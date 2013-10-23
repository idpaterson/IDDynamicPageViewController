//
//  IDDynamicPageViewController.m
//  DynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/16/13.
//
//

#import "IDDynamicPageViewController.h"

#import "IDWeakObjectRepresentation.h"

@interface IDDynamicPageViewController ()

@end

@implementation IDDynamicPageViewController

@synthesize dataSource = _dataSource;

#pragma mark - Initialization

- (void)setup
{
   _controllerClassByReuseIdentifier         = [NSMutableDictionary new];
   _reusableControllerQueueByReuseIdentifier = [NSMutableDictionary new];
   _activeControllerSetByReuseIdentifier     = [NSMutableDictionary new];
   _viewControllerReferenceByObjectReference = [NSMutableDictionary new];
   _objectReferenceByViewControllerReference = [NSMutableDictionary new];

   _animationDuration = 0.3;
   _interPageSpacing  = 0.0f;
   _minimumGestureCompletionRatioToChangeViewController = 0.3f;
   _minimumGestureVelocityToChangeViewController        = 100.0f;
   _transitionStyle = IDDynamicPageViewControllerTransitionStyleStack;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   if (self)
   {
      [self setup];
   }
   return self;
}

- (id)initWithNavigationOrientation:(IDDynamicPageViewControllerNavigationOrientation)navigationOrientation interPageSpacing:(CGFloat)interPageSpacing
{
   self = [super initWithNibName:nil bundle:nil];

   if (self)
   {
      [self setup];

      _navigationOrientation = navigationOrientation;
      _interPageSpacing      = interPageSpacing;
   }

   return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
   [super viewDidLoad];

   UIView * containerView = self.view;

   _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];

   _panGestureRecognizer.delaysTouchesBegan = YES;

   [containerView addGestureRecognizer:_panGestureRecognizer];
}

#pragma mark - Child view controller management

#pragma mark Appearance and disappearance

- (void)beginAppearanceTransition:(BOOL)isAppearing forViewController:(UIViewController *)viewController animated:(BOOL)animated
{
   if (viewController && ![viewController.parentViewController isEqual:self])
   {
      // We are trying to hide a controller that is not managed by this
      // container controller
      if (!isAppearing)
      {
         return;
      }

      // Adding the controller begins the appearance transition
      [self addChildViewController:viewController];
      [viewController didMoveToParentViewController:self];

      UIView * controllerView = viewController.view;
      [viewController beginAppearanceTransition:isAppearing animated:animated];
      [self.view addSubview:controllerView];
   }
   else
   {
      if (!isAppearing)
      {
         [viewController willMoveToParentViewController:nil];
      }

      [viewController beginAppearanceTransition:isAppearing animated:animated];
   }
}

- (void)willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
   viewController.view.frame = self.view.bounds;

   [self beginAppearanceTransition:YES forViewController:viewController animated:animated];
   [self applyConstraintsForChildViewController:viewController];
}

- (void)didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
   [viewController endAppearanceTransition];
}

- (void)willRemoveViewController:(UIViewController *)viewController animated:(BOOL)animated
{
   [self beginAppearanceTransition:NO forViewController:viewController animated:animated];
}

- (void)removeViewController:(UIViewController *)viewController animated:(BOOL)animated
{
   [viewController.view removeFromSuperview];
   [viewController endAppearanceTransition];
   [viewController removeFromParentViewController];
}

- (void)animateWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
   if (duration > 0.0f)
   {
      // Override for custom animations
      [UIView animateWithDuration:_animationDuration
                            delay:0.0
                          options:options
                       animations:animations
                       completion:completion];
   }
   // If not animated, perform the operations synchronously
   else
   {
      if (animations)
      {
         animations();
      }
      if (completion)
      {
         completion(YES);
      }
   }
}

#pragma mark Controller-based navigation

- (void)setViewController:(UIViewController *)viewController direction:(IDDynamicPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
   if (!viewController || [_activeViewController isEqual:viewController])
   {
      return;
   }

   // Do not animate the initial controller
   if (!_activeViewController)
   {
      animated = NO;
   }

   UIViewController * activeViewController = _activeViewController;
   NSTimeInterval     duration             = animated ? _animationDuration : 0.0;

   // Any in-progress animation must be finished immediately. The animation will
   // be cancelled and its completion block called asynchronously.
   if (_appearingViewController.view.layer.animationKeys.count > 0)
   {
      [self removeViewController:_appearingViewController animated:YES];
      [self didShowViewController:_activeViewController animated:YES];

      [_appearingViewController.view.layer removeAllAnimations];
      [_activeViewController.view.layer removeAllAnimations];

      [self didFinishAnimating:YES
        previousViewController:_appearingViewController
           transitionCompleted:NO];
   }

   // Set new view controller to _appearingViewController to set up the
   // animations
   _appearingViewController = viewController;

   [self willShowViewController:viewController animated:animated];
   [self willRemoveViewController:activeViewController animated:animated];

   [self applyTransformsInterpolatedTo:0.0f
                           inDirection:direction];

   [self willTransitionToViewController:viewController];

   // Stop recognizing any current gestures and do not allow interruption of
   // the transition
   _panGestureRecognizer.enabled = NO;

   [self animateWithDuration:duration
                     options:(UIViewAnimationOptionCurveEaseOut)
                  animations:^{
                     [self applyTransformsInterpolatedTo:1.0f
                                             inDirection:direction];
                  }
                  completion:^(BOOL completed) {
                     // If interrupted, these have already been called.
                     if (completed)
                     {
                        [self removeViewController:activeViewController animated:animated];
                        [self didShowViewController:viewController animated:animated];

                        _appearingViewController = nil;
                        _activeViewController = viewController;
                     }

                     _panGestureRecognizer.enabled = YES;

                     [self didFinishAnimating:YES
                       previousViewController:activeViewController
                          transitionCompleted:completed];

                     if (completion)
                     {
                        completion(completed);
                     }
                  }];

   // The new controller is now active
   _appearingViewController = activeViewController;
   _activeViewController    = viewController;
}

- (void)setDefaultViewController
{
   if ([_dataSource respondsToSelector:@selector(numberOfPagesInPageViewController:)] &&
       [_dataSource numberOfPagesInPageViewController:self] > 0)
   {
      UIViewController * firstController = [_dataSource pageViewController:self
                                              viewControllerForPageAtIndex:0];

      [self setViewController:firstController
                    direction:IDDynamicPageViewControllerNavigationDirectionForward
                     animated:NO completion:nil];
   }
}

#pragma mark Object-based navigation

- (void)setObject:(id)object animated:(BOOL)animated completion:(void (^)(BOOL))completion
{
   id activeObject = self.activeObject;

   // If we're already showing this object there is nothing to do
   if ([activeObject isEqual:object])
   {
      [self setViewController:self.activeViewController
                    direction:IDDynamicPageViewControllerNavigationDirectionForward
                     animated:animated
                   completion:completion];
      return;
   }

   NSUInteger index = [_dataSource pageViewController:self indexOfObject:object];

   // The object does not exist in the data source or we have no data source
   if (index == NSNotFound || !_dataSource)
   {
      if (completion)
      {
         completion(NO);
      }
      return;
   }

   NSUInteger         currentIndex   = [_dataSource pageViewController:self indexOfObject:activeObject];
   UIViewController * viewController = [_dataSource pageViewController:self viewControllerForObject:object];

   // Are we animating forward or backward?
   IDDynamicPageViewControllerNavigationDirection direction = (currentIndex < index ?
                                                               IDDynamicPageViewControllerNavigationDirectionForward :
                                                               IDDynamicPageViewControllerNavigationDirectionReverse);

   [self setViewController:viewController direction:direction animated:animated completion:completion];
}

- (id)objectForViewController:(UIViewController *)viewController
{
   if (viewController)
   {
      IDWeakObjectRepresentation * weakController = [IDWeakObjectRepresentation weakRepresentationOfObject:viewController];

      @synchronized(_objectReferenceByViewControllerReference)
      {
         return [_objectReferenceByViewControllerReference[weakController] object];
      }
   }

   return nil;
}

- (id)activeObject
{
   UIViewController * activeViewController = self.activeViewController;

   if (activeViewController)
   {
      return [self objectForViewController:activeViewController];
   }

   return nil;
}

#pragma mark Populating from the data source

- (void)setDataSource:(id<IDDynamicPageViewControllerDataSource>)dataSource
{
   [self willChangeValueForKey:@"dataSource"];
   _dataSource = dataSource;
   [self didChangeValueForKey:@"dataSource"];

   // Remove all cached controllers and objects
   @synchronized(_reusableControllerQueueByReuseIdentifier)
   {
      [_reusableControllerQueueByReuseIdentifier removeAllObjects];
   }
   @synchronized(_activeControllerSetByReuseIdentifier)
   {
      [_activeControllerSetByReuseIdentifier removeAllObjects];
   }
   @synchronized(_objectReferenceByViewControllerReference)
   {
      [_objectReferenceByViewControllerReference removeAllObjects];
   }
   @synchronized(_viewControllerReferenceByObjectReference)
   {
      [_viewControllerReferenceByObjectReference removeAllObjects];
   }

   [self setDefaultViewController];
}

- (void)showNeighboringControllerIfNecessaryInDirection:(IDDynamicPageViewControllerNavigationDirection)direction
{
   // Already showing this controller
   if (_appearingControllerDirection == direction)
   {
      return;
   }
   else if (_appearingControllerDirection != IDDynamicPageViewControllerNavigationDirectionNone)
   {
      [self willRemoveViewController:_appearingViewController animated:NO];
      [self removeViewController:_appearingViewController animated:NO];
   }

   UIViewController * viewController;

   switch (direction)
   {
      case IDDynamicPageViewControllerNavigationDirectionForward:
         viewController = [_dataSource pageViewController:self viewControllerAfterViewController:_activeViewController];
         break;

      case IDDynamicPageViewControllerNavigationDirectionReverse:
         viewController = [_dataSource pageViewController:self viewControllerBeforeViewController:_activeViewController];
         break;

      case IDDynamicPageViewControllerNavigationDirectionNone:
         // Should not happen, this is only used to denote that no neighboring
         // controllers are loaded.
         break;
   }

   if (!viewController)
   {
      return;
   }

   UIView * containerView  = self.view;
   UIView * controllerView = viewController.view;

   // The active controller is not disappearing yet; the disappearing will be
   // handled once the user releases the pan gesture
   [self willShowViewController:viewController animated:YES];

   // Moving forward adds pages on top, moving backwards adds them on the bottom
   // to support stack navigation.
   if (direction == IDDynamicPageViewControllerNavigationDirectionReverse)
   {
      [containerView sendSubviewToBack:controllerView];
   }

   [containerView layoutIfNeeded];

   _appearingControllerDirection = direction;
   _appearingViewController      = viewController;
}

#pragma mark - View Controller Reuse

- (UIViewController *)inactiveViewControllerForReuseWithIdentifier:(NSString *)reuseIdentifier alreadyAssociatedWithObject:(id)object
{
   IDWeakObjectRepresentation * weakObject     = [IDWeakObjectRepresentation weakRepresentationOfObject:object];
   UIViewController           * viewController = nil;

   @synchronized(_viewControllerReferenceByObjectReference)
   {
      viewController = [_viewControllerReferenceByObjectReference[weakObject] object];
   }

   // If a suitable view controller is found we still need to make sure it is
   // the correct reuse identifier.
   if (viewController)
   {
      @synchronized(_reusableControllerQueueByReuseIdentifier)
      {
         NSMutableOrderedSet * reuseQueue = _reusableControllerQueueByReuseIdentifier[reuseIdentifier];

         if ([reuseQueue containsObject:viewController])
         {
            [reuseQueue removeObject:viewController];

            IDLogInfo(@"Reused controller %@ already representing object %@", viewController, object);
            IDLogInfo(@"Controller %@ is no longer reusable", viewController);

            return viewController;
         }
      }
   }

   return nil;
}

- (UIViewController *)inactiveViewControllerForReuseIdentifier:(NSString *)reuseIdentifier byAssociatingWithObject:(id)object
{
   id viewController = nil;

   @synchronized(_reusableControllerQueueByReuseIdentifier)
   {
      NSMutableOrderedSet * reuseQueue = _reusableControllerQueueByReuseIdentifier[reuseIdentifier];

      // Don't reuse the only controller in the queue. We want 2 at all times
      // since there is one controller before and one after the current one
      if (reuseQueue.count > 1)
      {
         viewController = reuseQueue.firstObject;

         if (viewController)
         {
            [reuseQueue removeObjectAtIndex:0];
         }
      }
   }

   if (viewController)
   {
      IDWeakObjectRepresentation * weakController = [IDWeakObjectRepresentation weakRepresentationOfObject:viewController];
      IDWeakObjectRepresentation * newWeakObject  = [IDWeakObjectRepresentation weakRepresentationOfObject:object];
      IDWeakObjectRepresentation * oldWeakObject  = nil;

      @synchronized(_objectReferenceByViewControllerReference)
      {
         oldWeakObject = _objectReferenceByViewControllerReference[weakController];

         _objectReferenceByViewControllerReference[weakController] = newWeakObject;
      }

      @synchronized(_viewControllerReferenceByObjectReference)
      {
         if (oldWeakObject)
         {
            [_viewControllerReferenceByObjectReference removeObjectForKey:oldWeakObject];
         }

         _viewControllerReferenceByObjectReference[newWeakObject] = weakController;
      }

      IDLogInfo(@"Reused controller %@ that was representing %@ to represent %@", viewController, oldWeakObject.object, object);

      return viewController;
   }

   return nil;
}

- (UIViewController *)createViewControllerForReuseIdentifier:(NSString *)reuseIdentifier byAssociatingWithObject:(id)object
{
   Class class;

   @synchronized(_controllerClassByReuseIdentifier)
   {
      class = _controllerClassByReuseIdentifier[reuseIdentifier];
   }

   NSAssert(class != nil, @"No controller class registered for reuse identifier: %@", reuseIdentifier);

   id viewController = [[class alloc] initWithNibName:nil bundle:nil];
   IDWeakObjectRepresentation * weakController = [IDWeakObjectRepresentation weakRepresentationOfObject:viewController];
   IDWeakObjectRepresentation * weakObject     = [IDWeakObjectRepresentation weakRepresentationOfObject:object];

   @synchronized(_objectReferenceByViewControllerReference)
   {
      _objectReferenceByViewControllerReference[weakController] = weakObject;
   }

   @synchronized(_viewControllerReferenceByObjectReference)
   {
      _viewControllerReferenceByObjectReference[weakObject] = weakController;
   }

   IDLogInfo(@"Created a new controller %@ to represent %@", viewController, object);

   return viewController;
}

- (void)registerClass:(Class)viewControllerClass forViewControllerWithReuseIdentifier:(NSString *)reuseIdentifier
{
   NSAssert(reuseIdentifier != nil, @"Reuse identifier cannot be nil");

   if (viewControllerClass)
   {
      _controllerClassByReuseIdentifier[reuseIdentifier] = viewControllerClass;
   }
   else
   {
      [_controllerClassByReuseIdentifier removeObjectForKey:reuseIdentifier];
   }
}

- (UIViewController *)dequeueReusableViewControllerWithReuseIdentifier:(NSString *)reuseIdentifier forObject:(id)object
{
   NSAssert(reuseIdentifier != nil, @"Reuse identifier cannot be nil");
   NSAssert(object != nil, @"Object cannot be nil");

   id viewController = [self inactiveViewControllerForReuseWithIdentifier:reuseIdentifier
                                              alreadyAssociatedWithObject:object];

   // Reuse a different controller if available
   if (!viewController)
   {
      viewController = [self inactiveViewControllerForReuseIdentifier:reuseIdentifier
                                              byAssociatingWithObject:object];
   }

   if (!viewController)
   {
      viewController = [self createViewControllerForReuseIdentifier:reuseIdentifier
                                            byAssociatingWithObject:object];
   }

   // Record the controller as active
   @synchronized(_activeControllerSetByReuseIdentifier)
   {
      NSMutableSet * controllerSet = _activeControllerSetByReuseIdentifier[reuseIdentifier];

      if (!controllerSet)
      {
         controllerSet = [NSMutableSet set];
         _activeControllerSetByReuseIdentifier[reuseIdentifier] = controllerSet;
      }

      [controllerSet addObject:viewController];
   }

   return viewController;
}


#pragma mark - Data source change handling

- (void)beginUpdates
{
   if (++_updateLevel == 1)
   {
      _indexOfActiveViewControllerAfterChanges = _indexOfActiveViewController;
   }
}

- (void)endUpdates
{
   if (--_updateLevel == 0)
   {
      _indexOfActiveViewController             = _indexOfActiveViewControllerAfterChanges;
      _indexOfActiveViewControllerAfterChanges = NSNotFound;
   }
}

- (void)beginUpdatesIfNecessary
{
   if (_updateLevel == 0)
   {
      _dataWasChangedWithoutBeginUpdates = YES;

      [self beginUpdates];
   }
}

- (void)endUpdatesIfWasNecessaryToBegin
{
   if (_dataWasChangedWithoutBeginUpdates)
   {
      _dataWasChangedWithoutBeginUpdates = NO;

      [self endUpdates];
   }
}

- (void)insertPagesAtIndexes:(NSIndexSet *)indexes
{
   [self beginUpdatesIfNecessary];

   NSRange upToActiveController = NSMakeRange(0, _indexOfActiveViewController);

   _indexOfActiveViewControllerAfterChanges += [indexes countOfIndexesInRange:upToActiveController];

   [self endUpdatesIfWasNecessaryToBegin];
}

- (void)deletePagesAtIndexes:(NSIndexSet *)indexes
{
   [self beginUpdatesIfNecessary];

   if ([indexes containsIndex:_indexOfActiveViewController])
   {

   }
   else
   {
      NSRange upToNotIncludingActiveController = NSMakeRange(0, _indexOfActiveViewController - 1);
      _indexOfActiveViewControllerAfterChanges -= [indexes countOfIndexesInRange:upToNotIncludingActiveController];
   }

   [self endUpdatesIfWasNecessaryToBegin];
}

- (void)movePageAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
   [self beginUpdatesIfNecessary];

   if (fromIndex == _indexOfActiveViewController)
   {
      _indexOfActiveViewControllerAfterChanges = toIndex;
   }
   else if (fromIndex < _indexOfActiveViewController && toIndex > _indexOfActiveViewController)
   {
      _indexOfActiveViewControllerAfterChanges--;
   }

   [self endUpdatesIfWasNecessaryToBegin];
}

- (void)reloadPageAtIndex:(NSUInteger)index
{
   [self beginUpdatesIfNecessary];



   [self endUpdatesIfWasNecessaryToBegin];
}


#pragma mark - Layout

- (void)applyTransformsInterpolatedTo:(CGFloat)interpolationRatio inDirection:(IDDynamicPageViewControllerNavigationDirection)direction
{
   if (_appearingViewController)
   {
      CATransform3D activeControllerTransform = [self finalTransformForDisappearingViewController:_activeViewController
                                                                                        direction:direction
                                                                                   interpolatedTo:interpolationRatio];
      CATransform3D appearingControllerTransform = [self initialTransformForAppearingViewController:_appearingViewController
                                                                                          direction:direction
                                                                                     interpolatedTo:interpolationRatio];

      _activeViewController.view.layer.transform    = activeControllerTransform;
      _appearingViewController.view.layer.transform = appearingControllerTransform;
   }
   else
   {
      CATransform3D activeControllerTransform = [self finalTransformForBouncingViewController:_activeViewController
                                                                                    direction:direction
                                                                               interpolatedTo:interpolationRatio];

      _activeViewController.view.layer.transform = activeControllerTransform;
   }
}

- (CATransform3D)initialTransformForAppearingViewController:(UIViewController *)controller direction:(IDDynamicPageViewControllerNavigationDirection)direction interpolatedTo:(CGFloat)interpolationRatio
{
   UIView * containerView = self.view;
   CGRect   bounds        = containerView.bounds;
   CGSize   offset        = bounds.size;

   switch (_navigationOrientation)
   {
      case IDDynamicPageViewControllerNavigationOrientationHorizontal:
         offset.width += _interPageSpacing;
         offset.height = 0.0f;
         break;

      case IDDynamicPageViewControllerNavigationOrientationVertical:
         offset.height += _interPageSpacing;
         offset.width   = 0.0f;
         break;
   }

   switch (direction)
   {
      case IDDynamicPageViewControllerNavigationDirectionReverse:
         offset.width  *= -1.0f;
         offset.height *= -1.0f;

         if (_transitionStyle == IDDynamicPageViewControllerTransitionStyleStack)
         {
            return CATransform3DMakeScale(1.0f - 0.1f * (1.0f - interpolationRatio),
                                          1.0f - 0.1f * (1.0f - interpolationRatio),
                                          1.0f);
         }
         break;

      default:
         break;
   }

   return CATransform3DMakeTranslation(offset.width * (1.0f - interpolationRatio),
                                       offset.height * (1.0f - interpolationRatio),
                                       0.0f);
}

- (CATransform3D)finalTransformForDisappearingViewController:(UIViewController *)controller direction:(IDDynamicPageViewControllerNavigationDirection)direction interpolatedTo:(CGFloat)interpolationRatio
{
   UIView * containerView = self.view;
   CGRect   bounds        = containerView.bounds;
   CGSize   offset        = bounds.size;

   switch (_navigationOrientation)
   {
      case IDDynamicPageViewControllerNavigationOrientationHorizontal:
         offset.width += _interPageSpacing;
         offset.height = 0.0f;
         break;

      case IDDynamicPageViewControllerNavigationOrientationVertical:
         offset.height += _interPageSpacing;
         offset.width   = 0.0f;
         break;
   }

   switch (direction)
   {
      case IDDynamicPageViewControllerNavigationDirectionForward:
         offset.width  *= -1.0f;
         offset.height *= -1.0f;

         if (_transitionStyle == IDDynamicPageViewControllerTransitionStyleStack)
         {
            return CATransform3DMakeScale(1.0f - 0.1f * interpolationRatio,
                                          1.0f - 0.1f * interpolationRatio,
                                          1.0f);
         }
         break;

      default:
         break;
   }

   return CATransform3DMakeTranslation(offset.width * interpolationRatio,
                                       offset.height * interpolationRatio,
                                       0.0f);
}

- (CATransform3D)finalTransformForBouncingViewController:(UIViewController *)controller direction:(IDDynamicPageViewControllerNavigationDirection)direction interpolatedTo:(CGFloat)interpolationRatio
{
   UIView * containerView = self.view;
   CGRect   bounds        = containerView.bounds;
   CGSize   offset        = bounds.size;

   switch (_navigationOrientation)
   {
      case IDDynamicPageViewControllerNavigationOrientationHorizontal:
         offset.width += _interPageSpacing;
         offset.height = 0.0f;
         break;

      case IDDynamicPageViewControllerNavigationOrientationVertical:
         offset.height += _interPageSpacing;
         offset.width   = 0.0f;
         break;
   }

   switch (direction)
   {
      case IDDynamicPageViewControllerNavigationDirectionForward:
         offset.width  *= -1.0f;
         offset.height *= -1.0f;
         break;

      default:
         break;
   }

   return CATransform3DMakeTranslation(offset.width * interpolationRatio * 0.5f,
                                       offset.height * interpolationRatio * 0.5f,
                                       0.0f);
}

- (void)applyConstraintsForChildViewController:(UIViewController *)viewController
{
   NSLayoutConstraint * constraint;
   UIView             * containerView  = self.view;
   UIView             * controllerView = viewController.view;

   controllerView.translatesAutoresizingMaskIntoConstraints = NO;

   constraint = [NSLayoutConstraint
                 constraintWithItem:controllerView
                 attribute:NSLayoutAttributeWidth
                 relatedBy:NSLayoutRelationEqual
                 toItem:containerView
                 attribute:NSLayoutAttributeWidth
                 multiplier:1.0f constant:0.0f];
   [containerView addConstraint:constraint];

   constraint = [NSLayoutConstraint
                 constraintWithItem:controllerView
                 attribute:NSLayoutAttributeHeight
                 relatedBy:NSLayoutRelationEqual
                 toItem:containerView
                 attribute:NSLayoutAttributeHeight
                 multiplier:1.0f constant:0.0f];
   [containerView addConstraint:constraint];

   constraint = [NSLayoutConstraint
                 constraintWithItem:controllerView
                 attribute:NSLayoutAttributeCenterX
                 relatedBy:NSLayoutRelationEqual
                 toItem:containerView
                 attribute:NSLayoutAttributeCenterX
                 multiplier:1.0f constant:0.0f];
   [containerView addConstraint:constraint];

   constraint = [NSLayoutConstraint
                 constraintWithItem:controllerView
                 attribute:NSLayoutAttributeCenterY
                 relatedBy:NSLayoutRelationEqual
                 toItem:containerView
                 attribute:NSLayoutAttributeCenterY
                 multiplier:1.0f constant:0.0f];
   [containerView addConstraint:constraint];
}

#pragma mark - Gesture handling

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
   if (![panGesture isEqual:_panGestureRecognizer])
   {
      return;
   }

   UIView                 * containerView = self.view;
   UIGestureRecognizerState state         = panGesture.state;
   CGPoint translation = [_panGestureRecognizer translationInView:containerView];
   CGPoint velocity    = [_panGestureRecognizer velocityInView:containerView];
   IDDynamicPageViewControllerNavigationDirection direction;
   CGRect  bounds                 = containerView.bounds;
   CGFloat interpolationRatio     = 0.0f;
   CGFloat velocityOnCriticalAxis = 0.0f;

   switch (_navigationOrientation)
   {
      case IDDynamicPageViewControllerNavigationOrientationHorizontal:
         if (translation.x <= 0.0f)
         {
            direction              = IDDynamicPageViewControllerNavigationDirectionForward;
            velocityOnCriticalAxis = -velocity.x;
         }
         else
         {
            direction              = IDDynamicPageViewControllerNavigationDirectionReverse;
            velocityOnCriticalAxis = velocity.x;
         }

         interpolationRatio = ABS(translation.x / bounds.size.width);
         break;

      case IDDynamicPageViewControllerNavigationOrientationVertical:
         if (translation.y <= 0.0f)
         {
            direction              = IDDynamicPageViewControllerNavigationDirectionForward;
            velocityOnCriticalAxis = -velocity.y;
         }
         else
         {
            direction              = IDDynamicPageViewControllerNavigationDirectionReverse;
            velocityOnCriticalAxis = velocity.y;
         }

         interpolationRatio = ABS(translation.y / bounds.size.height);
         break;
   }

   if (state == UIGestureRecognizerStateEnded)
   {
      CGFloat            finalInterpolationRatio = 0.0f;
      UIViewController * appearingViewController = _appearingViewController;
      UIViewController * activeViewController    = _activeViewController;

      // Only finish the transition if the gesture is still moving in the
      // direction of the page turn, and has either passed the distance or
      // velocity thresholds. Otherwise return to the previous controller
      if (appearingViewController &&
          velocityOnCriticalAxis >= 0.0f &&
          (velocityOnCriticalAxis > _minimumGestureVelocityToChangeViewController ||
           interpolationRatio > _minimumGestureCompletionRatioToChangeViewController))
      {
         finalInterpolationRatio = 1.0f;

         // Transition has already begun for the appearing controller, so just
         // tell the active controller that it will be disappearing
         [self willRemoveViewController:activeViewController animated:YES];

         [self willTransitionToViewController:appearingViewController];
      }
      else
      {
         [self didShowViewController:appearingViewController animated:YES];
         [self willRemoveViewController:appearingViewController animated:YES];
      }

      _panGestureRecognizer.enabled = NO;

      [self animateWithDuration:_animationDuration
                        options:(UIViewAnimationOptionCurveEaseOut)
                     animations:^{
                        [self applyTransformsInterpolatedTo:finalInterpolationRatio
                                                inDirection:direction];
                     }
                     completion:^(BOOL completed) {
                        // Transition finished
                        if (finalInterpolationRatio > 0.5f)
                        {
                           [self removeViewController:activeViewController
                                             animated:YES];
                           [self didShowViewController:appearingViewController
                                              animated:YES];

                           activeViewController.view.layer.transform = CATransform3DIdentity;

                           _activeViewController = appearingViewController;
                        }
                        // Transition cancelled
                        else
                        {
                           [self removeViewController:appearingViewController
                                             animated:YES];
                        }

                        appearingViewController.view.layer.transform = CATransform3DIdentity;

                        _appearingViewController = nil;
                        _appearingControllerDirection = IDDynamicPageViewControllerNavigationDirectionNone;

                        _panGestureRecognizer.enabled = YES;

                        [self didFinishAnimating:YES
                          previousViewController:activeViewController
                             transitionCompleted:completed];
                     }];
   }
   else if (state == UIGestureRecognizerStateChanged)
   {
      [self showNeighboringControllerIfNecessaryInDirection:direction];

      [self applyTransformsInterpolatedTo:interpolationRatio inDirection:direction];
   }
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];

   @synchronized(_reusableControllerQueueByReuseIdentifier)
   {
      [_reusableControllerQueueByReuseIdentifier removeAllObjects];
   }
}

#pragma mark - IDDynamicPageViewControllerDelegate implementation

- (void)didFinishAnimating:(BOOL)finished previousViewController:(UIViewController *)previousViewController transitionCompleted:(BOOL)completed
{
   UIViewController * activeViewController = self.activeViewController;

   //id currentObject = _objectByViewController[currentViewController];

   if (![activeViewController isEqual:previousViewController])
   {
      UIViewController * viewControllerBefore = [_dataSource pageViewController:self viewControllerBeforeViewController:activeViewController];
      UIViewController * viewControllerAfter  = [_dataSource pageViewController:self viewControllerAfterViewController:activeViewController];

      _previousObject = [self objectForViewController:viewControllerBefore];
      _nextObject     = [self objectForViewController:viewControllerAfter];
   }

   IDLogInfo(@"Controller %@ is now active", activeViewController);

   @synchronized(_reusableControllerQueueByReuseIdentifier)
   {
      @synchronized(_activeControllerSetByReuseIdentifier)
      {
         [_activeControllerSetByReuseIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString * reuseIdentifier, NSMutableSet * viewControllers, BOOL * stop) {
            NSMutableOrderedSet * reuseQueue = _reusableControllerQueueByReuseIdentifier[reuseIdentifier];

            if (!reuseQueue)
            {
               reuseQueue = [NSMutableOrderedSet new];
               _reusableControllerQueueByReuseIdentifier[reuseIdentifier] = reuseQueue;
            }

            // Iterate a copy of viewControllers, because we're going to remove
            // items that are no longer active.
            for (UIViewController * viewController in [NSSet setWithSet:viewControllers])
            {
               // The current view controller is no longer reusable
               if ([viewController isEqual:activeViewController])
               {
                  [reuseQueue removeObject:viewController];

                  IDLogInfo(@"Controller %@ is no longer reusable", viewController);
               }
               // Any other controller is
               else
               {
                  [reuseQueue addObject:viewController];
                  
                  IDLogInfo(@"Controller %@ is now reusable", viewController);
               }
            }
         }];
      }
   }
   
   //[self updatePageControl];
   
   if ([_delegate respondsToSelector:@selector(pageViewController:didFinishAnimating:previousViewController:transitionCompleted:)])
   {
      [_delegate pageViewController:self
                 didFinishAnimating:finished
             previousViewController:previousViewController
                transitionCompleted:completed];
   }
}

- (void)willTransitionToViewController:(UIViewController *)pendingViewController
{
   if ([_delegate respondsToSelector:@selector(pageViewController:willTransitionToViewController:)])
   {
      [_delegate pageViewController:self willTransitionToViewController:pendingViewController];
   }
}

- (NSUInteger)supportedInterfaceOrientations
{
   if ([_delegate respondsToSelector:@selector(pageViewControllerSupportedInterfaceOrientations:)])
   {
      return [_delegate pageViewControllerSupportedInterfaceOrientations:self];
   }
   
   return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
   if ([_delegate respondsToSelector:@selector(pageViewControllerPreferredInterfaceOrientationForPresentation:)])
   {
      return [_delegate pageViewControllerPreferredInterfaceOrientationForPresentation:self];
   }
   
   return [UIApplication sharedApplication].statusBarOrientation;
}

@end

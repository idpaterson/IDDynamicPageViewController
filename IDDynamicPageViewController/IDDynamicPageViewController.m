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

@synthesize dataSource = _dataSource,
pageControl            = _pageControl;

#pragma mark - Initialization

- (void)setup
{
   _controllerClassByReuseIdentifier         = [NSMutableDictionary dictionary];
   _reusableControllerQueueByReuseIdentifier = [NSMutableDictionary new];
   _reuseIdentifierByControllerReference     = [NSMutableDictionary new];
   _indexByControllerReference               = [NSMutableDictionary new];
   _viewControllerReferenceByObjectReference = [NSMutableDictionary new];
   _objectReferenceByViewControllerReference = [NSMutableDictionary new];

   _animationDuration = 0.3;
   _interPageSpacing  = 0.0f;
   _minimumGestureCompletionRatioToChangeViewController = 0.3f;
   _minimumGestureVelocityToChangeViewController        = 100.0f;
   _transitionStyle = IDDynamicPageViewControllerTransitionStyleScroll;
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

   UIView * controllerView = self.view;
   _controllerContainerView = [[UIView alloc] initWithFrame:controllerView.bounds];
   _pageControl             = self.pageControl;

   _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];

   _panGestureRecognizer.delegate           = self;
   _panGestureRecognizer.delaysTouchesBegan = YES;

   controllerView.clipsToBounds = YES;
   [controllerView addGestureRecognizer:_panGestureRecognizer];

   _controllerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
   _pageControl.translatesAutoresizingMaskIntoConstraints             = NO;

   [controllerView addSubview:_controllerContainerView];
   [controllerView addSubview:_pageControl];

   NSArray      * constraints;
   NSDictionary * views;

   views = NSDictionaryOfVariableBindings(_controllerContainerView);

   constraints = [NSLayoutConstraint
                  constraintsWithVisualFormat:@"H:|[_controllerContainerView]|"
                  options:0 metrics:nil views:views];
   [controllerView addConstraints:constraints];

   constraints = [NSLayoutConstraint
                  constraintsWithVisualFormat:@"V:|[_controllerContainerView]"
                  options:0 metrics:nil views:views];
   [controllerView addConstraints:constraints];

   [self updatePageControlLayout];
}

#pragma mark - Child view controller management

#pragma mark Appearance and disappearance

- (void)beginAppearanceTransition:(BOOL)isAppearing forViewController:(UIViewController *)viewController animated:(BOOL)animated
{
   UIView * controllerView = viewController.view;

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
      [viewController beginAppearanceTransition:isAppearing animated:animated];
   }
   else
   {
      if (!isAppearing)
      {
         [viewController willMoveToParentViewController:nil];
      }

      [viewController beginAppearanceTransition:isAppearing animated:animated];
   }

   if (![controllerView isDescendantOfView:_controllerContainerView])
   {
      [_controllerContainerView addSubview:controllerView];
   }
}

- (void)willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
   @synchronized(_reusableControllerQueueByReuseIdentifier)
   {
      NSString            * reuseIdentifier = [self reuseIdentifierForViewController:viewController];
      NSMutableOrderedSet * reuseQueue      = _reusableControllerQueueByReuseIdentifier[reuseIdentifier];

      if ([reuseQueue containsObject:viewController])
      {
         [reuseQueue removeObject:viewController];

         IDLogInfo(@"Controller %@ is no longer reusable", viewController);
      }
   }

   UIView * controllerView = viewController.view;
   controllerView.layer.transform = CATransform3DIdentity;
   controllerView.frame           = _controllerContainerView.bounds;
   controllerView.translatesAutoresizingMaskIntoConstraints = NO;

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
   if (!viewController)
   {
      return;
   }

   [viewController.view removeFromSuperview];
   [viewController endAppearanceTransition];
   [viewController removeFromParentViewController];

   @synchronized(_reusableControllerQueueByReuseIdentifier)
   {
      NSString * reuseIdentifier = [self reuseIdentifierForViewController:viewController];

      if (reuseIdentifier)
      {
         NSMutableOrderedSet * reuseQueue = _reusableControllerQueueByReuseIdentifier[reuseIdentifier];

         if (!reuseQueue)
         {
            reuseQueue = [NSMutableOrderedSet new];
            _reusableControllerQueueByReuseIdentifier[reuseIdentifier] = reuseQueue;
         }

         [reuseQueue addObject:viewController];

         IDLogInfo(@"Controller %@ is now reusable", viewController);
      }
   }
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
   // Do not animate the initial controller
   if (!_activeViewController)
   {
      animated = NO;
   }

   // Make sure the controller's view hierarchy has loaded
   if (!self.isViewLoaded)
   {
      self.view.tag = 0;
   }

   UIViewController * activeViewController = _activeViewController;
   NSTimeInterval     duration             = animated ? _animationDuration : 0.0;
   NSUInteger         transitionNumber     = ++_transitionNumber;

   _transitioningDueToUserInteraction = NO;

   if (!viewController || [activeViewController isEqual:viewController])
   {
      [self animateWithDuration:duration
                        options:(UIViewAnimationOptionCurveEaseOut)
                     animations:^{
                        self.activeViewController = viewController;
                     }
                     completion:nil];

      return;
   }

   // Any in-progress animation must be finished immediately. The animation will
   // be cancelled and its completion block called asynchronously.
   if (_otherViewController.view.layer.animationKeys.count > 0)
   {
      [self removeViewController:_otherViewController animated:YES];
      [self didShowViewController:_activeViewController animated:YES];

      [_otherViewController.view.layer removeAllAnimations];
      [_activeViewController.view.layer removeAllAnimations];

      [self didFinishAnimating:YES
        previousViewController:_otherViewController
           transitionCompleted:NO];
   }

   // Set new view controller to _otherViewController to set up the
   // animations
   _otherViewController = viewController;

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

                     // The new controller is now active, update it with an
                     // animated page dot or layout transition
                     _otherViewController      = activeViewController;
                     self.activeViewController = viewController;
                  }
                  completion:^(BOOL completed) {
                     // The animation sometimes reports questionable values
                     // here, so we determine completion by whether or not the
                     // animation has been interrupted by showing a different
                     // controller.
                     completed = transitionNumber == _transitionNumber;

                     // If another transition was started before this one
                     // finished these calls will have already been made
                     if (completed)
                     {
                        [self removeViewController:activeViewController animated:animated];
                        [self didShowViewController:viewController animated:animated];

                        _otherViewController = nil;
                     }

                     _panGestureRecognizer.enabled = YES;

                     [self didFinishAnimating:YES
                       previousViewController:activeViewController
                          transitionCompleted:completed];

                     if (completion)
                     {
                        completion(completed);
                     }

                     // Prepare both directions, since the current and previous
                     // views controllers may not necessarily be adjacent in
                     // the case of programmatic controller switching.
                     [self prepareNeighboringControllerIfNecessaryInDirection:IDDynamicPageViewControllerNavigationDirectionForward];
                     [self prepareNeighboringControllerIfNecessaryInDirection:IDDynamicPageViewControllerNavigationDirectionReverse];
                  }];
}

- (void)setActiveViewController:(UIViewController *)activeViewController
{
   // Already active
   if ([_activeViewController isEqual:activeViewController])
   {
      [self updatePageControl];
      return;
   }

   [self willChangeValueForKey:@"activeViewController"];
   _activeViewController = activeViewController;
   [self didChangeValueForKey:@"activeViewController"];

   NSUInteger index = self.indexOfActiveViewController;

   _previousObject = [_dataSource pageViewController:self objectAtIndex:index - 1];
   _nextObject     = [_dataSource pageViewController:self objectAtIndex:index + 1];

   [self updatePageControl];

   [self didActivateViewController:_activeViewController];
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

   NSUInteger currentIndex = [_dataSource pageViewController:self indexOfObject:activeObject];

   _previousObject = [_dataSource pageViewController:self objectAtIndex:index - 1];
   _nextObject     = [_dataSource pageViewController:self objectAtIndex:index + 1];

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

- (UIViewController *)viewControllerForObject:(id)object
{
   if (object)
   {
      IDWeakObjectRepresentation * weakObject = [IDWeakObjectRepresentation weakRepresentationOfObject:object];

      @synchronized(_viewControllerReferenceByObjectReference)
      {
         return [_viewControllerReferenceByObjectReference[weakObject] object];
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

- (NSUInteger)indexOfActiveViewController
{
   return [_dataSource pageViewController:self indexOfObject:self.activeObject];
}

#pragma mark Populating from the data source

- (void)setDataSource:(id<IDDynamicPageViewControllerDataSource>)dataSource
{
   [self willChangeValueForKey:@"dataSource"];
   _dataSource = dataSource;
   [self didChangeValueForKey:@"dataSource"];

   // If we are in an update procedure the expectation is that the current
   // controller will be carried over despite a change of data source, if the
   // new data source contains the same object.
   if (_updateLevel == 0)
   {
      // Remove all cached controllers and objects
      @synchronized(_reusableControllerQueueByReuseIdentifier)
      {
         [_reusableControllerQueueByReuseIdentifier removeAllObjects];
      }
      @synchronized(_objectReferenceByViewControllerReference)
      {
         [_objectReferenceByViewControllerReference removeAllObjects];
      }
      @synchronized(_viewControllerReferenceByObjectReference)
      {
         [_viewControllerReferenceByObjectReference removeAllObjects];
      }
      _nextObject     = nil;
      _previousObject = nil;

      [self reloadData];
   }
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
      [self willRemoveViewController:_otherViewController animated:NO];
      [self removeViewController:_otherViewController animated:NO];
   }

   UIViewController * viewController              = nil;
   NSUInteger         indexOfActiveViewController = self.indexOfActiveViewController;

   switch (direction)
   {
      case IDDynamicPageViewControllerNavigationDirectionForward:
         if (indexOfActiveViewController + 1 < [_dataSource numberOfPagesInPageViewController:self])
         {
            viewController = [_dataSource pageViewController:self viewControllerForPageAtIndex:indexOfActiveViewController + 1];
         }
         break;

      case IDDynamicPageViewControllerNavigationDirectionReverse:
         if (indexOfActiveViewController > 0)
         {
            viewController = [_dataSource pageViewController:self viewControllerForPageAtIndex:indexOfActiveViewController - 1];
         }
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

   UIView * controllerView = viewController.view;

   // The active controller is not disappearing yet; the disappearing will be
   // handled once the user releases the pan gesture
   [self willShowViewController:viewController animated:YES];

   // Moving forward adds pages on top, moving backwards adds them on the bottom
   // to support stack navigation.
   if (direction == IDDynamicPageViewControllerNavigationDirectionReverse)
   {
      [_controllerContainerView sendSubviewToBack:controllerView];
   }

   [_controllerContainerView layoutIfNeeded];

   _appearingControllerDirection = direction;
   _otherViewController          = viewController;
}

- (void)prepareNeighboringControllerIfNecessaryInDirection:(IDDynamicPageViewControllerNavigationDirection)direction
{
   UIViewController * viewController              = nil;
   NSUInteger         indexOfActiveViewController = self.indexOfActiveViewController;

   _preparingNeighborViewControllers = YES;

   switch (direction)
   {
      case IDDynamicPageViewControllerNavigationDirectionForward:
         if (indexOfActiveViewController + 1 < [_dataSource numberOfPagesInPageViewController:self])
         {
            viewController = [_dataSource pageViewController:self viewControllerForPageAtIndex:indexOfActiveViewController + 1];
         }
         break;

      case IDDynamicPageViewControllerNavigationDirectionReverse:
         if (indexOfActiveViewController > 0)
         {
            viewController = [_dataSource pageViewController:self viewControllerForPageAtIndex:indexOfActiveViewController - 1];
         }
         break;

      case IDDynamicPageViewControllerNavigationDirectionNone:
         // Should not happen, this is only used to denote that no neighboring
         // controllers are loaded.
         break;
   }

   _preparingNeighborViewControllers = NO;

   // Ensure that the view is loaded
   viewController.view.alpha = 1.0f;
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

   return viewController;
}

- (UIViewController *)inactiveViewControllerForReuseIdentifier:(NSString *)reuseIdentifier byAssociatingWithObject:(id)object atIndex:(NSUInteger)index
{
   __block id viewController = nil;

   @synchronized(_reusableControllerQueueByReuseIdentifier)
   {
      NSMutableOrderedSet * reuseQueue = _reusableControllerQueueByReuseIdentifier[reuseIdentifier];
      id previousViewController;
      id nextViewController;

      // If this is being called as a result of preparing controllers adjacent
      // to the active controller, ensure that the controllers to avoid are in
      // relation to the active controller rather than this adjacent one.
      if (_preparingNeighborViewControllers)
      {
         previousViewController = [self viewControllerForObject:_previousObject];
         nextViewController     = [self viewControllerForObject:_nextObject];
      }
      // If a new controller is being set, the previous and next ivars are not
      // relevant; instead, look for existing controllers representing the
      // objects adjacent to the new object
      else
      {
         id previousObject = [_dataSource pageViewController:self objectAtIndex:index - 1];
         id nextObject     = [_dataSource pageViewController:self objectAtIndex:index + 1];

         previousViewController = [self viewControllerForObject:previousObject];
         nextViewController     = [self viewControllerForObject:nextObject];
      }

      // Find the first controller that is not representing an object adjacent
      // to the target object
      [reuseQueue enumerateObjectsUsingBlock:^(UIViewController * otherController, NSUInteger index, BOOL * stop) {
         if (otherController != previousViewController &&
             otherController != nextViewController)
         {
            viewController = otherController;
            *stop = YES;

            [reuseQueue removeObjectAtIndex:index];
         }
      }];
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

   // Record the reuse identifier
   @synchronized(_reuseIdentifierByControllerReference)
   {
      IDWeakObjectRepresentation * weakReference = [IDWeakObjectRepresentation weakRepresentationOfObject:viewController];

      _reuseIdentifierByControllerReference[weakReference] = reuseIdentifier;
   }

   @synchronized(_reusableControllerQueueByReuseIdentifier)
   {
      NSMutableOrderedSet * reuseQueue = _reusableControllerQueueByReuseIdentifier[reuseIdentifier];

      if (!reuseQueue)
      {
         reuseQueue = [NSMutableOrderedSet new];
         _reusableControllerQueueByReuseIdentifier[reuseIdentifier] = reuseQueue;
      }

      [reuseQueue addObject:viewController];
   }

   IDLogInfo(@"Created a new controller %@ to represent %@", viewController, object);

   return viewController;
}

- (NSString *)reuseIdentifierForViewController:(UIViewController *)viewController
{
   @synchronized(_reuseIdentifierByControllerReference)
   {
      IDWeakObjectRepresentation * weakReference = [IDWeakObjectRepresentation weakRepresentationOfObject:viewController];

      return _reuseIdentifierByControllerReference[weakReference];
   }
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController
{
   @synchronized(_indexByControllerReference)
   {
      IDWeakObjectRepresentation * weakReference = [IDWeakObjectRepresentation weakRepresentationOfObject:viewController];
      NSNumber * indexNumber = _indexByControllerReference[weakReference];

      if (indexNumber)
      {
         return indexNumber.unsignedIntegerValue;
      }

      return NSNotFound;
   }
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

- (UIViewController *)dequeueReusableViewControllerWithReuseIdentifier:(NSString *)reuseIdentifier forObject:(id)object atIndex:(NSUInteger)index
{
   NSAssert(reuseIdentifier != nil, @"Reuse identifier cannot be nil");
   NSAssert(object != nil, @"Object cannot be nil");

   id viewController = [self inactiveViewControllerForReuseWithIdentifier:reuseIdentifier
                                              alreadyAssociatedWithObject:object];

   // Reuse a different controller if available
   if (!viewController)
   {
      viewController = [self inactiveViewControllerForReuseIdentifier:reuseIdentifier
                                              byAssociatingWithObject:object
                                                              atIndex:index];
   }

   if (!viewController)
   {
      viewController = [self createViewControllerForReuseIdentifier:reuseIdentifier
                                            byAssociatingWithObject:object];
   }

   @synchronized(_indexByControllerReference)
   {
      IDWeakObjectRepresentation * weakReference = [IDWeakObjectRepresentation weakRepresentationOfObject:viewController];

      _indexByControllerReference[weakReference] = @(index);
   }

   return viewController;
}


#pragma mark - Data source change handling

- (void)beginUpdates
{
   ++_updateLevel;
}

- (void)endUpdates
{
   if (--_updateLevel == 0)
   {
      [self reloadData];
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

- (void)reloadData
{
   UIViewController * currentController = self.activeViewController;
   id                 object            = self.activeObject;
   NSUInteger         index             = self.indexOfActiveViewController;

   // The controller no longer exists, show the current one instead
   if (index == NSNotFound)
   {
      UIViewController * controllerToPresent = nil;
      IDDynamicPageViewControllerNavigationDirection direction;

      // There was an object before the controller, check if it's still in the
      // data source.
      if (_previousObject)
      {
         index     = [_dataSource pageViewController:self indexOfObject:_previousObject];
         object    = _previousObject;
         direction = IDDynamicPageViewControllerNavigationDirectionReverse;
      }

      // If not, maybe the object that was after the controller
      if (index == NSNotFound && _nextObject)
      {
         index     = [_dataSource pageViewController:self indexOfObject:_nextObject];
         object    = _nextObject;
         direction = IDDynamicPageViewControllerNavigationDirectionForward;
      }

      // Either the previous or next still exists in the data source, so we'll
      // show a controller close to where the user was before.
      if (index != NSNotFound)
      {
         controllerToPresent = [_dataSource pageViewController:self viewControllerForObject:object];
      }
      // Otherwise everything we know is lost so we'll just show the default
      // controller
      else if ([_dataSource numberOfPagesInPageViewController:self] > 0)
      {
         index               = 0;
         controllerToPresent = [_dataSource pageViewController:self viewControllerForPageAtIndex:index];
         direction           = IDDynamicPageViewControllerNavigationDirectionReverse;
      }
      else
      {
         // there are no controllers, but we'll set these anyway for clarity
         index               = NSNotFound;
         controllerToPresent = nil;
         direction           = IDDynamicPageViewControllerNavigationDirectionReverse;
      }

      // Fade the controller out so that it looks like it is disappearing.
      [UIView animateWithDuration:0.15
                       animations:^{
                          currentController.view.alpha = 0.0f;
                       }];

      [self setViewController:controllerToPresent
                    direction:direction animated:YES
                   completion:^(BOOL completed)
       {
          // Reset last controller to 100% opacity
          currentController.view.alpha = 1.0f;
       }];
   }
   else
   {
      [self setViewController:currentController
                    direction:IDDynamicPageViewControllerNavigationDirectionForward
                     animated:NO completion:nil];
   }

   @synchronized(_indexByControllerReference)
   {
      IDWeakObjectRepresentation * weakReference = [IDWeakObjectRepresentation weakRepresentationOfObject:_activeViewController];

      _indexByControllerReference[weakReference] = @(index);
   }
}

#pragma mark - Page control

- (UIPageControl *)pageControl
{
   if (!_pageControl)
   {
      _pageControl = [[UIPageControl alloc] initWithFrame:self.view.bounds];
   }

   return _pageControl;
}

- (void)setPageControlPosition:(IDDynamicPageViewControllerPageControlPosition)pageControlPosition
{
   if (pageControlPosition == _pageControlPosition)
   {
      return;
   }

   [self willChangeValueForKey:@"pageControlPosition"];
   _pageControlPosition = pageControlPosition;
   [self didChangeValueForKey:@"pageControlPosition"];

   [self updatePageControlLayout];
}

- (void)setPageControlOverlaysContent:(BOOL)pageControlOverlaysContent
{
   if (_pageControlOverlaysContent == pageControlOverlaysContent)
   {
      return;
   }

   [self willChangeValueForKey:@"pageControlOverlaysContent"];
   _pageControlOverlaysContent = pageControlOverlaysContent;
   [self didChangeValueForKey:@"pageControlOverlaysContent"];

   [self updatePageControlLayout];
}

- (void)updatePageControl
{
   NSUInteger numberOfPages = [_dataSource numberOfPagesInPageViewController:self];
   NSUInteger minimumPages  = (_pageControl.hidesForSinglePage) ? 1 : 0;
   BOOL       needsLayout   = (numberOfPages <= minimumPages) != (_pageControl.numberOfPages <= minimumPages);

   _pageControl.numberOfPages = numberOfPages;
   _pageControl.currentPage   = self.indexOfActiveViewController;

   if (needsLayout)
   {
      [self updatePageControlLayout];
      [self.view layoutIfNeeded];
   }
}

- (void)updatePageControlLayout
{
   NSLayoutConstraint * constraint;
   NSArray            * constraints;
   NSDictionary       * views;
   NSMutableArray     * pageControlConstraints = [NSMutableArray new];
   UIView             * parentView             = self.view;

   views = NSDictionaryOfVariableBindings(_pageControl,
                                          _controllerContainerView);

   // Install constraints that will not need to be removed later
   if (!_pageControlLayoutConstraints)
   {
      constraints = [NSLayoutConstraint
                     constraintsWithVisualFormat:@"H:|[_pageControl]|"
                     options:0 metrics:nil views:views];
      [parentView addConstraints:constraints];
      constraints = [NSLayoutConstraint
                     constraintsWithVisualFormat:@"V:[_pageControl]|"
                     options:0 metrics:nil views:views];
      [parentView addConstraints:constraints];
   }
   else
   {
      [parentView removeConstraints:_pageControlLayoutConstraints];
   }

   // This setting determines whether the controller container is pinned to the
   // bottom of the superview
   if (_pageControlOverlaysContent)
   {
      constraints = [NSLayoutConstraint
                     constraintsWithVisualFormat:@"V:[_controllerContainerView]|"
                     options:0 metrics:nil views:views];
      [pageControlConstraints addObjectsFromArray:constraints];
      [parentView addConstraints:constraints];
   }
   // or to the top of the page control
   else
   {
      constraints = [NSLayoutConstraint
                     constraintsWithVisualFormat:@"V:[_controllerContainerView][_pageControl]"
                     options:0 metrics:nil views:views];
      [pageControlConstraints addObjectsFromArray:constraints];
      [parentView addConstraints:constraints];
   }

   // If the page control is not supposed to be visible, give it a height of
   // zero. It will also be marked hidden = YES
   if (_pageControlPosition == IDDynamicPageViewControllerPageControlPositionNone)
   {
      _pageControl.hidden = YES;

      constraint = [NSLayoutConstraint
                    constraintWithItem:_pageControl
                    attribute:NSLayoutAttributeHeight
                    relatedBy:NSLayoutRelationEqual
                    toItem:nil
                    attribute:NSLayoutAttributeNotAnAttribute
                    multiplier:1.0f constant:0.0f];
      [pageControlConstraints addObject:constraint];
      [parentView addConstraint:constraint];
   }
   else
   {
      _pageControl.hidden = NO;
   }

   _pageControlLayoutConstraints = pageControlConstraints;
}

#pragma mark - Layout

- (void)applyTransformsInterpolatedTo:(CGFloat)interpolationRatio inDirection:(IDDynamicPageViewControllerNavigationDirection)direction
{
   if (_otherViewController)
   {
      CATransform3D activeControllerTransform = [self finalTransformForDisappearingViewController:_activeViewController
                                                                                        direction:direction
                                                                                   interpolatedTo:interpolationRatio];
      CATransform3D appearingControllerTransform = [self initialTransformForAppearingViewController:_otherViewController
                                                                                          direction:direction
                                                                                     interpolatedTo:interpolationRatio];

      _activeViewController.view.layer.transform = activeControllerTransform;
      _otherViewController.view.layer.transform  = appearingControllerTransform;
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
   CGRect bounds = _controllerContainerView.bounds;
   CGSize offset = bounds.size;

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
   CGRect bounds = _controllerContainerView.bounds;
   CGSize offset = bounds.size;

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
   CGRect bounds = _controllerContainerView.bounds;
   CGSize offset = bounds.size;

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
   UIView             * controllerView = viewController.view;

   controllerView.translatesAutoresizingMaskIntoConstraints = NO;

   constraint = [NSLayoutConstraint
                 constraintWithItem:controllerView
                 attribute:NSLayoutAttributeWidth
                 relatedBy:NSLayoutRelationEqual
                 toItem:_controllerContainerView
                 attribute:NSLayoutAttributeWidth
                 multiplier:1.0f constant:0.0f];
   [_controllerContainerView addConstraint:constraint];

   constraint = [NSLayoutConstraint
                 constraintWithItem:controllerView
                 attribute:NSLayoutAttributeHeight
                 relatedBy:NSLayoutRelationEqual
                 toItem:_controllerContainerView
                 attribute:NSLayoutAttributeHeight
                 multiplier:1.0f constant:0.0f];
   [_controllerContainerView addConstraint:constraint];

   constraint = [NSLayoutConstraint
                 constraintWithItem:controllerView
                 attribute:NSLayoutAttributeCenterX
                 relatedBy:NSLayoutRelationEqual
                 toItem:_controllerContainerView
                 attribute:NSLayoutAttributeCenterX
                 multiplier:1.0f constant:0.0f];
   [_controllerContainerView addConstraint:constraint];

   constraint = [NSLayoutConstraint
                 constraintWithItem:controllerView
                 attribute:NSLayoutAttributeCenterY
                 relatedBy:NSLayoutRelationEqual
                 toItem:_controllerContainerView
                 attribute:NSLayoutAttributeCenterY
                 multiplier:1.0f constant:0.0f];
   [_controllerContainerView addConstraint:constraint];
}

#pragma mark - Gesture handling

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
   if (![panGesture isEqual:_panGestureRecognizer])
   {
      return;
   }

   UIGestureRecognizerState state = panGesture.state;
   CGPoint translation            = [_panGestureRecognizer translationInView:_controllerContainerView];
   CGPoint velocity               = [_panGestureRecognizer velocityInView:_controllerContainerView];
   IDDynamicPageViewControllerNavigationDirection direction;
   CGRect  bounds                 = _controllerContainerView.bounds;
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
         break;
   }

   if (_simultaneousPanGestureRecognizer)
   {
      if (![self shouldApplyTranslationWithSimultaneousGesturesInDirection:direction])
      {
         [self applyTransformsInterpolatedTo:0.0f inDirection:IDDynamicPageViewControllerNavigationDirectionForward];

         _translationInInnerScrollView = [_simultaneousPanGestureRecognizer translationInView:_simultaneousPanGestureRecognizer.view];
         return;
      }

      translation.x -= _translationInInnerScrollView.x;
      translation.y -= _translationInInnerScrollView.y;
   }

   // Calculate the completion ratio of the gesture
   switch (_navigationOrientation)
   {
      case IDDynamicPageViewControllerNavigationOrientationHorizontal:
         interpolationRatio = ABS(translation.x / bounds.size.width);
         break;

      case IDDynamicPageViewControllerNavigationOrientationVertical:
         interpolationRatio = ABS(translation.y / bounds.size.height);
         break;
   }

   if (state == UIGestureRecognizerStateEnded)
   {
      CGFloat            finalInterpolationRatio = 0.0f;
      UIViewController * otherViewController     = _otherViewController;
      UIViewController * activeViewController    = _activeViewController;

      // Only finish the transition if the gesture is still moving in the
      // direction of the page turn, and has either passed the distance or
      // velocity thresholds. Otherwise return to the previous controller
      if (otherViewController &&
          velocityOnCriticalAxis >= 0.0f &&
          (velocityOnCriticalAxis > _minimumGestureVelocityToChangeViewController ||
           interpolationRatio > _minimumGestureCompletionRatioToChangeViewController))
      {
         finalInterpolationRatio = 1.0f;

         // Transition has already begun for the appearing controller, so just
         // tell the active controller that it will be disappearing
         [self willRemoveViewController:activeViewController animated:YES];

         [self willTransitionToViewController:otherViewController];
      }
      else
      {
         [self didShowViewController:otherViewController animated:YES];
         [self willRemoveViewController:otherViewController animated:YES];
      }

      _simultaneousPanGestureRecognizer.enabled = YES;
      _simultaneousPanGestureRecognizer         = nil;
      _translationInInnerScrollView             = CGPointZero;
      _panGestureRecognizer.enabled             = NO;

      [self animateWithDuration:_animationDuration
                        options:(UIViewAnimationOptionCurveEaseOut)
                     animations:^{
                        [self applyTransformsInterpolatedTo:finalInterpolationRatio
                                                inDirection:direction];

                        // Update the active controller with animated page dot
                        // transition
                        if (finalInterpolationRatio > 0.5f)
                        {
                           self.activeViewController = otherViewController;
                        }
                     }
                     completion:^(BOOL completed) {
                        // Transition finished
                        if (finalInterpolationRatio > 0.5f)
                        {
                           [self removeViewController:activeViewController
                                             animated:YES];
                           [self didShowViewController:otherViewController
                                              animated:YES];
                        }
                        // Transition cancelled
                        else
                        {
                           [self removeViewController:otherViewController
                                             animated:YES];
                        }

                        activeViewController.view.layer.transform = CATransform3DIdentity;
                        otherViewController.view.layer.transform = CATransform3DIdentity;

                        _otherViewController = nil;
                        _appearingControllerDirection = IDDynamicPageViewControllerNavigationDirectionNone;

                        _panGestureRecognizer.enabled = YES;

                        [self didFinishAnimating:YES
                          previousViewController:activeViewController
                             transitionCompleted:completed];

                        _transitioningDueToUserInteraction = NO;

                        dispatch_async(dispatch_get_main_queue(), ^{
                           [self prepareNeighboringControllerIfNecessaryInDirection:direction];
                        });
                     }];
   }
   else if (state == UIGestureRecognizerStateChanged)
   {
      [self showNeighboringControllerIfNecessaryInDirection:direction];
      
      [self applyTransformsInterpolatedTo:interpolationRatio inDirection:direction];
   }
   else if (state == UIGestureRecognizerStateBegan)
   {
      _transitioningDueToUserInteraction = YES;
   }
}

- (BOOL)shouldApplyTranslationWithSimultaneousGesturesInDirection:(IDDynamicPageViewControllerNavigationDirection)direction
{
   if (_simultaneousPanGestureRecognizer)
   {
      UIScrollView * scrollView  = (id)_simultaneousPanGestureRecognizer.view;
      CGRect         visibleRect = [self visibleRectInScrollView:scrollView];
      CGSize         contentSize = scrollView.contentSize;

      switch (_navigationOrientation)
      {
         case IDDynamicPageViewControllerNavigationOrientationHorizontal:
            if (direction == IDDynamicPageViewControllerNavigationDirectionForward)
            {
               return CGRectGetMaxX(visibleRect) >= contentSize.width;
            }
            else
            {
               return CGRectGetMinX(visibleRect) <= 0.0f;
            }

         case IDDynamicPageViewControllerNavigationOrientationVertical:
            if (direction == IDDynamicPageViewControllerNavigationDirectionForward)
            {
               return CGRectGetMaxY(visibleRect) >= contentSize.height;
            }
            else
            {
               return CGRectGetMinY(visibleRect) <= 0.0f;
            }
      }
   }

   return YES;
}

- (BOOL)shouldBeginPanGestureWithGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
   CGPoint velocity = [panGestureRecognizer velocityInView:_controllerContainerView];

   switch (_navigationOrientation)
   {
      case IDDynamicPageViewControllerNavigationOrientationHorizontal:
         return ABS(velocity.x) > ABS(velocity.y);

      case IDDynamicPageViewControllerNavigationOrientationVertical:
         return ABS(velocity.y) > ABS(velocity.x);
   }
}

- (CGRect)visibleRectInScrollView:(UIScrollView *)scrollView
{
   if (!scrollView)
   {
      return CGRectZero;
   }

   CGRect   visibleRect = CGRectZero;
   CGFloat  zoomScale   = scrollView.zoomScale;
   UIView * zoomView    = nil;

   visibleRect.origin = scrollView.contentOffset;

   if (zoomScale != 1.0f && [scrollView.delegate respondsToSelector:@selector(viewForZoomingInScrollView:)])
   {
      zoomView = [scrollView.delegate viewForZoomingInScrollView:scrollView];

      if (zoomView)
      {
         visibleRect.origin.x -= zoomView.frame.origin.x;
         visibleRect.origin.y -= zoomView.frame.origin.y;
         visibleRect.size      = scrollView.contentSize;
      }
   }

   if (!zoomView)
   {
      visibleRect.size = scrollView.bounds.size;

      visibleRect.origin.x    /= zoomScale;
      visibleRect.origin.y    /= zoomScale;
      visibleRect.size.width  /= zoomScale;
      visibleRect.size.height /= zoomScale;
   }

   return visibleRect;
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
   
   IDLogInfo(@"Controller %@ is now active", activeViewController);
   
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

- (void)didActivateViewController:(UIViewController *)viewController
{
   if ([_delegate respondsToSelector:@selector(pageViewController:didActivateViewController:)])
   {
      [_delegate pageViewController:self didActivateViewController:viewController];
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

#pragma mark - UIGestureRecognizerDelegate implementation

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
   if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
   {
      return [self shouldBeginPanGestureWithGestureRecognizer:(id)gestureRecognizer];
   }
   
   return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
   if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
       [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]])
   {
      UIScrollView * scrollView = (id)otherGestureRecognizer.view;
      
      // If the scroll view does not scroll along the axis of interest, do not
      // run the recognizers simultaneously.
      switch (_navigationOrientation)
      {
         case IDDynamicPageViewControllerNavigationOrientationHorizontal:
            if (scrollView.contentSize.width <= scrollView.bounds.size.width)
            {
               return NO;
            }
            break;
            
         case IDDynamicPageViewControllerNavigationOrientationVertical:
            if (scrollView.contentSize.height <= scrollView.bounds.size.height)
            {
               return NO;
            }
            break;
      }
      
      _simultaneousPanGestureRecognizer = (id)otherGestureRecognizer;
      _translationInInnerScrollView     = CGPointZero;
      
      return YES;
   }
   return NO;
}

@end

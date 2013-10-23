//
//  IDDynamicPageViewController.h
//  DynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/16/13.
//
//

#import <UIKit/UIKit.h>

#ifndef IDDPVC_SUPERCLASS
// Allows substitution of a different view controller superclass for
// <IDDynamicPageViewController> in the event that your app uses a custom
// subclass of `UIViewController`
#define IDDPVC_SUPERCLASS UIViewController
#endif

#ifdef IDDPVC_SUPERCLASS_IMPORT
// Using IDDPVC_SUPERCLASS requires the class to be imported, for example
// #define IDDPVC_SUPERCLASS_IMPORT "MyViewController.h"
#import IDDPVC_SUPERCLASS_IMPORT
#endif

#define IDLogInfo(format, ...) NSLog(format, ## __VA_ARGS__)

/// Used to specify the position of the <pageControl> element with respect to
/// the content of the page view controller.
typedef NS_ENUM (NSUInteger, IDDynamicPageViewControllerPageControlPosition) {
   /// The page control is not shown.
   IDDynamicPageViewControllerPageControlPositionNone,
   /// The page control is at the top of the view
   IDDynamicPageViewControllerPageControlPositionTop,
   /// The page control is at the bottom of the view
   IDDynamicPageViewControllerPageControlPositionBottom,
   /// The page control is on the left edge of the view
   IDDynamicPageViewControllerPageControlPositionLeft,
   /// The page control is on the right edge of the view
   IDDynamicPageViewControllerPageControlPositionRight,
   /// The page control is on the left edge of the view in ltr languages such
   /// as English, but on the right edge of the view in rtl languages
   IDDynamicPageViewControllerPageControlPositionLeading,
   /// The page control is on the right edge of the view in ltr languages such
   /// as English, but on the left edge of the view in rtl languages
   IDDynamicPageViewControllerPageControlPositionTrailing
};

typedef NS_ENUM (NSUInteger, IDDynamicPageViewControllerNavigationOrientation)
{
   IDDynamicPageViewControllerNavigationOrientationHorizontal,
   IDDynamicPageViewControllerNavigationOrientationVertical
};

typedef NS_ENUM (NSUInteger, IDDynamicPageViewControllerNavigationDirection)
{
   IDDynamicPageViewControllerNavigationDirectionNone,
   IDDynamicPageViewControllerNavigationDirectionForward,
   IDDynamicPageViewControllerNavigationDirectionReverse
};

typedef NS_ENUM (NSUInteger, IDDynamicPageViewControllerTransitionStyle)
{
   IDDynamicPageViewControllerTransitionStyleScroll,
   IDDynamicPageViewControllerTransitionStyleStack
};

@protocol IDDynamicPageViewControllerDelegate;
@protocol IDDynamicPageViewControllerDataSource;

@interface IDDynamicPageViewController : IDDPVC_SUPERCLASS
{
@private
#pragma mark - ivars
#pragma mark Controller management and reuse ivars

   NSMutableDictionary * _controllerClassByReuseIdentifier;
   NSMutableDictionary * _reusableControllerQueueByReuseIdentifier;
   NSMutableDictionary * _activeControllerSetByReuseIdentifier;
   NSMutableDictionary * _reuseIdentifierByControllerReference;
   NSMutableDictionary * _indexByControllerReference;
   NSMutableDictionary * _viewControllerReferenceByObjectReference;
   NSMutableDictionary * _objectReferenceByViewControllerReference;

#pragma mark Controller removal handling

   __weak id  _previousObject;
   __weak id  _nextObject;
   NSUInteger _indexOfActiveViewControllerAfterChanges;
   NSUInteger _updateLevel;
   BOOL       _dataWasChangedWithoutBeginUpdates;

#pragma mark Interaction support

   UIPanGestureRecognizer * _panGestureRecognizer;
   IDDynamicPageViewControllerNavigationDirection _appearingControllerDirection;
}

#pragma mark - Initialization
/// @name      Initialization

/// Initializes an `IDDynamicPageViewController` with the specified orientation and
/// spacing
///
/// @param navigationOrientation Specifies whether the pages scroll horizontally
/// or vertically
/// @param interPageSpacing The gap between pages
- (id)initWithNavigationOrientation:(IDDynamicPageViewControllerNavigationOrientation)navigationOrientation interPageSpacing:(CGFloat)interPageSpacing;

#pragma mark - Configuring page display
/// @name      Configuring page display

/// The gap between each page in the scroll transition.
@property (nonatomic, assign, readonly) CGFloat interPageSpacing;

/// The view controller that was active before and that will become active again
/// the page transition is cancelled.
///
/// When scrolling programmatically, the `activeViewController` is set as soon
/// as the animation begins. When swiping, the `activeViewController` is set
/// upon lifting the swiping finger off the screen.
@property (nonatomic, strong, readonly) UIViewController * activeViewController;

/// The object represented by the visible view controller
///
/// @see setObject:animated:completion:
@property (nonatomic, strong, readonly) id activeObject;

/// The index of the visible view controller in the data source
@property (nonatomic, assign, readonly) NSUInteger indexOfActiveViewController;

/// The view controller that will become active if the page transition gesture
/// is completed, or that will be removed once the page transition finishes.
///
/// When swiping, the `otherViewController` corresponds to the controller in
/// the direction of the swipe. Swiping forward then backward without releasing
/// the drag will cause the `otherViewController` to switch from the view
/// controller after to the view controller before.
@property (nonatomic, strong, readonly) UIViewController * otherViewController;

/// Determines how the page controller transitions between pages.
@property (nonatomic, assign) IDDynamicPageViewControllerTransitionStyle transitionStyle;

#pragma mark - Configuring the page control element
/// @name      Configuring the page control element

/// The page control showing indicators corresponding to the current page and
/// others in the data source.
@property (nonatomic, strong, readonly) UIPageControl * pageControl;

/// Defines the location of the page control relative to the page view
/// controller's bounds.
///
/// Default is <IDDynamicPageViewControllerPageControlPositionNone>. If the
/// <navigationOrientation> is horizontal, only
/// <IDDynamicPageViewControllerPageControlPositionNone>,
/// <IDDynamicPageViewControllerPageControlPositionTop>, and
/// <IDDynamicPageViewControllerPageControlPositionBottom> are supported. The
/// remaining positions may be used with a vertical orientation.
/// @see navigationOrientation
@property (nonatomic, assign) IDDynamicPageViewControllerPageControlPosition pageControlPosition;

/// If `YES`, the page control will appear over the content view controller,
/// otherwise the content view controller will be sized to abut the page
/// control.
@property (nonatomic, assign) BOOL pageControlOverlaysContent;

/// Specifies whether the pages transition horizontally or vertically.
/// @see pageControlPosition
@property (nonatomic, assign, readonly) IDDynamicPageViewControllerNavigationOrientation navigationOrientation;

#pragma mark - Programmatic navigation
/// @name      Programmatic navigation

/// Specifies the maximum duration of animated page transitions.
///
/// Animations resulting from input gestures may use a shorter duration
/// depending on the velocity and translation of the pan gesture.
@property (nonatomic, assign) NSTimeInterval animationDuration;

/// Set visible view controller, optionally with animation.
///
/// @param viewController The controller that will be visible after the
/// animation has completed
/// @param direction Determines whether the controllers animate as if the new
/// one is before or after the old one.
///
/// @see setObject:animated:completion:
- (void)setViewController:(UIViewController *)viewController direction:(IDDynamicPageViewControllerNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion;

/// Set visible view controller based on an object in the data source.
///
/// If the object does not exist in the data source, the current view controller
/// will remain visible and `completion` will be called with a negatory
/// argument. If the object is already being displayed, it is given an
/// opportunity to update the view controller by calling
/// <setViewController:direction:animated:completion:>.
///
/// The transition direction is determined automatically based on the index
/// of the current object compared to the index of the new object.
///
/// @param object     An object in the <dataSource>
/// @param animated   Whether or not to animate the transition
/// @param completion Called with `YES` if the specified object is now
/// represented by the current controller, otherwise `NO`.
///
/// @see setViewController:direction:animated:completion:
- (void)setObject:(id)object animated:(BOOL)animated completion:(void (^)(BOOL completed))completion;

#pragma mark - Gesture-based navigation
/// @name      Gesture-based navigation

/// The ratio at which releasing the pan gesture will activate the
/// <otherViewController>.
///
/// Default is `0.3f` which corresponds to a pan translation covering at least
/// 30% of the controller's dimension in the direction of the transition.
@property (nonatomic, assign) CGFloat minimumGestureCompletionRatioToChangeViewController;

/// <#Description#>
@property (nonatomic, assign) CGFloat minimumGestureVelocityToChangeViewController;

#pragma mark - View Controller Management
/// @name      View Controller Management

/// <#description#>
@property (nonatomic, weak) id<IDDynamicPageViewControllerDataSource> dataSource;

/// <#description#>
@property (nonatomic, weak) id<IDDynamicPageViewControllerDelegate> delegate;

/// Register a class for use in creating new view controllers.
///
/// Prior to calling the <dequeueReusableViewControllerWithReuseIdentifier:forIndex:>
/// method of the page view controller, you must use this method to tell the
/// page view controller how to create a new controller of the given type. If a
/// controller of the specified type is not currently in a reuse queue, the
/// page view controller uses the provided information to create a new
/// controller automatically.
///
/// If you previously registered a class with the same reuse identifier, the
/// class you specify in the `viewControllerClass` parameter replaces the old
/// entry. You may specify `nil` for `viewControllerClass` if you want to
/// unregister the class from the specified reuse identifier.
///
/// @param viewControllerClass The class of a controller that you want to use in
/// the page view controller.
/// @param reuseIdentifier The reuse identifier to associate with the specified
/// class. This parameter must not be `nil` and must not be an empty string.
/// @see dequeueReusableViewControllerWithReuseIdentifier:forIndex:
- (void)registerClass:(Class)viewControllerClass forViewControllerWithReuseIdentifier:(NSString *)reuseIdentifier;

/// Returns a reusable view controller located by its identifier
///
/// Call this method from your data source object when asked to provide a new
/// view controller for the page view controller. This method dequeues an
/// existing controller if one is available or creates a new one based on the
/// class you previously registered. Preference is given to any view controller
/// representing the same object, otherwise controllers are reused in a FIFO
/// queue.
///
/// @warning You must register a class using the
/// <registerClass:forViewControllerWithReuseIdentifier:> method before calling
/// this method.
///
/// @discussion If you registered a class for the specified identifier and a new
/// controller must be created, this method initializes the controller by
/// calling its `initWithNibName:bundle:` method. The `nibName` parameter will
/// be `nil`, requiring controller and nib naming to conform to standard
/// heuristics for nib lookup. If an existing controller was available for
/// reuse, this method calls the controller's `prepareForReuse` method instead.
///
/// @param reuseIdentifier The reuse identifier for the specifxied controller.
/// This parameter must not be `nil`.
/// @param object The object that the controller will represent.
- (UIViewController *)dequeueReusableViewControllerWithReuseIdentifier:(NSString *)reuseIdentifier forObject:(id)object atIndex:(NSUInteger)index;

/// Returns the view controller currently representing the specified object if
/// any exist.
///
/// @param object The object in the data source represented by a controller
///
/// @return the view controller representing the object or `nil` if none are
- (UIViewController *)viewControllerForObject:(id)object;

/// Returns the object currently represented by the specified view controller.
///
/// @param viewController The view controller within the page view controller
///
/// @return the object represented by the controller or `nil` if unknown
- (id)objectForViewController:(UIViewController *)viewController;

#pragma mark - Inserting, Deleting, and Moving Pages
/// @name      Inserting, Deleting, and Moving Pages

/// Call before changes are made to the data source.
///
/// Can be nested, in which case the controller will wait until all changes are
/// complete before updating.
- (void)beginUpdates;

/// Call after changes are made to the data source.
///
/// Upon ending updates, the controller will call <reloadData>.
/// @see reloadData
- (void)endUpdates;

/// Reloads the view controllers and page control of the receiver.
///
/// Call this method to apply any changes that will affect the order or
/// availability of view controllers. `IDDynamicPageViewController` will not
/// automatically detect changes to the data source, to the current view
/// controller, or to the controllers adjacent to the current view controller.
/// While the change may not necessarily affect the current or adjacent
/// controllers, it is easier and safer to call this method for all updates.
///
/// No view controllers are deallocated as a result of this call. The current
/// controller and two adjacent controllers will be reconfigured, offering the
/// opportunity to apply changes to the view controllers if necessary. There is
/// no inherent efficiency problem with this method as might be seen in
/// `UITableView`.
///
/// If the current view controller is no longer in the data source, a different
/// controller will be displayed. Under all other circumstances the same view
/// controller will remain on the screen regardless of its position in the
/// data source.
- (void)reloadData;

@end

@protocol IDDynamicPageViewControllerDelegate <NSObject>

@optional

/// Sent when a gesture-initiated or programmatic transition begins.
///
/// @param pageViewController    The page view controller
/// @param pendingViewController The view controller that may be displayed as a
/// result of the gesture.
- (void)pageViewController:(IDDynamicPageViewController *)pageViewController willTransitionToViewController:(UIViewController *)pendingViewController;

/// Sent when a gesture-initiated or programmatic transition ends.
///
/// @param pageViewController     The page view controller
/// @param finished               Indicates whether the animation finished
/// @param previousViewController The controller that was visible before this
/// interaction
/// @param completed              Indicates whether the transition completed or
/// bailed out (if the user let go early)
- (void)pageViewController:(IDDynamicPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewController:(UIViewController *)previousViewController transitionCompleted:(BOOL)completed;

/// Returns the complete set of supported interface orientations for the page
/// view controller, as determined by the delegate.
///
/// If not implemented by the delegate, the page view controller will support
/// all interface orientations.
///
/// @param pageViewController The page view controller
///
/// @return One of the `UIInterfaceOrientationMask` constants that represents
/// the set of interface orientations supported by the page view controller.
- (NSUInteger)pageViewControllerSupportedInterfaceOrientations:(IDDynamicPageViewController *)pageViewController;

/// Returns the preferred orientation for presentation of the page view
/// controller, as determined by the delegate.
///
/// If not implemented by the delegate, the page view controller will prefer
/// the current interface orientation as determined by the status bar
/// orientation.
///
/// @param pageViewController The page view controller
///
/// @return The preferred orientation for presenting the page view controller.
- (UIInterfaceOrientation)pageViewControllerPreferredInterfaceOrientationForPresentation:(IDDynamicPageViewController *)pageViewController;

@end

/// The `IDDynamicPageViewControllerDataSource` protocol is adopted by an object that
/// provides view controllers to the page view controller on an as-needed basis,
/// in response to navigation gestures.
///
/// The data source is also responsible for tracking objects represented by each
/// view controller. The association between view controllers and objects is
/// crucial to maintain proper order of the view controllers. The data source
/// *must not* store view controllers; instead it may query the page view
/// controller to determine the object associated with a particular view
/// controller.
@protocol IDDynamicPageViewControllerDataSource <UIPageViewControllerDataSource>

/// Returns the view controller that represents the given object. (required)
///
/// @param pageViewController The page view controller
/// @param object             An object in the data source
///
/// @return The view controller that represents the given object, or `nil` to
/// indicate that there is no controller for that object.
- (UIViewController *)pageViewController:(IDDynamicPageViewController *)pageViewController viewControllerForObject:(id)object;

/// Returns the view controller that represents the object at the given index.
/// (required)
///
/// @param pageViewController The page view controller
/// @param index              The index of an object in the data source
///
/// @return The view controller that represents the given index, or `nil` to
/// indicate that there is no controller for that index.
- (UIViewController *)pageViewController:(IDDynamicPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)index;

/// Returns the controller that should be displayed when the data source is set.
/// (required)
///
/// @param pageViewController The page view controller
///
/// @return the controller to display
- (UIViewController *)pageViewControllerDefaultViewController:(IDDynamicPageViewController *)pageViewController;

/// Returns the index of the object in the data source. (required)
///
/// @param pageViewController The page view controller
/// @param object             The object to look up
///
/// @return The index or `NSNotFound` if the object is not in the data source
- (NSUInteger)pageViewController:(IDDynamicPageViewController *)pageViewController indexOfObject:(id)object;

/// Returns the object at the specified index in the data source. (required)
///
/// @param pageViewController The page view controller
/// @param index              An index in the data source
///
/// @return The object or `nil` if the object is not in the data source
- (id)pageViewController:(IDDynamicPageViewController *)pageViewController objectAtIndex:(NSUInteger)index;

@optional

/// Returns the number of objects in the data source.
///
/// This value may be used in conjunction with
/// <pageViewController:indexOfObject:> to manage a `UIPageControl`.
///
/// @param pageViewController The page view controller
///
/// @return The number of objects in the data source
- (NSInteger)numberOfPagesInPageViewController:(IDDynamicPageViewController *)pageViewController;

@end


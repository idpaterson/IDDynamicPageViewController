//
//  IDDynamicPageViewControllerTests.m
//  IDDynamicPageViewControllerTests
//
//  Created by Ian Paterson on 10/18/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "IDDynamicPageViewController.h"
#import "IDLifecycleVerificationViewController.h"
#import "IDMutablePageViewDataSource.h"

@interface IDDynamicPageViewControllerTests : XCTestCase

@end

@implementation IDDynamicPageViewControllerTests

#pragma mark - Factory methods

- (IDDynamicPageViewController *)newPageViewControllerInViewHierarchy
{
   IDDynamicPageViewController * controller = [[IDDynamicPageViewController alloc] initWithNavigationOrientation:IDDynamicPageViewControllerNavigationOrientationHorizontal
                                                                                                interPageSpacing:5.0f];
   UIWindow         * window         = [UIApplication sharedApplication].windows[0];
   UIViewController * rootController = window.rootViewController;

   controller.view.frame = rootController.view.bounds;

   [controller registerClass:self.controllerClass1 forViewControllerWithReuseIdentifier:self.reuseIdentifier1];
   [controller registerClass:self.controllerClass2 forViewControllerWithReuseIdentifier:self.reuseIdentifier2];

   [rootController addChildViewController:controller];
   [rootController.view addSubview:controller.view];
   [controller didMoveToParentViewController:rootController];

   [controller endAppearanceTransition];

   return controller;
}

- (UIPageViewController *)newUIPageViewControllerInViewHierarchy
{
   UIPageViewController * controller = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                       navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                     options:nil];
   UIWindow * window = [UIApplication sharedApplication].windows[0];

   controller.view.frame = CGRectMake(0.0f, 0.0f, 300.0f, 300.0f);
   UIViewController * rootController = window.rootViewController;

   [rootController addChildViewController:controller];
   [rootController.view addSubview:controller.view];
   [controller didMoveToParentViewController:rootController];

   [controller endAppearanceTransition];

   return controller;
}

- (NSString *)reuseIdentifier1
{
   return @"Object1";
}

- (NSString *)reuseIdentifier2
{
   return @"Object2";
}

- (Class)controllerClass1
{
   return [UIViewController class];
}

- (Class)controllerClass2
{
   return [UINavigationController class];
}

- (IDMutablePageViewDataSource *)newDataSource
{
   IDMutablePageViewDataSource * dataSource = [IDMutablePageViewDataSource new];

   dataSource.reuseIdentifier = self.reuseIdentifier1;

   return dataSource;
}

- (IDMutablePageViewDataSource *)newDataSourceWithThreeItems
{
   IDMutablePageViewDataSource * dataSource = [IDMutablePageViewDataSource new];

   dataSource.reuseIdentifier = self.reuseIdentifier1;

   [dataSource addObject:@1];
   [dataSource addObject:@2];
   [dataSource addObject:@3];

   return dataSource;
}

- (IDMutablePageViewDataSource *)newDataSourceWithFiveItems
{
   IDMutablePageViewDataSource * dataSource = [self newDataSourceWithThreeItems];

   [dataSource addObject:@4];
   [dataSource addObject:@5];

   return dataSource;
}


#pragma mark - Test case setup and teardown

- (void)setUp
{
   [super setUp];
   // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
   UIWindow         * window         = [UIApplication sharedApplication].windows[0];
   UIViewController * rootController = window.rootViewController;
   NSArray          * subviews       = rootController.view.subviews.copy;

   for (UIView * subview in subviews)
   {
      id controller = subview.nextResponder;
      if ([controller isKindOfClass:[IDDynamicPageViewController class]])
      {
         [controller willMoveToParentViewController:nil];
         [subview removeFromSuperview];
         [controller removeFromParentViewController];
      }
   }

   [super tearDown];
}

#pragma mark - Test Cases

- (void)testDelegateAsssignment
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];

   id<IDDynamicPageViewControllerDelegate> delegate = mockProtocol(@protocol(IDDynamicPageViewControllerDelegate));

   assertThat(pageViewController.delegate, nilValue());

   pageViewController.delegate = delegate;

   assertThat(pageViewController.delegate, equalTo(delegate));

   pageViewController.delegate = nil;

   assertThat(pageViewController.delegate, nilValue());
}

#pragma mark - Switching view controllers

- (void)testSetViewController
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   UIViewController            * controller1        = [UIViewController new];
   UIViewController            * controller2        = [UIViewController new];

   assertThat(pageViewController.activeViewController, nilValue());

   [pageViewController setViewController:controller1
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:NO completion:nil];

   assertThat(pageViewController.activeViewController, equalTo(controller1));

   [pageViewController setViewController:controller2
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:NO completion:nil];

   assertThat(pageViewController.activeViewController, equalTo(controller2));
}

- (void)testSetViewControllerAnimated
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   UIViewController            * controller1        = [UIViewController new];
   UIViewController            * controller2        = [UIViewController new];

   assertThat(pageViewController.activeViewController, nilValue());

   [pageViewController setViewController:controller1
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:YES completion:nil];

   assertThat(pageViewController.activeViewController, equalTo(controller1));

   [pageViewController setViewController:controller2
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:YES completion:nil];

   assertThat(pageViewController.activeViewController, equalTo(controller2));
}

- (void)testSetViewControllerInterruption
{
   IDDynamicPageViewController * pageViewController   = [self newPageViewControllerInViewHierarchy];
   UIViewController            * controller1          = [IDLifecycleVerificationViewController new];
   UIViewController            * controller2          = [IDLifecycleVerificationViewController new];
   __block NSNumber            * controller1Completed = nil;
   __block NSNumber            * controller2Completed = nil;

   [pageViewController setViewController:controller1
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:NO
                              completion:^(BOOL completed) {
                                 controller1Completed = @(completed);
                              }];

   // controller1's is presented immediately rather than animated
   assertThat(controller1Completed, equalTo(@YES));

   assertThat(pageViewController.activeViewController, equalTo(controller1));

   // Interrupt the previous animation
   [pageViewController setViewController:controller2
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:YES
                              completion:^(BOOL completed) {
                                 controller2Completed = @(completed);
                              }];

   assertThat(pageViewController.activeViewController, equalTo(controller2));

   controller1Completed = nil;

   [pageViewController setViewController:controller1
                               direction:IDDynamicPageViewControllerNavigationDirectionReverse
                                animated:YES
                              completion:^(BOOL completed) {
                                 controller1Completed = @(completed);
                              }];

   assertThat(pageViewController.activeViewController, equalTo(controller1));

   // Make sure everything was cleaned up properly
   assertThat(controller1.parentViewController, equalTo(pageViewController));
   assertThat(controller1.view.superview, isNot(nilValue()));

   assertEventuallyWithBlock (^BOOL {
      return controller2.parentViewController == nil;
   });

   assertEventuallyWithBlock (^BOOL {
      return controller2.view.superview == nil;
   });

   // This animation was interrupted by the other
   assertEventuallyWithBlock (^BOOL {
      return controller2Completed && controller2Completed.boolValue == NO;
   });

   // This animation should complete normally
   assertEventuallyWithBlock (^BOOL {
      return controller1Completed && controller1Completed.boolValue == YES;
   });
}

- (void)testSetObjectWithoutDataSource
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   __block NSNumber            * objectCompleted    = nil;
   id object = @1;

   [pageViewController setObject:object
                        animated:YES
                      completion:^(BOOL completed) {
                         objectCompleted = @(completed);
                      }];

   assertThat(pageViewController.activeViewController, nilValue());

   assertEventuallyWithBlock (^BOOL {
      return objectCompleted.boolValue == NO;
   });
}

- (void)testSetNilObject
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   __block NSNumber            * objectCompleted    = nil;
   id object = nil;

   [pageViewController setObject:object
                        animated:YES
                      completion:^(BOOL completed) {
                         objectCompleted = @(completed);
                      }];

   assertThat(pageViewController.activeViewController, nilValue());

   assertEventuallyWithBlock (^BOOL {
      return objectCompleted.boolValue == NO;
   });
}

#pragma mark - View controller lifecycle

- (void)testLifecycleOnSetViewControllerInUIPageViewController
{
   UIPageViewController * pageViewController = [self newUIPageViewControllerInViewHierarchy];

   IDLifecycleVerificationViewController * controller1 = [IDLifecycleVerificationViewController new];
   IDLifecycleVerificationViewController * controller2 = [IDLifecycleVerificationViewController new];

   [pageViewController setViewControllers:@[controller1]
                                direction:UIPageViewControllerNavigationDirectionForward
                                 animated:NO completion:nil];

   assertThatUnsignedInteger(controller1.willMoveToNonNilParentViewControllerTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.didMoveToNonNilParentViewControllerTimes, equalTo(@1));

   // controller1 will appear
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionAppearingTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillAppearNotAnimatedTimes, equalTo(@1));

   // controller1 did appear
   assertThatUnsignedInteger(controller1.endAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidAppearNotAnimatedTimes, equalTo(@1));

   [pageViewController setViewControllers:@[controller2]
                                direction:UIPageViewControllerNavigationDirectionForward
                                 animated:NO completion:nil];

   // controller1 will disappear
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionTimes, equalTo(@2));
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionDisappearingTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillDisappearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillDisappearNotAnimatedTimes, equalTo(@1));

   // controller1 did disappear
   assertThatUnsignedInteger(controller1.endAppearanceTransitionTimes, equalTo(@2));
   assertThatUnsignedInteger(controller1.viewDidDisappearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidDisappearNotAnimatedTimes, equalTo(@1));

   assertThatUnsignedInteger(controller1.willMoveToNilParentViewControllerTimes, greaterThanOrEqualTo(@1));
   assertThatUnsignedInteger(controller1.didMoveToNilParentViewControllerTimes, equalTo(@1));


   assertThatUnsignedInteger(controller2.willMoveToNonNilParentViewControllerTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.didMoveToNonNilParentViewControllerTimes, equalTo(@1));

   // controller2 will appear
   assertThatUnsignedInteger(controller2.beginAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.beginAppearanceTransitionAppearingTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.viewWillAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.viewWillAppearNotAnimatedTimes, equalTo(@1));

   // controller2 did appear
   assertThatUnsignedInteger(controller2.endAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.viewDidAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.viewDidAppearNotAnimatedTimes, equalTo(@1));
}

- (void)testLifecycleOnSetViewControllerInUIPageViewControllerAnimated
{
   UIPageViewController * pageViewController = [self newUIPageViewControllerInViewHierarchy];

   IDLifecycleVerificationViewController * controller1 = [IDLifecycleVerificationViewController new];
   IDLifecycleVerificationViewController * controller2 = [IDLifecycleVerificationViewController new];

   // Regardless of the animated designation, this will not animate
   [pageViewController setViewControllers:@[controller1]
                                direction:UIPageViewControllerNavigationDirectionForward
                                 animated:YES completion:nil];

   assertThatUnsignedInteger(controller1.willMoveToNonNilParentViewControllerTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.didMoveToNonNilParentViewControllerTimes, equalTo(@1));

   // controller1 will appear
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionAppearingTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillAppearNotAnimatedTimes, equalTo(@1));

   // controller1 did appear
   assertThatUnsignedInteger(controller1.endAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidAppearNotAnimatedTimes, equalTo(@1));

   [pageViewController setViewControllers:@[controller2]
                                direction:UIPageViewControllerNavigationDirectionForward
                                 animated:YES completion:nil];


   assertThatUnsignedInteger(controller1.willMoveToNilParentViewControllerTimes, equalTo(@1));

   assertThatUnsignedInteger(controller2.willMoveToNonNilParentViewControllerTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.didMoveToNonNilParentViewControllerTimes, equalTo(@1));

   // controller1 will disappear
   assertEventuallyWithBlock (^BOOL {
      return controller1.beginAppearanceTransitionTimes == 2;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.beginAppearanceTransitionDisappearingTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.viewWillDisappearTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.viewWillDisappearAnimatedTimes == 1;
   });

   // controller1 did disappear
   assertEventuallyWithBlock (^BOOL {
      return controller1.endAppearanceTransitionTimes >= 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.viewDidDisappearTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.viewDidDisappearAnimatedTimes == 1;
   });

   assertEventuallyWithBlock (^BOOL {
      return controller1.didMoveToNilParentViewControllerTimes == 1;
   });

   // controller2 will appear
   assertEventuallyWithBlock (^BOOL {
      return controller2.beginAppearanceTransitionTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.beginAppearanceTransitionAppearingTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.viewWillAppearTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.viewWillAppearAnimatedTimes == 1;
   });

   // controller2 did appaear
   assertEventuallyWithBlock (^BOOL {
      return controller2.endAppearanceTransitionTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.viewDidAppearTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.viewDidAppearAnimatedTimes == 1;
   });
}

- (void)testLifecycleOnSetViewController
{
   IDDynamicPageViewController           * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDLifecycleVerificationViewController * controller1        = [IDLifecycleVerificationViewController new];
   IDLifecycleVerificationViewController * controller2        = [IDLifecycleVerificationViewController new];

   [pageViewController setViewController:controller1
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:NO completion:nil];

   assertThatUnsignedInteger(controller1.willMoveToNonNilParentViewControllerTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.didMoveToNonNilParentViewControllerTimes, equalTo(@1));

   // controller1 will appear
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionAppearingTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillAppearNotAnimatedTimes, equalTo(@1));

   // controller1 did appear
   assertThatUnsignedInteger(controller1.endAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidAppearNotAnimatedTimes, equalTo(@1));

   [pageViewController setViewController:controller2
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:NO completion:nil];

   // controller1 will disappear
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionTimes, equalTo(@2));
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionDisappearingTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillDisappearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillDisappearNotAnimatedTimes, equalTo(@1));

   // controller1 did disappear
   assertThatUnsignedInteger(controller1.endAppearanceTransitionTimes, equalTo(@2));
   assertThatUnsignedInteger(controller1.viewDidDisappearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidDisappearNotAnimatedTimes, equalTo(@1));

   assertThatUnsignedInteger(controller1.willMoveToNilParentViewControllerTimes, greaterThanOrEqualTo(@1));
   assertThatUnsignedInteger(controller1.didMoveToNilParentViewControllerTimes, equalTo(@1));


   assertThatUnsignedInteger(controller2.willMoveToNonNilParentViewControllerTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.didMoveToNonNilParentViewControllerTimes, equalTo(@1));

   // controller2 will appear
   assertThatUnsignedInteger(controller2.beginAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.beginAppearanceTransitionAppearingTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.viewWillAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.viewWillAppearNotAnimatedTimes, equalTo(@1));

   // controller2 did appear
   assertThatUnsignedInteger(controller2.endAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.viewDidAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.viewDidAppearNotAnimatedTimes, equalTo(@1));
}


- (void)testLifecycleOnSetViewControllerAnimated
{
   IDDynamicPageViewController           * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDLifecycleVerificationViewController * controller1        = [IDLifecycleVerificationViewController new];
   IDLifecycleVerificationViewController * controller2        = [IDLifecycleVerificationViewController new];

   [pageViewController setViewController:controller1
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:YES completion:nil];

   assertThatUnsignedInteger(controller1.willMoveToNonNilParentViewControllerTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.didMoveToNonNilParentViewControllerTimes, equalTo(@1));

   // controller1 will appear
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.beginAppearanceTransitionAppearingTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewWillAppearNotAnimatedTimes, equalTo(@1));

   // controller1 did appear
   assertThatUnsignedInteger(controller1.endAppearanceTransitionTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidAppearTimes, equalTo(@1));
   assertThatUnsignedInteger(controller1.viewDidAppearNotAnimatedTimes, equalTo(@1));

   [pageViewController setViewController:controller2
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:YES completion:nil];

   assertThatUnsignedInteger(controller1.willMoveToNilParentViewControllerTimes, equalTo(@1));

   assertThatUnsignedInteger(controller2.willMoveToNonNilParentViewControllerTimes, equalTo(@1));
   assertThatUnsignedInteger(controller2.didMoveToNonNilParentViewControllerTimes, equalTo(@1));

   // controller1 will disappear
   assertEventuallyWithBlock (^BOOL {
      return controller1.beginAppearanceTransitionTimes == 2;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.beginAppearanceTransitionDisappearingTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.viewWillDisappearTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.viewWillDisappearAnimatedTimes == 1;
   });

   // controller1 did disappear
   assertEventuallyWithBlock (^BOOL {
      return controller1.endAppearanceTransitionTimes >= 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.viewDidDisappearTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller1.viewDidDisappearAnimatedTimes == 1;
   });

   assertEventuallyWithBlock (^BOOL {
      return controller1.didMoveToNilParentViewControllerTimes == 1;
   });

   // controller2 will appear
   assertEventuallyWithBlock (^BOOL {
      return controller2.beginAppearanceTransitionTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.beginAppearanceTransitionAppearingTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.viewWillAppearTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.viewWillAppearAnimatedTimes == 1;
   });

   // controller2 did appaear
   assertEventuallyWithBlock (^BOOL {
      return controller2.endAppearanceTransitionTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.viewDidAppearTimes == 1;
   });
   assertEventuallyWithBlock (^BOOL {
      return controller2.viewDidAppearAnimatedTimes == 1;
   });
}

#pragma mark - Generating view controllers

- (void)testDequeueReusableViewController
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   NSString                    * reuseIdentifier1   = @"A";
   NSString                    * reuseIdentifier2   = @"B";
   Class class1  = [UIViewController class];
   Class class2  = [UINavigationController class];
   id    object1 = @1;
   id    object2 = @2;

   [pageViewController registerClass:class1 forViewControllerWithReuseIdentifier:reuseIdentifier1];
   [pageViewController registerClass:class2 forViewControllerWithReuseIdentifier:reuseIdentifier2];

   id controller1 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier1 forObject:object1 atIndex:0];
   id controller2 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier2 forObject:object2 atIndex:1];

   assertThatBool([controller1 isMemberOfClass:class1], equalTo(@YES));
   assertThatBool([controller2 isMemberOfClass:class2], equalTo(@YES));
}

- (void)testViewControllerReuse
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   NSString                    * reuseIdentifier    = @"A";
   id object1 = @1;
   id object2 = @2;
   id object3 = @3;
   id object4 = @4;
   id object5 = @5;

   [pageViewController registerClass:[IDLifecycleVerificationViewController class] forViewControllerWithReuseIdentifier:reuseIdentifier];

   id controller1 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object1 atIndex:0];
   [pageViewController setViewController:controller1 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   id controller2 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object2 atIndex:1];
   [pageViewController setViewController:controller2 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   assertThat(controller1, isNot(equalTo(controller2)));

   id controller3 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object3 atIndex:2];
   [pageViewController setViewController:controller3 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   assertThat(controller1, isNot(equalTo(controller3)));
   assertThat(controller2, isNot(equalTo(controller3)));

   id controller4 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object4 atIndex:3];
   [pageViewController setViewController:controller4 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   // controller1 should have been reused
   assertThat(controller1, equalTo(controller4));
   assertThat(controller2, isNot(equalTo(controller4)));
   assertThat(controller3, isNot(equalTo(controller4)));

   id controller5 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object5 atIndex:4];
   [pageViewController setViewController:controller5 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   // controller2 should have been reused
   assertThat(controller2, equalTo(controller5));
   assertThat(controller1, isNot(equalTo(controller5)));
   assertThat(controller3, isNot(equalTo(controller5)));
   assertThat(controller4, isNot(equalTo(controller5)));
}

- (void)testViewControllerReuseWithRespectToReuseIdentifier
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   NSString                    * reuseIdentifier1   = @"A";
   NSString                    * reuseIdentifier2   = @"B";
   id object1 = @1;
   id object2 = @2;
   id object3 = @3;
   id object4 = @4;
   id object5 = @5;

   [pageViewController registerClass:[UIViewController class] forViewControllerWithReuseIdentifier:reuseIdentifier1];
   [pageViewController registerClass:[UINavigationController class] forViewControllerWithReuseIdentifier:reuseIdentifier2];

   id controller1 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier1 forObject:object1 atIndex:0];
   [pageViewController setViewController:controller1 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   id controller2 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier1 forObject:object2 atIndex:1];
   [pageViewController setViewController:controller2 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   assertThat(controller1, isNot(equalTo(controller2)));

   id controller3 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier1 forObject:object3 atIndex:2];
   [pageViewController setViewController:controller3 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   assertThat(controller1, isNot(equalTo(controller3)));
   assertThat(controller2, isNot(equalTo(controller3)));

   // NOTE: reuseIdentifier2
   id controller4 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier2 forObject:object4 atIndex:3];
   [pageViewController setViewController:controller4 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   // nothing to reuse
   assertThat(controller1, isNot(equalTo(controller4)));
   assertThat(controller2, isNot(equalTo(controller4)));
   assertThat(controller3, isNot(equalTo(controller4)));

   id controller5 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier1 forObject:object5 atIndex:4];
   [pageViewController setViewController:controller5 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   // controller1 should have been reused
   assertThat(controller1, equalTo(controller5));
   assertThat(controller2, isNot(equalTo(controller5)));
   assertThat(controller3, isNot(equalTo(controller5)));
   assertThat(controller4, isNot(equalTo(controller5)));
}

- (void)testViewControllerReuseWithObjectPreference
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   NSString                    * reuseIdentifier    = @"A";
   id object1 = @1;
   id object2 = @2;
   id object3 = object1;
   id object4 = object1;
   id object5 = @5;

   [pageViewController registerClass:[UIViewController class] forViewControllerWithReuseIdentifier:reuseIdentifier];

   id controller1 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object1 atIndex:0];
   [pageViewController setViewController:controller1 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   id controller2 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object2 atIndex:1];
   [pageViewController setViewController:controller2 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   assertThat(controller1, isNot(equalTo(controller2)));

   id controller3 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object3 atIndex:2];
   [pageViewController setViewController:controller3 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   // Object preference will reuse the old controller
   assertThat(controller1, equalTo(controller3));
   assertThat(controller2, isNot(equalTo(controller3)));

   id controller4 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object4 atIndex:3];
   [pageViewController setViewController:controller4 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   // Unless that controller is already displayed
   assertThat(controller1, isNot(equalTo(controller4)));
   assertThat(controller2, isNot(equalTo(controller4)));
   assertThat(controller3, isNot(equalTo(controller4)));

   id controller5 = [pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object5 atIndex:4];
   [pageViewController setViewController:controller5 direction:IDDynamicPageViewControllerNavigationDirectionForward animated:NO completion:nil];

   // controller2 should have been reused
   assertThat(controller2, equalTo(controller5));
   assertThat(controller1, isNot(equalTo(controller5)));
   assertThat(controller3, isNot(equalTo(controller5)));
   assertThat(controller4, isNot(equalTo(controller5)));

   [pageViewController.view removeFromSuperview];
}

#pragma mark - Data Source Management

- (void)testSetDataSource
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];

   assertThat(pageViewController.activeViewController, equalTo(nil));

   pageViewController.dataSource = dataSource;

   assertThat(pageViewController.activeViewController, isNot(equalTo(nil)));

   id object = [pageViewController objectForViewController:pageViewController.activeViewController];

   assertThat(@([dataSource indexOfObject:object]), isNot(@(NSNotFound)));
}

- (void)testShowControllerInDataSource
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];

   pageViewController.dataSource = dataSource;

   UIViewController * viewController     = pageViewController.activeViewController;
   UIViewController * nextViewController = [dataSource pageViewController:pageViewController
                                             viewControllerForPageAtIndex:1];

   [pageViewController setViewController:nextViewController
                               direction:IDDynamicPageViewControllerNavigationDirectionForward
                                animated:NO completion:nil];

   assertThat(pageViewController.activeViewController, equalTo(nextViewController));
   assertThat(viewController.parentViewController, equalTo(nil));
}

- (void)testShowControllerInDataSourceByObject
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];
   id lastObject = [dataSource objectAtIndex:2];

   pageViewController.dataSource = dataSource;

   UIViewController * viewController = pageViewController.activeViewController;

   // Move to the last object
   [pageViewController setObject:lastObject animated:NO completion:nil];

   id showingObject = [pageViewController objectForViewController:pageViewController.activeViewController];

   assertThat(pageViewController.activeViewController, isNot(equalTo(viewController)));
   assertThat(viewController.parentViewController, equalTo(nil));
   assertThat(showingObject, equalTo(lastObject));
}

- (void)testRemoveNextViewController
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];

   pageViewController.dataSource = dataSource;

   UIViewController * viewController = pageViewController.activeViewController;

   [dataSource removeObjectAtIndex:1];

   assertThat(pageViewController.activeViewController, equalTo(viewController));
}

- (void)testRemovePreviousViewController
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];

   pageViewController.dataSource = dataSource;

   id object = [dataSource objectAtIndex:1];

   [pageViewController setObject:object animated:NO completion:nil];

   UIViewController * viewController = pageViewController.activeViewController;

   [dataSource removeObjectAtIndex:0];

   assertThat(pageViewController.activeViewController, equalTo(viewController));
}

- (void)testRemoveCurrentViewControllerAtFirstPage
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];

   pageViewController.dataSource = dataSource;

   UIViewController * viewController = pageViewController.activeViewController;

   [dataSource removeObjectAtIndex:0];

   assertThat(pageViewController.activeViewController, isNot(equalTo(viewController)));
   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@0));

   assertEventuallyWithBlock (^BOOL {
      return viewController.parentViewController == nil;
   });
}

- (void)testRemoveCurrentViewControllerAtLastPage
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];
   id lastObject = [dataSource objectAtIndex:2];

   pageViewController.dataSource = dataSource;

   [pageViewController setObject:lastObject animated:NO completion:nil];

   UIViewController * viewController = pageViewController.activeViewController;

   [dataSource removeObjectAtIndex:2];

   assertThat(pageViewController.activeViewController, isNot(equalTo(viewController)));
   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@1));

   // Due to the magic that makes removal work, the original controller is not
   // removed synchronously
   assertEventuallyWithBlock (^BOOL {
      return viewController.parentViewController == nil;
   });
}

- (void)testRemoveCurrentAndAllNeighboringViewControllers
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithFiveItems];
   NSUInteger index  = 3;
   id         object = [dataSource objectAtIndex:index];

   pageViewController.dataSource = dataSource;

   // Show the 4th of 5 items
   [pageViewController setObject:object animated:NO completion:nil];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@(index)));

   // The controller will be updated after every operation
   [dataSource removeObjectAtIndex:index + 1];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@(index)));

   [dataSource removeObjectAtIndex:index];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@(index - 1)));

   [dataSource removeObjectAtIndex:index - 1];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@(index - 2)));
}

// When all 3 controllers that an IDDynamicPageViewController knows about are removed,
// it shows the default controller, which is the first in the data source.
- (void)testRemoveCurrentAndAllNeighboringViewControllersBatched
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithFiveItems];
   NSUInteger index  = 3;
   id         object = [dataSource objectAtIndex:index];

   pageViewController.dataSource = dataSource;

   // Show the 4th of 5 items
   [pageViewController setObject:object animated:NO completion:nil];

   UIViewController * viewController = pageViewController.activeViewController;

   // Batch the updates, otherwise the controller will be updated after each
   [pageViewController beginUpdates];

   [dataSource removeObjectAtIndex:index + 1];
   [dataSource removeObjectAtIndex:index];
   [dataSource removeObjectAtIndex:index - 1];

   [pageViewController endUpdates];

   assertThat(pageViewController.activeViewController, isNot(equalTo(viewController)));

   // The default first object is shown when all neighbors are removed
   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@0));

   // Due to the magic that makes removal work, the original controller is not
   // removed synchronously, and it should not be reused because it was just
   // active.
   assertEventuallyWithBlock (^BOOL {
      return viewController.parentViewController == nil;
   });
}

- (void)testRemoveAllViewControllers
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];

   pageViewController.dataSource = dataSource;

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@0));

   [dataSource removeObjectAtIndex:0];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@0));

   [dataSource removeObjectAtIndex:0];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@0));

   [dataSource removeObjectAtIndex:0];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@(NSNotFound)));
   assertThat(pageViewController.activeViewController, nilValue());
}

- (void)testRemoveAllViewControllersThenAddMore
{
   IDDynamicPageViewController * pageViewController = [self newPageViewControllerInViewHierarchy];
   IDMutablePageViewDataSource * dataSource         = [self newDataSourceWithThreeItems];
   id object4 = @4;
   id object5 = @5;

   pageViewController.dataSource = dataSource;

   // Show the last object
   [pageViewController setObject:[dataSource objectAtIndex:2] animated:NO completion:nil];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@2));

   [pageViewController beginUpdates];

   [dataSource removeObjectAtIndex:0];
   [dataSource removeObjectAtIndex:0];
   [dataSource removeObjectAtIndex:0];

   [pageViewController endUpdates];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@(NSNotFound)));
   assertThat(pageViewController.activeViewController, nilValue());

   [dataSource addObject:object4];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@0));
   assertThat(pageViewController.activeViewController, isNot(nilValue()));

   [dataSource addObject:object5];

   assertThat(@(pageViewController.indexOfActiveViewController), equalTo(@0));
   assertThat(pageViewController.activeViewController, isNot(nilValue()));
}

@end

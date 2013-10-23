//
//  IDLifecycleVerificationViewController.m
//  IDDynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/18/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "IDLifecycleVerificationViewController.h"

@interface IDLifecycleVerificationViewController ()

@end

@implementation IDLifecycleVerificationViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
   NSLog(@"LIFECYCLE: %@ %@", self, NSStringFromSelector(_cmd));
   [super viewDidLoad];

   _viewDidLoadTimes++;
}

- (void)viewWillAppear:(BOOL)animated
{
   NSLog(@"LIFECYCLE: %@ %@", self, NSStringFromSelector(_cmd));
   [super viewWillAppear:animated];

   if (animated)
   {
      _viewWillAppearAnimatedTimes++;
   }
   else
   {
      _viewWillAppearNotAnimatedTimes++;
   }

   _viewWillAppearTimes++;
}

- (void)viewDidAppear:(BOOL)animated
{
   NSLog(@"LIFECYCLE: %@ %@", self, NSStringFromSelector(_cmd));
   [super viewDidAppear:animated];

   if (animated)
   {
      _viewDidAppearAnimatedTimes++;
   }
   else
   {
      _viewDidAppearNotAnimatedTimes++;
   }

   _viewDidAppearTimes++;
}

- (void)viewWillDisappear:(BOOL)animated
{
   NSLog(@"LIFECYCLE: %@ %@", self, NSStringFromSelector(_cmd));
   [super viewWillDisappear:animated];

   if (animated)
   {
      _viewWillDisappearAnimatedTimes++;
   }
   else
   {
      _viewWillDisappearNotAnimatedTimes++;
   }

   _viewWillDisappearTimes++;
}

- (void)viewDidDisappear:(BOOL)animated
{
   NSLog(@"LIFECYCLE: %@ %@", self, NSStringFromSelector(_cmd));
   [super viewDidDisappear:animated];

   if (animated)
   {
      _viewDidDisappearAnimatedTimes++;
   }
   else
   {
      _viewDidDisappearNotAnimatedTimes++;
   }

   _viewDidDisappearTimes++;
}

#pragma mark - Parent controllers

- (void)willMoveToParentViewController:(UIViewController *)parent
{
   NSLog(@"LIFECYCLE: %@ %@%@", self, NSStringFromSelector(_cmd), parent);
   [super willMoveToParentViewController:parent];

   if (parent)
   {
      _willMoveToNonNilParentViewControllerTimes++;
   }
   else
   {
      _willMoveToNilParentViewControllerTimes++;
   }

   _willMoveToParentViewControllerTimes++;
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
   NSLog(@"LIFECYCLE: %@ %@%@", self, NSStringFromSelector(_cmd), parent);
   [super didMoveToParentViewController:parent];

   if (parent)
   {
      _didMoveToNonNilParentViewControllerTimes++;
   }
   else
   {
      _didMoveToNilParentViewControllerTimes++;
   }

   _didMoveToParentViewControllerTimes++;
}

#pragma mark - Transitions

- (void)beginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated
{
   NSLog(@"LIFECYCLE: %@ %@ %d", self, NSStringFromSelector(_cmd), isAppearing);
   [super beginAppearanceTransition:isAppearing animated:animated];

   if (isAppearing)
   {
      _beginAppearanceTransitionAppearingTimes++;
   }
   else
   {
      _beginAppearanceTransitionDisappearingTimes++;
   }

   _beginAppearanceTransitionTimes++;
}

- (void)endAppearanceTransition
{
   NSLog(@"LIFECYCLE: %@ %@", self, NSStringFromSelector(_cmd));
   [super endAppearanceTransition];

   _endAppearanceTransitionTimes++;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
   NSLog(@"LIFECYCLE: %@ %@", self, NSStringFromSelector(_cmd));
   [super viewDidLayoutSubviews];

   _viewDidLayoutSubviewsTimes++;
}

- (void)viewWillLayoutSubviews
{
   NSLog(@"LIFECYCLE: %@ %@", self, NSStringFromSelector(_cmd));
   [super viewWillLayoutSubviews];
   
   _viewWillLayoutSubviewsTimes++;
}

@end

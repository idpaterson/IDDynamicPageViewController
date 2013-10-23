//
//  IDLifecycleVerificationViewController.h
//  IDDynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/18/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IDLifecycleVerificationViewController : UIViewController

@property (nonatomic, assign, readonly) NSUInteger viewDidLoadTimes;

@property (nonatomic, assign, readonly) NSUInteger viewWillAppearTimes;
@property (nonatomic, assign, readonly) NSUInteger viewWillAppearAnimatedTimes;
@property (nonatomic, assign, readonly) NSUInteger viewWillAppearNotAnimatedTimes;

@property (nonatomic, assign, readonly) NSUInteger viewDidAppearTimes;
@property (nonatomic, assign, readonly) NSUInteger viewDidAppearAnimatedTimes;
@property (nonatomic, assign, readonly) NSUInteger viewDidAppearNotAnimatedTimes;

@property (nonatomic, assign, readonly) NSUInteger viewWillDisappearTimes;
@property (nonatomic, assign, readonly) NSUInteger viewWillDisappearAnimatedTimes;
@property (nonatomic, assign, readonly) NSUInteger viewWillDisappearNotAnimatedTimes;

@property (nonatomic, assign, readonly) NSUInteger viewDidDisappearTimes;
@property (nonatomic, assign, readonly) NSUInteger viewDidDisappearAnimatedTimes;
@property (nonatomic, assign, readonly) NSUInteger viewDidDisappearNotAnimatedTimes;

@property (nonatomic, assign, readonly) NSUInteger viewDidLayoutSubviewsTimes;
@property (nonatomic, assign, readonly) NSUInteger viewWillLayoutSubviewsTimes;

@property (nonatomic, assign, readonly) NSUInteger willMoveToParentViewControllerTimes;
@property (nonatomic, assign, readonly) NSUInteger willMoveToNilParentViewControllerTimes;
@property (nonatomic, assign, readonly) NSUInteger willMoveToNonNilParentViewControllerTimes;

@property (nonatomic, assign, readonly) NSUInteger didMoveToParentViewControllerTimes;
@property (nonatomic, assign, readonly) NSUInteger didMoveToNilParentViewControllerTimes;
@property (nonatomic, assign, readonly) NSUInteger didMoveToNonNilParentViewControllerTimes;

@property (nonatomic, assign, readonly) NSUInteger beginAppearanceTransitionTimes;
@property (nonatomic, assign, readonly) NSUInteger beginAppearanceTransitionAppearingTimes;
@property (nonatomic, assign, readonly) NSUInteger beginAppearanceTransitionDisappearingTimes;

@property (nonatomic, assign, readonly) NSUInteger endAppearanceTransitionTimes;

@end

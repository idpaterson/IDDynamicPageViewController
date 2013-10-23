//
//  IDAppDelegate.m
//  IDDynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/17/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "IDAppDelegate.h"

#import "IDDynamicPageViewController.h"
#import "IDLifecycleVerificationViewController.h"
#import "IDMutablePageViewDataSource.h"

@implementation IDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   IDDynamicPageViewController * pageViewController = [[IDDynamicPageViewController alloc] initWithNavigationOrientation:IDDynamicPageViewControllerNavigationOrientationHorizontal interPageSpacing:5.0f];

   _dataSource = [IDMutablePageViewDataSource new];

   self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

   _window.rootViewController = pageViewController;

   [self.window makeKeyAndVisible];

   _dataSource.reuseIdentifier = @"Page";
   [pageViewController registerClass:[UIViewController class]
forViewControllerWithReuseIdentifier:@"Page"];

   [_dataSource addObject:[UIColor redColor]];
   [_dataSource addObject:[UIColor greenColor]];
   [_dataSource addObject:[UIColor blueColor]];

   _dataSource.configureViewControllerBlock = ^(UIViewController * viewController, UIColor * color, IDDynamicPageViewController * pageViewController, NSUInteger index)
   {
      viewController.view.backgroundColor = color;
   };

   pageViewController.dataSource = _dataSource;

   return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
   // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
   // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
   // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
   // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
   // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

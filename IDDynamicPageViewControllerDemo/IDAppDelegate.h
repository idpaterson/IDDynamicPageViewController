//
//  IDAppDelegate.h
//  IDDynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/17/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#include <Foundation/Foundation.h>

@class IDMutablePageViewDataSource;

@interface IDAppDelegate : UIResponder
<UIApplicationDelegate>

@property (strong, nonatomic) UIWindow * window;

@property (nonatomic, strong, readonly) IDMutablePageViewDataSource * dataSource;

@end

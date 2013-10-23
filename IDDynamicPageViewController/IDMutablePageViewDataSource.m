//
//  IDMutablePageViewDataSource.m
//  IDDynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/19/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "IDMutablePageViewDataSource.h"

@implementation IDMutablePageViewDataSource

- (id)init
{
   self = [super init];

   if (self)
   {
      _objects = [NSMutableArray new];
   }

   return self;
}

#pragma mark - Data Access

- (NSArray *)objects
{
   @synchronized(_objects)
   {
      // Return a read-only copy
      return [NSArray arrayWithArray:_objects];
   }
}

- (NSUInteger)indexOfObject:(id)object
{
   @synchronized(_objects)
   {
      return [_objects indexOfObject:object];
   }
}

- (id)objectAtIndex:(NSUInteger)index
{
   @synchronized(_objects)
   {
      if (index >= _objects.count)
      {
         return nil;
      }

      return [_objects objectAtIndex:index];
   }
}

#pragma mark - Data Manipulation

- (void)addObject:(id)anObject
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects addObject:anObject];
   }

   [_pageViewController endUpdates];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects insertObject:anObject atIndex:index];
   }

   [_pageViewController endUpdates];
}

- (void)removeLastObject
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeLastObject];
   }

   [_pageViewController endUpdates];
}

- (void)removeObject:(id)object
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeObject:object];
   }

   [_pageViewController endUpdates];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeObjectAtIndex:index];
   }

   [_pageViewController endUpdates];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects replaceObjectAtIndex:index withObject:anObject];
   }

   [_pageViewController endUpdates];
}

- (void)didCompleteUpdate
{
   [_pageViewController reloadData];
}

#pragma mark - View Controller Management

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index
{
   @synchronized(_objects)
   {
      if (index == NSNotFound || index >= _objects.count)
      {
         return nil;
      }

      NSString * reuseIdentifier = _reuseIdentifier;
      id         object          = _objects[index];

      if (!reuseIdentifier && _reuseIdentifierBlock)
      {
         reuseIdentifier = _reuseIdentifierBlock(object, _pageViewController, index);
      }

      UIViewController * controller = [_pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier forObject:object];

      if (_configureViewControllerBlock)
      {
         _configureViewControllerBlock(controller, object, _pageViewController, index);
      }

      return controller;
   }
}

- (UIViewController *)viewControllerByOffset:(NSInteger)offset fromViewController:(UIViewController *)viewController
{
   @synchronized(_objects)
   {
      id         object      = [_pageViewController objectForViewController:viewController];
      NSUInteger index       = [_objects indexOfObject:object];
      NSInteger  targetIndex = NSNotFound;

      // The view controller exists
      if (index != NSNotFound)
      {
         targetIndex = index + offset;
      }

      // The view controller is not associated with this data source
      if (targetIndex == NSNotFound)
      {
         return nil;
      }
      // The target is beyond the bounds of the data source
      else if (targetIndex >= _objects.count || targetIndex < 0)
      {
         return nil;
      }
      // Index is valid, return a controller for that index
      else
      {
         return [self viewControllerAtIndex:targetIndex];
      }
   }
}

#pragma mark - UIPageViewControllerDataSource implementation

- (UIViewController *)pageViewController:(IDDynamicPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
   if (pageViewController)
   {
      _pageViewController = pageViewController;
   }

   return [self viewControllerByOffset:1 fromViewController:viewController];
}

- (UIViewController *)pageViewController:(IDDynamicPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
   if (pageViewController)
   {
      _pageViewController = pageViewController;
   }

   return [self viewControllerByOffset:-1 fromViewController:viewController];
}

- (UIViewController *)pageViewController:(IDDynamicPageViewController *)pageViewController viewControllerForObject:(id)object
{
   if (pageViewController)
   {
      _pageViewController = pageViewController;
   }

   NSUInteger index = NSNotFound;

   @synchronized(_objects)
   {
      index = [_objects indexOfObject:object];
   }

   return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(IDDynamicPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)index
{
   if (pageViewController)
   {
      _pageViewController = pageViewController;
   }

   return [self viewControllerAtIndex:index];
}

- (NSUInteger)pageViewController:(IDDynamicPageViewController *)pageViewController indexOfObject:(id)object
{
   if (pageViewController)
   {
      _pageViewController = pageViewController;
   }

   return [self indexOfObject:object];
}

- (NSInteger)numberOfPagesInPageViewController:(IDDynamicPageViewController *)pageViewController
{
   return _objects.count;
}

@end

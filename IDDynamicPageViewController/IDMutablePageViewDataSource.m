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

- (NSUInteger)numberOfObjects
{
   @synchronized(_objects)
   {
      return _objects.count;
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

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block
{
   if (!block)
   {
      return;
   }

   @synchronized(_objects)
   {
      [_objects enumerateObjectsUsingBlock:block];
   }
}

#pragma mark - Data Manipulation

#pragma mark Adding Objects

- (void)addObject:(id)object
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects addObject:object];
   }

   [_pageViewController endUpdates];
}

- (void)addObjectsFromArray:(NSArray *)array
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects addObjectsFromArray:array];
   }

   [_pageViewController endUpdates];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects insertObject:object atIndex:index];
   }

   [_pageViewController endUpdates];
}

- (void)insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects insertObjects:objects atIndexes:indexes];
   }

   [_pageViewController endUpdates];
}


#pragma mark Removing Objects

- (void)removeLastObject
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeLastObject];
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

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeObjectsAtIndexes:indexes];
   }

   [_pageViewController endUpdates];
}

- (void)removeAllObjects
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeAllObjects];
   }

   [_pageViewController endUpdates];
}

- (void)removeObject:(id)object inRange:(NSRange)range
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeObject:object inRange:range];
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

- (void)removeObjectIdenticalTo:(id)object inRange:(NSRange)range
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeObjectIdenticalTo:object inRange:range];
   }

   [_pageViewController endUpdates];
}

- (void)removeObjectIdenticalTo:(id)object
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeObjectIdenticalTo:object];
   }

   [_pageViewController endUpdates];
}

- (void)removeObjectsInArray:(NSArray *)array
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeObjectsInArray:array];
   }

   [_pageViewController endUpdates];
}

- (void)removeObjectsInRange:(NSRange)range
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects removeObjectsInRange:range];
   }

   [_pageViewController endUpdates];
}


#pragma mark Replacing Objects

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects replaceObjectAtIndex:index withObject:object];
   }

   [_pageViewController endUpdates];
}

- (void)replaceObjectsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects replaceObjectsAtIndexes:indexes withObjects:objects];
   }

   [_pageViewController endUpdates];
}

- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)array range:(NSRange)otherRange
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects replaceObjectsInRange:range withObjectsFromArray:array range:otherRange];
   }

   [_pageViewController endUpdates];
}

- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)array
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects replaceObjectsInRange:range withObjectsFromArray:array];
   }

   [_pageViewController endUpdates];
}


#pragma mark Filtering Content

- (void)filterUsingPredicate:(NSPredicate *)predicate
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects filterUsingPredicate:predicate];
   }

   [_pageViewController endUpdates];
}


#pragma mark Rearranging Content

- (void)exchangeObjectAtIndex:(NSUInteger)index1 withObjectAtIndex:(NSUInteger)index2
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
   }

   [_pageViewController endUpdates];
}

- (void)sortUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects sortUsingFunction:compare context:context];
   }

   [_pageViewController endUpdates];
}

- (void)sortUsingSelector:(SEL)comparator
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects sortUsingSelector:comparator];
   }

   [_pageViewController endUpdates];
}

#if NS_BLOCKS_AVAILABLE
- (void)sortUsingComparator:(NSComparator)comparator
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects sortUsingComparator:comparator];
   }

   [_pageViewController endUpdates];
}

- (void)sortWithOptions:(NSSortOptions)options usingComparator:(NSComparator)comparator
{
   [_pageViewController beginUpdates];

   @synchronized(_objects)
   {
      [_objects sortWithOptions:options usingComparator:comparator];
   }

   [_pageViewController endUpdates];
}
#endif

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

      UIViewController * controller = [_pageViewController dequeueReusableViewControllerWithReuseIdentifier:reuseIdentifier
                                                                                                  forObject:object
                                                                                                    atIndex:index];

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

#pragma mark - IDDynamicPageViewControllerDataSource implementation

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

- (id)pageViewController:(IDDynamicPageViewController *)pageViewController objectAtIndex:(NSUInteger)index
{
   if (pageViewController)
   {
      _pageViewController = pageViewController;
   }

   return [self objectAtIndex:index];
}

- (NSInteger)numberOfPagesInPageViewController:(IDDynamicPageViewController *)pageViewController
{
   return _objects.count;
}

@end

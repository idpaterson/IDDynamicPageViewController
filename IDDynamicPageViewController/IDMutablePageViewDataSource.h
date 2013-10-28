//
//  IDMutablePageViewDataSource.h
//  IDDynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/19/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IDDynamicPageViewController.h"

/// Given a view controller, configure it to represent the appropriate content
/// for the specified object.
///
/// Note that the view controller may have just been created for the purpose
/// of displaying this object, it could already be displaying the object, or it
/// could be in a reuse state after representing a different object. All of
/// these cases must be handled if the <reuseIdentifier> allows them to occur.
///
/// @param viewController     The view controller to configure
/// @param object             The object to be represented by the controller
/// @param pageViewController The page view controller into which it will be added
/// @param index              The index among other controllers
typedef void (^ IDPageViewDataSourceConfigureViewControllerBlock)(UIViewController * viewController, id object, IDDynamicPageViewController * pageViewController, NSUInteger index);

/// Provides a dynamic reuse identifier based on the object and desired reuse
/// pattern for the page view controller.
///
/// The reuse identifiers returned by this block must be registered with the
/// page view controller. Otherwise, the corresponding controllers cannot be
/// initialized.
///
/// @param object             The object to be represented by the controller
/// @param pageViewController The page view controller into which it will be added
/// @param index              The index among other controllers
///
/// @return A string corresponding to a reuse identifier registered with the
/// page view controller.
typedef NSString * (^ IDPageViewDataSourceReuseIdentifierBlock)(id object, IDDynamicPageViewController * pageViewController, NSUInteger index);

typedef void (^ IDPageViewDataSourceObjectEnumerationBlock)(id object, NSUInteger * index, BOOL * stop);

@interface IDMutablePageViewDataSource : NSObject
<IDDynamicPageViewControllerDataSource>
{
@private
   NSUInteger       _updateLevel;
   NSMutableArray * _objects;

   __weak IDDynamicPageViewController * _pageViewController;
}

#pragma mark - Configuring Controllers
/// @name      Configuring Controllers

/// The reuse identifier to use for all view controllers.
///
/// If set to a value other than `nil`, this will override the behavior of
/// <reuseIdentifierBlock>. Using this property implies that all controllers
/// will use the same reuse identifier, which requires the controllers to be
/// capable of recycling for representation of different objects.
///
/// @see reuseIdentifierBlock
@property (nonatomic, copy) NSString * reuseIdentifier;

/// Provides dynamic reuse identifiers based on the specific object in each
/// controller.
///
/// Implement a reuse identifier block that returns a different value for each
/// distinct controller to ensure that controllers are not reused.
@property (nonatomic, copy) IDPageViewDataSourceReuseIdentifierBlock reuseIdentifierBlock;

/// Allows configuration of a view controller prior to presentation in the
/// <IDPageViewController>.
///
/// The controller may be newly instantiated, already representing the object,
/// or representing a different object. For more information on reuse of view
/// controllers, see <-[IDPageViewController
/// dequeueReusableViewControllerWithReuseIdentifier:forIndex:>
@property (nonatomic, copy) IDPageViewDataSourceConfigureViewControllerBlock configureViewControllerBlock;

#pragma mark - Data Access
/// @name      Data Access

/// All of the objects currently represented in this data source.
@property (nonatomic, readonly) NSArray * objects;

/// Finds the index of the specified object in the data source.
///
/// @param object The object to search for
///
/// @return The index or `NSNotFound` if the object is not in the data source
- (NSUInteger)indexOfObject:(id)object;

/// Finds the object at the specified index in the data source.
///
/// @param index An index within the range of <objects>.
///
/// @return The object or `nil` if the index is outside the range of <objects>
- (id)objectAtIndex:(NSUInteger)index;

/// Returns the number of objects in the data source.
///
/// @return The number of objects in the data source.
- (NSUInteger)numberOfObjects;

- (void)enumerateObjectsUsingBlock:(void (^)(id object, NSUInteger index, BOOL * stop))block;

#pragma mark - Adding Objects
/// @name      Adding Objects

- (void)addObject:(id)object;
- (void)addObjectsFromArray:(NSArray *)array;
- (void)insertObject:(id)object atIndex:(NSUInteger)index;
- (void)insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;

#pragma mark - Removing Objects
/// @name      Removing Objects

- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)removeAllObjects;
- (void)removeObject:(id)object inRange:(NSRange)range;
- (void)removeObject:(id)object;
- (void)removeObjectIdenticalTo:(id)object inRange:(NSRange)range;
- (void)removeObjectIdenticalTo:(id)object;
- (void)removeObjectsInArray:(NSArray *)array;
- (void)removeObjectsInRange:(NSRange)range;

#pragma mark - Replacing Objects
/// @name      Replacing Objects

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object;
- (void)replaceObjectsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects;
- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)array range:(NSRange)otherRange;
- (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)array;

#pragma mark - Filtering Content
/// @name      Filtering Content

- (void)filterUsingPredicate:(NSPredicate *)predicate;

#pragma mark - Rearranging Content
/// @name      Rearranging Content

- (void)exchangeObjectAtIndex:(NSUInteger)index1 withObjectAtIndex:(NSUInteger)index2;
- (void)sortUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context;
- (void)sortUsingSelector:(SEL)comparator;
#if NS_BLOCKS_AVAILABLE
- (void)sortUsingComparator:(NSComparator)comparator;
- (void)sortWithOptions:(NSSortOptions)options usingComparator:(NSComparator)comparator;
#endif

@end
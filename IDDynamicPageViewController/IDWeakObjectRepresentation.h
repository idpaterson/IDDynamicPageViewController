//
//  IDWeakObjectRepresentation.h
//  IDDynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/19/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import <Foundation/Foundation.h>

///
/// A container model that simply holds a weak reference to any object.
///
/// An `IDWeakObjectRepresentation` is also useful for representing an object
/// that does not conform to `NSCopying` in a collection.
///

@interface IDWeakObjectRepresentation : NSObject
<NSCopying>

/// An object to which the instance holds a weak reference. If the target object
/// is deallocated, `object` will become `nil`.
@property (nonatomic, weak) id object;

/// Creates an `IDWeakObjectRepresentation` with the specified object
+ (instancetype)weakRepresentationOfObject:(id)object;

/// Creates an `IDWeakObjectRepresentation` with the specified object
- (instancetype)initWithObject:(id)object;

/// Compares `IDWeakObjectRepresentation` instances to determine whether they
/// represent the same object.
///
/// This is equivalent to `[wor1.object isEqual:wor2.object]`.
///
/// @param object The object to compare.
///
/// @return `YES` if the object is an `IDWeakObjectRepresentation` of the same
/// object according to the object's `isEqual:`.
- (BOOL)isEqual:(id)object;

/// Compares `IDWeakObjectRepresentation` instances to determine whether they
/// represent the same pointer.
///
/// This is equivalent to `wor1.object == wor2.object`.
///
/// @param object The object to compare.
///
/// @return `YES` if the object is an `IDWeakObjectRepresentation` of the same
/// pointer.
- (BOOL)isIdenticalTo:(id)object;

@end
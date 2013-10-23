//
//  IDWeakObjectRepresentation.m
//  IDDynamicPageViewControllerDemo
//
//  Created by Ian Paterson on 10/19/13.
//  Copyright (c) 2013 Ian Paterson. All rights reserved.
//

#import "IDWeakObjectRepresentation.h"

@implementation IDWeakObjectRepresentation

+ (instancetype)weakRepresentationOfObject:(id)object
{
   return [[IDWeakObjectRepresentation alloc] initWithObject:object];
}

- (instancetype)initWithObject:(id)object
{
   if ((self = [super init]))
   {
      _object = object;
   }
   return self;
}

- (BOOL)isEqual:(id)object
{
   if (![object isKindOfClass:[IDWeakObjectRepresentation class]])
   {
      return NO;
   }
   IDWeakObjectRepresentation * other = object;
   return [other.object isEqual:_object];
}

- (BOOL)isIdenticalTo:(id)object
{
   if (![object isKindOfClass:[IDWeakObjectRepresentation class]])
   {
      return NO;
   }
   IDWeakObjectRepresentation * other = object;
   return other.object == _object;
}

- (NSUInteger)hash
{
   return [_object hash];
}

#pragma mark - NSCopying implementation

- (id)copyWithZone:(NSZone *)zone
{
   return [[[self class] allocWithZone:zone] initWithObject:_object];
}

@end

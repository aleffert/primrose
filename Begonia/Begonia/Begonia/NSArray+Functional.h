//
//  NSArray+Functional.h
//  Collage
//
//  Created by Scott Ostler on 7/9/11.
//  Copyright 2011 Lascaux. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^MapBlock)(id);
typedef BOOL (^FilterBlock)(id);
typedef id (^FoldLeftBlock)(id object, NSUInteger index, id accumulator);

@interface NSArray (Functional)

- (NSArray *)map:(MapBlock)f;
- (NSArray *)filter:(FilterBlock)f;

- (NSArray *)tail;

- (id)foldLeft:(FoldLeftBlock)f base:(id)base;

@end

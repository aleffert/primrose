//
//  NSArray+Functional.m
//  Collage
//
//  Created by Scott Ostler on 7/9/11.
//  Copyright 2011 Lascaux. All rights reserved.
//

#import "NSArray+Functional.h"


@implementation NSArray (Functional)

- (NSArray *)map:(MapBlock)f
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[self count]];
    for (id o in self) {
        [ret addObject:f(o)];
    }
    return ret;
}

- (NSArray*)filter:(FilterBlock)f {
    NSMutableArray* result = [NSMutableArray array];
    for(id obj in self) {
        if(f(obj)) {
            [result addObject:obj];
        }
    }
    return result;
}

- (NSArray *)tail
{
    NSRange range = NSMakeRange(1, [self count] - 1);
    return [self subarrayWithRange:range];
}

- (id)foldLeft:(FoldLeftBlock)f base:(id)base {
    __block id acc = base;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL* stop) {
        acc = f(obj, index, acc);
    }];
    return acc;
}

@end

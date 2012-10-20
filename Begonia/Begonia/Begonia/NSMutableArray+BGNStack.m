//
//  NSMutableArray+BGNStack.m
//  Begonia
//
//  Created by Akiva Leffert on 10/20/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "NSMutableArray+BGNStack.h"

@implementation NSMutableArray (BGNStack)

- (id)peek {
    return [self lastObject];
}

- (void)push:(id)object {
    [self addObject:object];
}

- (id)pop {
    id object = [self lastObject];
    [self removeLastObject];
    return object;
}

@end

//
//  NSObject+BGNConstruction.m
//  Begonia
//
//  Created by Akiva Leffert on 10/20/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "NSObject+BGNConstruction.h"

@implementation NSObject (BGNConstruction)
+ (id)makeThen:(void (^)(id o))f {
    id result = [[self alloc] init];
    f(result);
    return result;
}
@end

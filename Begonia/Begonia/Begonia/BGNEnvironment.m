//
//  BGNEnvironment.m
//  Begonia
//
//  Created by Akiva Leffert on 11/10/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNEnvironment.h"
#import "NSObject+BGNConstruction.h"

@interface BGNEnvironment ()

@property (copy, nonatomic) NSDictionary* map;

@end

@implementation BGNEnvironment

+ (BGNEnvironment*)empty {
    return [BGNEnvironment makeThen:^(BGNEnvironment* env) {
        env.map = [NSDictionary dictionary];
    }];
}

- (BGNEnvironment*)pushName:(NSString*)name withValue:(id <BGNValue>)value {
    NSMutableDictionary* updatedMap = self.map.mutableCopy;
    [updatedMap setObject:value forKey:name];
    
    return [BGNEnvironment makeThen:^(BGNEnvironment* env) {
        env.map = updatedMap;
    }];
}

@end

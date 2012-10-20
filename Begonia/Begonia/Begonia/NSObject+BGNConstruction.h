//
//  NSObject+BGNConstruction.h
//  Begonia
//
//  Created by Akiva Leffert on 10/20/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (BGNConstruction)

+ (id)makeThen:(void (^)(id o))f;

@end

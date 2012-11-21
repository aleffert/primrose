//
//  BGNPrimops.h
//  Begonia
//
//  Created by Akiva Leffert on 11/18/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNInterpreter;
@protocol BGNValue;

@interface BGNPrimops : NSObject

+ (id <BGNValue>)evaluatePrimop:(NSString*)name args:(NSArray*)args inInterpreter:(BGNInterpreter*)interpreter;

@end

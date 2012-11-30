//
//  BGNInterpreter.h
//  Begonia
//
//  Created by Akiva Leffert on 9/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BGNModuleManager.h"

typedef void (^StringBlock)(NSString* error);

@interface BGNInterpreter : NSObject <BGNModuleManagerDelegate>

@property (retain, nonatomic) CALayer* display;
@property (copy, nonatomic) StringBlock errorHandler;

- (void)exportModuleNamed:(NSString*)name bindings:(NSDictionary*)bindings;
- (void)interpretFile:(NSString*)path;
- (id)objectNamed:(NSString*)name;

@end

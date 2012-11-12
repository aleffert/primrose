//
//  BGNEnvironment.h
//  Begonia
//
//  Created by Akiva Leffert on 11/10/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BGNValue;

@interface BGNEnvironment : NSObject <NSCopying>

+ (BGNEnvironment*)empty;

- (BGNEnvironment*)bindExpVar:(NSString*)name withValue:(id <BGNValue>)value;
- (id <BGNValue>)valueNamed:(NSString*)name inModule:(NSString*)moduleName;

- (BGNEnvironment*)scopeModuleNamed:(NSString*)name inBody:(BGNEnvironment* (^)(BGNEnvironment* env))body;

- (BGNEnvironment*)importModuleNamed:(NSString*)moduleName;
- (BGNEnvironment*)openModule:(NSString*)moduleName;

@end

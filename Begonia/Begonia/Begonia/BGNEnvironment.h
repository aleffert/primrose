//
//  BGNEnvironment.h
//  Begonia
//
//  Created by Akiva Leffert on 11/10/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BGNValue;

@interface BGNEnvironment : NSObject

+ (BGNEnvironment*)empty;

- (BGNEnvironment*)pushName:(NSString*)name withValue:(id <BGNValue>)value;

@end

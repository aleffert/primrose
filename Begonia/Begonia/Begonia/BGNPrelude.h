//
//  BGNPrelude.h
//  Begonia
//
//  Created by Akiva Leffert on 11/21/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNEnvironment;

@interface BGNPrelude : NSObject

+ (BGNEnvironment*)loadIntoEnvironment:(BGNEnvironment*)env;

@end

extern NSString* BGNPreludeModuleName;
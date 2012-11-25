//
//  BGNCocoaRouter.h
//  Begonia
//
//  Created by Akiva Leffert on 11/25/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNClassFetcher;

@interface BGNCocoaRouter : NSObject

+ (BGNCocoaRouter*)router;

- (BGNClassFetcher*)classNamed;

@end

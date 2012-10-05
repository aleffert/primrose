//
//  BGNParserResult.h
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNNode;

@interface BGNParserResult : NSObject

+ (BGNParserResult*)resultWithNode:(BGNNode*)node;
+ (BGNParserResult*)resultWithError:(NSError*)error;

- (void)caseNode:(void(^)(BGNNode*))node error:(void(^)(NSError*))error;

@end

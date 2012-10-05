//
//  BGNParserResult.h
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNModule;

@protocol BGNParserResult <NSObject>

- (void)caseModule:(void(^)(BGNModule*))module error:(void(^)(NSError*))error;

@end

@interface BGNParserResult

+ (id <BGNParserResult>)resultWithModule:(BGNModule*)module;
+ (id <BGNParserResult>)resultWithError:(NSError*)error;

@end

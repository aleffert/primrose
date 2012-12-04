//
//  BGNParserResult.m
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNParserResult.h"

@interface BGNModuleParserResult : NSObject <BGNParserResult>
@property (strong, nonatomic) BGNModule* module;
@end

@implementation BGNModuleParserResult

- (void)caseModule:(void (^)(BGNModule *))module error:(void (^)(NSError *))error {
    module(self.module);
}

@end


@interface BGNErrorParserResult : NSObject <BGNParserResult>
@property (strong, nonatomic) NSError* error;
@end

@implementation BGNErrorParserResult

- (void)caseModule:(void (^)(BGNModule *))module error:(void (^)(NSError *))error {
    error(self.error);
}

@end

@implementation BGNParserResult

+ (id <BGNParserResult>)resultWithModule:(BGNModule *)module {
    BGNModuleParserResult* result = [[BGNModuleParserResult alloc] init];
    result.module = module;
    return result;
}

+ (id <BGNParserResult>)resultWithError:(NSError*)error {
    BGNErrorParserResult* result = [[BGNErrorParserResult alloc] init];
    result.error = error;
    return result;
}

@end

//
//  BGNParserResult.m
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNParserResult.h"

@interface BGNNodeParserResult : BGNParserResult
@property (retain, nonatomic) BGNNode* node;
@end

@implementation BGNNodeParserResult

- (void)caseNode:(void (^)(BGNNode *))node error:(void (^)(NSError *))error {
    node(self.node);
}

@end


@interface BGNErrorParserResult : BGNParserResult
@property (retain, nonatomic) NSError* error;
@end

@implementation BGNErrorParserResult

- (void)caseNode:(void (^)(BGNNode *))node error:(void (^)(NSError *))error {
    error(self.error);
}

@end

@implementation BGNParserResult

+ (BGNParserResult*)resultWithNode:(BGNNode*)node {
    BGNNodeParserResult* result = [[BGNNodeParserResult alloc] init];
    result.node = node;
    return result;
}

+ (BGNParserResult*)resultWithError:(NSError*)error {
    BGNErrorParserResult* result = [[BGNErrorParserResult alloc] init];
    result.error = error;
    return result;
}

- (void)caseNode:(void(^)(BGNNode*))node error:(void(^)(NSError*))error {
    NSAssert(NO, @"Abstract method", nil);
}

@end

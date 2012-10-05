//
//  BGNInterpreter.m
//  Begonia
//
//  Created by Akiva Leffert on 9/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNInterpreter.h"

#import "BGNParser.h"
#import "BGNParserResult.h"

@implementation BGNInterpreter

- (void)interpretFile:(NSString*)path {
    BGNParser* parser = [[BGNParser alloc] init];
    BGNParserResult* result = [parser parseFile:path];
    [result caseNode:^(BGNNode* node) {
        NSLog(@"parsed: %@", node);
    } error:^(NSError* error) {
        NSLog(@"parse error %@", error);
    }];
}

@end

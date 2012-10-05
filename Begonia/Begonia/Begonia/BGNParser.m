//
//  BGNParser.m
//  Begonia
//
//  Created by Akiva Leffert on 10/2/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ParseKit.h"

#import "BGNParser.h"

#import "BGNEndOfLineTokenizerState.h"
#import "BGNParserResult.h"

@class BGNNode;

@implementation BGNParser

- (BGNParserResult*)parseFile:(NSString *)path {
    NSError* error = nil;
    NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if(error != nil) {
        return [BGNParserResult resultWithError:error];
    }
    
    return [self parseString:contents sourceName:path.lastPathComponent];
}

- (NSArray*)tokenizeString:(NSString*)string sourceName:(NSString*)sourceName {
    NSMutableArray* result = [NSMutableArray array];
    PKTokenizer* tokenizer = [PKTokenizer tokenizerWithString:string];
    PKTokenizerState* eolState = [[BGNEndOfLineTokenizerState alloc] init];
    [tokenizer setTokenizerState:eolState from:'\n' to:'\n' + 1];
    PKToken* token = nil;
    while((token = [tokenizer nextToken]) != [PKToken EOFToken]) {
        [result addObject:token];
    }
    return result;
}

- (BGNParserResult*)parseString:(NSString *)string sourceName:(NSString *)sourceName {
    NSArray* tokens = [self tokenizeString:string sourceName:sourceName];
    NSLog(@"got tokens! %@", tokens);
    return [BGNParserResult resultWithError:nil];
}

@end

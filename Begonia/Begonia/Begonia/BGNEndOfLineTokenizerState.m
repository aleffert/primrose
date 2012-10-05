//
//  BGNEndOfLineTokenizerState.m
//  Begonia
//
//  Created by Akiva Leffert on 10/4/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNEndOfLineTokenizerState.h"

@interface PKTokenizerState ()
- (void)resetWithReader:(PKReader *)r;
- (void)append:(PKUniChar)c;
- (NSString *)bufferedString;
@end

@interface PKToken ()
@property (nonatomic, readwrite) NSUInteger offset;
@end

@implementation BGNEndOfLineTokenizerState

- (id)init {
    if((self = [super init])) {
    }
    return self;
}

- (BOOL)isWhitespaceChar:(unichar)c {
    return c == '\n' || c == '\r';
}

- (PKToken *)nextTokenFromReader:(PKReader *)r startingWith:(PKUniChar)cin tokenizer:(PKTokenizer *)t {
    NSParameterAssert(r);
    [self resetWithReader:r];
    
    PKUniChar c = cin;
    while ([self isWhitespaceChar:c]) {
        [self append:c];
        c = [r read];
    }
    if (PKEOF != c) {
        [r unread];
    }
    
    PKToken *tok = [PKToken tokenWithTokenType:PKTokenTypeWhitespace stringValue:@"\n" floatValue:0.0];
    tok.offset = offset;
    return tok;

}

@end

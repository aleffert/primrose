//
//  BGNPrecedenceParser.m
//  Begonia
//
//  Created by Akiva Leffert on 10/16/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNPrecedenceParser.h"

#import "NSObject+BGNConstruction.h"
#import "NSMutableArray+BGNStack.h"

@implementation BGNPrecedenceTokenAtom

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p, value = %@>", [self class], self, self.value];
}

@end

@implementation BGNPrecedenceTokenJuxtapose

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p>", [self class], self];
}

- (id)value {
    return @"(app)";
}

@end

@implementation BGNPrecedenceTokenOp

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p, isUnary = %@, value = %@>", [self class], self, @(self.isUnary), self.value];
}

@end

@implementation BGNPrecedenceParser

// Mark unary operators and add juxtaposition tokens
- (NSArray*)cleanupTokens:(NSArray*)tokens {
    id <BGNPrecedenceToken> previousToken = nil;
    NSMutableArray* resultTokens = [NSMutableArray array];
    for(id <BGNPrecedenceToken> token in tokens) {
        if([token isKindOfClass:[BGNPrecedenceTokenOp class]]) {
            BGNPrecedenceTokenOp* op = (BGNPrecedenceTokenOp*)token;
            op.isUnary = previousToken == nil || [previousToken isKindOfClass:[BGNPrecedenceTokenOp class]];
        }
        else if([token isKindOfClass:[BGNPrecedenceTokenAtom class]]) {
            if([previousToken isKindOfClass:[BGNPrecedenceTokenAtom class]]) {
                [resultTokens push: [BGNPrecedenceTokenJuxtapose new]];
            }
        }
        [resultTokens push:token];
        previousToken = token;
    }
    return resultTokens;
}

- (id)parseTokens:(NSArray*)tokens {
    // Distinguish binary and unary tokens
    tokens = [self cleanupTokens:tokens];
    // First convert to an unambigious RPN representation
    NSMutableArray* opStack = [NSMutableArray array];
    NSMutableArray* rpnStack = [NSMutableArray array];
    for (id <BGNPrecedenceToken> token in tokens) {
        if([token isKindOfClass:[BGNPrecedenceTokenOp class]]) {
            NSUInteger precedence = self.getPrecedence(token);
            BGNAssociativity assoc = self.getAssoc(token);
            if(assoc == BGNAssociativityRight) {
                while(opStack.count > 0 && precedence < self.getPrecedence([opStack lastObject])) {
                    [rpnStack push:[opStack pop]];
                }
            }
            else {
                while(opStack.count > 0 && precedence <= self.getPrecedence([opStack lastObject])) {
                    [rpnStack push:[opStack pop]];
                }
            }
            [opStack push:token];
        }
        else {
            [rpnStack push:token];
        }
    }
    
    while (opStack.count > 0) {
        [rpnStack push:[opStack pop]];
    }
    
    
    // Now just read it off the stack
    NSMutableArray* accumulator = [NSMutableArray array];
    for(id <BGNPrecedenceToken> token in rpnStack) {
        if([token isKindOfClass:[BGNPrecedenceTokenAtom class]]) {
            BGNPrecedenceTokenAtom* atom = (BGNPrecedenceTokenAtom*)token;
            [accumulator push:atom.value];
        }
        else {
            BGNPrecedenceTokenOp* op = (BGNPrecedenceTokenOp*)token;
            if (op.isUnary) {
                [accumulator push:self.unOp(op, [accumulator pop])];
            }
            else {
                id arg2 = [accumulator pop];
                id arg1 = [accumulator pop];
                [accumulator push:self.binOp(op, arg1, arg2)];
            }
        }
    }
    
    return [accumulator objectAtIndex:0];
}

+ (void)test {
    BGNPrecedenceParser* parser = [[BGNPrecedenceParser alloc] init];
    parser.getPrecedence = ^NSUInteger(BGNPrecedenceTokenOp* op) {
        if([op isKindOfClass:[BGNPrecedenceTokenJuxtapose class]]) {
            return 6;
        }
        else if([op.value isEqualToString:@"+"]){
            return 2;
        }
        else if([op.value isEqualToString:@"-"] && op.isUnary) {
            return 7;
        }
        else if([op.value isEqualToString:@"-"] && !op.isUnary) {
            return 2;
        }
        else if([op.value isEqualToString:@"*"]) {
            return 3;
        }
        else if([op.value isEqualToString:@"/"]) {
            return 4;
        }
        else {
            NSLog(@"unknown symbol %@", op.value);
            return 0;
        }
    };
    parser.getAssoc = ^BGNAssociativity(BGNPrecedenceTokenOp* op) {
        return ([op.value isEqualToString:@"-"] && op.isUnary) ? BGNAssociativityRight : BGNAssociativityLeft;
    };
    parser.unOp = ^(BGNPrecedenceTokenOp* op, id exp) {
        return @{@"op" : op.value, @"a" : exp};
    };
    parser.binOp = ^(BGNPrecedenceTokenOp* op, id exp1, id exp2) {
        return @{@"op" : op.value, @"a" : exp1, @"b" : exp2};
    };
    NSArray* tokens = @[
    [BGNPrecedenceTokenAtom makeThen:^(BGNPrecedenceTokenAtom* i){i.value = @"f";}],
    [BGNPrecedenceTokenAtom makeThen:^(BGNPrecedenceTokenAtom* i){i.value = @"x";}],
    [BGNPrecedenceTokenOp makeThen:^(BGNPrecedenceTokenOp* i){i.value = @"+";}],
    [BGNPrecedenceTokenOp makeThen:^(BGNPrecedenceTokenOp* i){i.value = @"-";}],
    [BGNPrecedenceTokenAtom makeThen:^(BGNPrecedenceTokenAtom* i){i.value = @"g";}],
    [BGNPrecedenceTokenOp makeThen:^(BGNPrecedenceTokenOp* i){i.value = @"*";}],
    [BGNPrecedenceTokenAtom makeThen:^(BGNPrecedenceTokenAtom* i){i.value = @"y";}]
    ];
    NSArray* result = [parser parseTokens:tokens];
    NSLog(@"got result %@", result);
}

@end

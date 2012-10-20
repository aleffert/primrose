//
//  BGNPrecedenceParser.h
//  Begonia
//
//  Created by Akiva Leffert on 10/16/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    BGNAssociativityLeft,
    BGNAssociativityRight
} BGNAssociativity;

@protocol BGNPrecedenceToken <NSObject>

@end

@interface BGNPrecedenceTokenOp : NSObject <BGNPrecedenceToken>

@property (copy, nonatomic) NSString* value;
@property (assign, nonatomic) BOOL isUnary;

@end

@interface BGNPrecedenceTokenJuxtapose : BGNPrecedenceTokenOp

@end

@interface BGNPrecedenceTokenAtom : NSObject <BGNPrecedenceToken>

@property (retain, nonatomic) id value;

@end


@interface BGNPrecedenceParser : NSObject

@property (copy, nonatomic) id(^binOp)(BGNPrecedenceTokenOp* op, id left, id right);
@property (copy, nonatomic) id(^unOp)(BGNPrecedenceTokenOp* op, id obj);
@property (copy, nonatomic) NSUInteger (^getPrecedence)(BGNPrecedenceTokenOp* subPart);
@property (copy, nonatomic) BGNAssociativity (^getAssoc)(BGNPrecedenceTokenOp* subPart);

- (id)parseTokens:(NSArray*)tokens;


+ (void)test;


@end

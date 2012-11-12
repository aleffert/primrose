//
//  BGNLang.m
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNLang.h"

#import "BGNTopDeclVisitor.h"

@implementation NSCharacterSet (BGNLang)

+ (NSCharacterSet*)operatorCharacterSet {
    return [NSCharacterSet characterSetWithCharactersInString:@"+-*$/^%<>=&"];
}

@end

@implementation NSString (BGNLang)

- (BOOL)isOperatorSymbol {
    return [self rangeOfCharacterFromSet:[[NSCharacterSet operatorCharacterSet] invertedSet]].location == NSNotFound;
}


@end

@implementation BGNModule

@end

@implementation BGNImport

@end

@implementation BGNExternalTypeDeclaration

- (void)acceptVisitor:(id <BGNTopDeclVisitor>)visitor {
    [visitor visitExternalTypeDecl:self];
}

@end

@implementation BGNDatatypeBinding

- (void)acceptVisitor:(id<BGNTopDeclVisitor>)visitor {
    [visitor visitDatatypeBinding:self];
}

@end

@implementation BGNScopedFunctionBinding

- (void)acceptVisitor:(id<BGNTopDeclVisitor>)visitor {
    [visitor visitFunctionBinding:self];
}

@end

@implementation BGNScopedExpBinding

- (void)acceptVisitor:(id<BGNTopDeclVisitor>)visitor {
    [visitor visitExpBinding:self];
}

@end

@implementation BGNTopExpression

- (void)acceptVisitor:(id<BGNTopDeclVisitor>)visitor {
    [visitor visitTopExp:self];
}

@end


@implementation BGNDatatypeArm

@end

@implementation BGNVarBinding

@end

@implementation BGNRecordBinding

@end

@implementation BGNRecordBindingField

@end

@implementation BGNTypeVariable

@end


@implementation BGNTypeArrow
@end

@implementation BGNTypeRecord

@end

@implementation BGNExpString

@end

@implementation BGNExpNumber

@end

@implementation BGNExpProj

@end

@implementation BGNExpApp

@end

@implementation BGNExpStmts

@end

@implementation BGNExpIfThenElse

@end

@implementation BGNExpVariable

@end

@implementation BGNExpRecord

@end

@implementation BGNExpRecordField


@end

@implementation BGNExpExternalMethod

@end


@implementation BGNExpCheck

@end

@implementation BGNExpModuleProj

@end

@implementation BGNExpLambda

@end

@implementation BGNStmtLet

@end

@implementation BGNStmtExp

@end




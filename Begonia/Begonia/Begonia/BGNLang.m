//
//  BGNLang.m
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNLang.h"

#import "BGNExpVisitor.h"
#import "BGNPatternVisitor.h"
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

- (id)acceptVisitor:(id <BGNTopDeclVisitor>)visitor {
    return [visitor visitExternalTypeDecl:self];
}

@end

@implementation BGNDatatypeBinding

- (id)acceptVisitor:(id<BGNTopDeclVisitor>)visitor {
    return [visitor visitDatatypeBinding:self];
}

@end

@implementation BGNScopedFunctionBinding

- (id)acceptVisitor:(id<BGNTopDeclVisitor>)visitor {
    return [visitor visitFunctionBinding:self];
}

@end

@implementation BGNScopedExpBinding

- (id)acceptVisitor:(id<BGNTopDeclVisitor>)visitor {
    return [visitor visitExpBinding:self];
}

@end

@implementation BGNTopExpression

- (id)acceptVisitor:(id<BGNTopDeclVisitor>)visitor {
    return [visitor visitTopExp:self];
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

- (id)acceptVisitor:(id <BGNExpVisitor>)visitor {
    return [visitor visitString:self];
}

@end

@implementation BGNExpNumber

- (id)acceptVisitor:(id <BGNExpVisitor>)visitor {
    return [visitor visitNumber:self];
}

@end

@implementation BGNExpProj

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitProjection:self];
}

@end

@implementation BGNExpApp

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitApplication:self];
}

@end

@implementation BGNCaseArm : NSObject

@end

@implementation BGNExpCase

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitCase:self];
}

@end

@implementation BGNExpStmts

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitStatements:self];
}

@end

@implementation BGNExpIfThenElse

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitIfThenElse:self];
}

@end

@implementation BGNExpVariable

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitVar:self];
}

@end

@implementation BGNExpRecord

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitRecord:self];
}

@end

@implementation BGNExpRecordField


@end

@implementation BGNExpPrimOp

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitPrimop:self];
}

@end

@implementation BGNExpCheck

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitCheck:self];
}

@end

@implementation BGNExpModuleProj

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitModuleProj:self];
}

@end

@implementation BGNExpLambda

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitLambda:self];
}

@end

@implementation BGNExpConstructor

- (id)acceptVisitor:(id<BGNExpVisitor>)visitor {
    return [visitor visitConstructor:self];
}

@end

@implementation BGNStmtLet

@end

@implementation BGNStmtExp

@end


@implementation BGNPatternInt

- (id)acceptVisitor:(id<BGNPatternVisitor>)visitor {
    return [visitor visitInt:self];
}

@end

@implementation BGNPatternBool

- (id)acceptVisitor:(id<BGNPatternVisitor>)visitor {
    return [visitor visitBool:self];
}

@end

@implementation BGNPatternString

- (id)acceptVisitor:(id<BGNPatternVisitor>)visitor {
    return [visitor visitString:self];
}

@end

@implementation BGNPatternVar

- (id)acceptVisitor:(id<BGNPatternVisitor>)visitor {
    return [visitor visitVar:self];
}

@end

@implementation BGNPatternRecordField
@end

@implementation BGNPatternRecord

- (id)acceptVisitor:(id<BGNPatternVisitor>)visitor {
    return [visitor visitRecord:self];
}

@end

@implementation BGNPatternConstructor

- (id)acceptVisitor:(id<BGNPatternVisitor>)visitor {
    return [visitor visitConstructor:self];
}

@end

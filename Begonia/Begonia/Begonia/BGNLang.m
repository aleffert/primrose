//
//  BGNLang.m
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNLang.h"

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

@end

@implementation BGNDatatypeBinding

@end

@implementation BGNDatatypeArm

@end

@implementation BGNScopedFunctionBinding

@end

@implementation BGNScopedValueBinding

@end

@implementation BGNTopExpression

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




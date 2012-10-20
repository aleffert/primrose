//
//  BGNNode.m
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNNode.h"

@implementation BGNModule

@end

@implementation BGNImport

@end

@implementation BGNExternalTypeDeclaration

- (void)caseExternalType:(void (^)(BGNExternalTypeDeclaration *))typeDeclaration datatypeBinding:(void (^)(BGNDatatypeBinding *))typeBinding funBinding:(void (^)(BGNScopedFunctionBinding *))funBinding valBinding:(void (^)(BGNScopedValueBinding *))valBinding exp:(void (^)(BGNTopExpression *))exp {
    typeDeclaration(self);
}

@end

@implementation BGNDatatypeBinding

- (void)caseExternalType:(void (^)(BGNExternalTypeDeclaration *))typeDeclaration datatypeBinding:(void (^)(BGNDatatypeBinding *))typeBinding funBinding:(void (^)(BGNScopedFunctionBinding *))funBinding valBinding:(void (^)(BGNScopedValueBinding *))valBinding exp:(void (^)(BGNTopExpression *))exp {
    typeBinding(self);
}

@end

@implementation BGNScopedFunctionBinding

- (void)caseExternalType:(void (^)(BGNExternalTypeDeclaration *))typeDeclaration datatypeBinding:(void (^)(BGNDatatypeBinding *))typeBinding funBinding:(void (^)(BGNScopedFunctionBinding *))funBinding valBinding:(void (^)(BGNScopedValueBinding *))valBinding exp:(void (^)(BGNTopExpression *))exp {
    funBinding(self);
}

@end

@implementation BGNScopedValueBinding


- (void)caseExternalType:(void (^)(BGNExternalTypeDeclaration *))typeDeclaration datatypeBinding:(void (^)(BGNDatatypeBinding *))typeBinding funBinding:(void (^)(BGNScopedFunctionBinding *))funBinding valBinding:(void (^)(BGNScopedValueBinding *))valBinding exp:(void (^)(BGNTopExpression *))exp {
    valBinding(self);
}

@end

@implementation BGNTopExpression

- (void)caseExternalType:(void (^)(BGNExternalTypeDeclaration *))typeDeclaration datatypeBinding:(void (^)(BGNDatatypeBinding *))typeBinding funBinding:(void (^)(BGNScopedFunctionBinding *))funBinding valBinding:(void (^)(BGNScopedValueBinding *))valBinding exp:(void (^)(BGNTopExpression *))exp {
    exp(self);
}

@end

@implementation BGNVarBinding

@end

@implementation BGNRecordBinding

@end

@implementation BGNRecordBindingField

@end

@implementation BGNTypeArgumentRecord

- (void)caseRecord:(void (^)(BGNTypeArgumentRecord *))record type:(void (^)(BGNTypeArgumentType *))type {
    record(self);
}

@end

@implementation BGNTypeArgumentType

- (void)caseRecord:(void (^)(BGNTypeArgumentRecord *))record type:(void (^)(BGNTypeArgumentType *))type {
    type(self);
}

@end


@implementation BGNTypeVariable

- (void)caseVar:(void (^)(BGNTypeVariable *))typeVariable arrow:(void (^)(BGNTypeArrow *))arrow recordType:(void (^)(BGNTypeRecord *))record {
    typeVariable(self);
}

@end


@implementation BGNTypeArrow

- (void)caseVar:(void (^)(BGNTypeVariable *))typeVariable arrow:(void (^)(BGNTypeArrow *))arrow recordType:(void (^)(BGNTypeRecord *))record {
    arrow(self);
}

@end

@implementation BGNTypeRecord

- (void)caseVar:(void (^)(BGNTypeVariable *))typeVariable arrow:(void (^)(BGNTypeArrow *))arrow recordType:(void (^)(BGNTypeRecord *))record {
    record(self);
}

@end


@implementation BGNExpNumber

- (void)caseNumber:(void(^)(BGNExpNumber*))number var:(void(^)(BGNExpVariable*))var path:(void(^)(BGNExpPath*))path app:(void(^)(BGNExpApp*))app group:(void(^)(BGNExpStmts*))group ifThenElse:(void(^)(BGNExpIfThenElse*))ifThenElse record:(void(^)(BGNExpRecord*))record externalMethod:(void(^)(BGNExpExternalMethod*))externalMethod {
    number(self);
}

@end

@implementation BGNExpPath

- (void)caseNumber:(void(^)(BGNExpNumber*))number var:(void(^)(BGNExpVariable*))var path:(void(^)(BGNExpPath*))path app:(void(^)(BGNExpApp*))app group:(void(^)(BGNExpStmts*))group ifThenElse:(void(^)(BGNExpIfThenElse*))ifThenElse record:(void(^)(BGNExpRecord*))record externalMethod:(void(^)(BGNExpExternalMethod*))externalMethod {
    path(self);
}

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

@implementation BGNExpLambda

@end

@implementation BGNStmtLet

- (void)caseLet:(void (^)(BGNStmtLet *))let exp:(void (^)(BGNStmtExp *))exp {
    let(self);
}

@end

@implementation BGNStmtExp

- (void)caseLet:(void (^)(BGNStmtLet *))let exp:(void (^)(BGNStmtExp *))exp {
    exp(self);
}

@end




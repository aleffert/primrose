//
//  BGNNode.h
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNNodeVisitor;


@interface BGNModule : NSObject

@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSArray* imports; // BGNImport
@property (copy, nonatomic) NSArray* declarations; //BGNTopLevelDeclaration

@end

@interface BGNImport : NSObject

@property (retain, nonatomic) NSString* name;

@end

@class BGNExternalTypeDeclaration;
@class BGNScopedFunctionBinding;
@class BGNScopedValueBinding;
@class BGNDatatypeBinding;
@class BGNTopExpression;
@protocol BGNExpression;

@protocol BGNTopLevelDeclaration

- (void)caseExternalType:(void(^)(BGNExternalTypeDeclaration*))typeDeclaration datatypeBinding:(void(^)(BGNDatatypeBinding*))typeBinding funBinding:(void(^)(BGNScopedFunctionBinding*))funBinding valBinding:(void(^)(BGNScopedValueBinding*))valBinding exp:(void(^)(BGNTopExpression*))exp;

@end

@interface BGNExternalTypeDeclaration : NSObject <BGNTopLevelDeclaration>

@property (copy, nonatomic) NSString* name;

@end

@protocol BGNTypeArgument;

@interface BGNDatatypeBinding : NSObject <BGNTopLevelDeclaration>

@property (retain, nonatomic) NSString* name;
@property (copy, nonatomic) id <BGNTypeArgument> body;

@end

typedef enum {
    BGNScopeLocal,
    BGNScopeLet
} BGNScope;

@interface BGNScopedFunctionBinding : NSObject <BGNTopLevelDeclaration>

@property (assign, nonatomic) BGNScope scope;
@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSArray* arguments; // id <BGNBindingArgument>
@property (retain, nonatomic) id <BGNExpression> body;

@end


@interface BGNScopedValueBinding : NSObject <BGNTopLevelDeclaration>

@property (assign, nonatomic) BGNScope scope;
@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNExpression> body;

@end

@interface BGNTopExpression : NSObject <BGNTopLevelDeclaration>

@property (retain, nonatomic) id <BGNExpression> expression;

@end

@class BGNVarBinding;
@class BGNRecordBinding;

@protocol BGNBindingArgument <NSObject>

@end


@interface BGNVarBinding : NSObject <BGNBindingArgument>

@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNTypeArgument> argumentType;

@end

@interface BGNRecordBinding : NSObject <BGNBindingArgument>

@property (copy, nonatomic) NSArray* fields; // BGNRecordBindingField

@end

@interface BGNRecordBindingField : NSObject

@property (retain, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNTypeArgument> type;
@property (retain, nonatomic) id <BGNExpression> defaultValue;

@end


@class BGNTypeVariable;
@class BGNTypeArrow;
@class BGNTypeRecord;

@protocol BGNType <NSObject>

- (void)caseVar:(void(^)(BGNTypeVariable*))typeVariable arrow:(void(^)(BGNTypeArrow*))arrow recordType:(void(^)(BGNTypeRecord*))record;

@end

@interface BGNTypeVariable : NSObject <BGNType>

@property (copy, nonatomic) NSString* name;

@end

@interface BGNTypeRecord : NSObject <BGNType>

@property (copy, nonatomic) NSArray* fields; // BGNTypeRecordField

@end

@class BGNTypeArgumentRecord;
@class BGNTypeArgumentType;

@protocol BGNTypeArgument <NSObject>

- (void)caseRecord:(void(^)(BGNTypeArgumentRecord*))record type:(void(^)(BGNTypeArgumentType*))type;

@end



@interface BGNTypeArgumentRecord : NSObject <BGNTypeArgument>

@property (copy, nonatomic) BGNTypeRecord* record; //BGNTypeRecordField

@end

@interface BGNTypeArgumentType : NSObject <BGNTypeArgument>

@property (retain, nonatomic) id <BGNType> type;

@end

@interface BGNTypeRecordField : NSObject

@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNTypeArgument> type;
@property (assign, nonatomic) BOOL optional;

@end

@interface BGNTypeArrow : NSObject <BGNType>

@property (retain, nonatomic) id <BGNTypeArgument> domain;
@property (retain, nonatomic) id <BGNType> codomain;

@end

@class BGNExpNumber;
@class BGNExpPath;
@class BGNExpApp;
@class BGNExpStmts;
@class BGNExpVariable;
@class BGNExpIfThenElse;
@class BGNExpRecord;
@class BGNExpExternalMethod;

@protocol BGNExpression <NSObject>
@end

@interface BGNExpNumber : NSObject <BGNExpression>

@property (retain, nonatomic) NSNumber* value;
@property (assign, nonatomic) BOOL isFloat;

@end

@interface BGNExpVariable : NSObject <BGNExpression>

@property (copy, nonatomic) NSString* name;

@end

@interface BGNExpPath : NSObject <BGNExpression>

@property (retain, nonatomic) id <BGNExpression> base;

@property (copy, nonatomic) NSArray* parts; //String

@end

@interface BGNExpApp : NSObject <BGNExpression>

@property (retain, nonatomic) id <BGNExpression> function;
@property (retain, nonatomic) id <BGNExpression> argument;

@end

@interface BGNExpStmts : NSObject <BGNExpression>

@property (copy, nonatomic) NSArray* statements; //BGNStatements

@end

@interface BGNExpIfThenElse : NSObject <BGNExpression>

@property (retain, nonatomic) id <BGNExpression> condition;
@property (retain, nonatomic) id <BGNExpression> thenCase;
@property (retain, nonatomic) id <BGNExpression> elseCase;

@end

@interface BGNExpRecord : NSObject <BGNExpression>

@property (copy, nonatomic) NSArray* fields; // BGNExpRecordField

@end

@interface BGNExpRecordField : NSObject

@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNExpression> body;

@end


@interface BGNExpExternalMethod : NSObject <BGNExpression>

@property (retain, nonatomic) id <BGNExpression> base;
@property (retain, nonatomic) id <BGNExpression> argument;
@property (retain, nonatomic) id <BGNType> resultType;

@end

@interface BGNExpLambda : NSObject <BGNExpression>

@property (retain, nonatomic) NSArray* arguments;
@property (retain, nonatomic) id <BGNExpression> body;

@end

@class BGNStmtLet;
@class BGNStmtExp;

@protocol BGNStatement <NSObject>

- (void)caseLet:(void(^)(BGNStmtLet*))let exp:(void(^)(BGNStmtExp*))exp;

@end

@interface BGNStmtLet : NSObject <BGNStatement>

@property (retain, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNExpression> body;

@end

@interface BGNStmtExp : NSObject <BGNStatement>

@property (retain, nonatomic) id <BGNExpression> exp;

@end

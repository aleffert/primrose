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
@protocol BGNExpression;

@protocol BGNTopLevelDeclaration

- (void)caseExternalType:(BGNExternalTypeDeclaration*)typeDeclaration datatypeBinding:(BGNDatatypeBinding*)typeBinding funBinding:(BGNScopedFunctionBinding*)funBinding valBinding:(BGNScopedValueBinding*)valBinding exp:(id <BGNExpression>)exp;

@end

@interface BGNExternalTypeDeclaration : NSObject <BGNTopLevelDeclaration>

@property (copy, nonatomic) NSString* name;

@end


@interface BGNDatatypeBinding : NSObject <BGNTopLevelDeclaration>

@property (retain, nonatomic) NSString* name;
@property (copy, nonatomic) NSArray* arms; // BGNDatatypeArm

@end

@interface BGNDatatypeArm : NSObject

@property (retain, nonatomic) NSString* name;
@property (copy, nonatomic) NSArray* fields; // BGNRecordBindingField

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

@class BGNVarBinding;
@class BGNRecordBinding;

@protocol BGNBindingArgument <NSObject>

- (void)caseVar:(BGNVarBinding*)varBinding record:(BGNRecordBinding*)recordBinding;

@end

@protocol BGNType;

@interface BGNVarBinding : NSObject <BGNBindingArgument>

@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNType> type;

@end

@interface BGNRecordBinding : NSObject <BGNBindingArgument>

@property (copy, nonatomic) NSArray* fields; // BGNRecordBindingField

@end

@interface BGNRecordBindingField : NSObject

@property (retain, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNType> type;
@property (retain, nonatomic) id <BGNExpression> defaultValue;

@end

@interface BGNScopedValueBinding : NSObject <BGNTopLevelDeclaration>

@property (assign, nonatomic) BGNScope scope;
@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNExpression> body;

@end

@class BGNTypeVariable;
@class BGNTypeArrow;
@class BGNTypeRecord;

@protocol BGNType <NSObject>

- (void)caseVar:(BGNTypeVariable*)typeVariable arrow:(BGNTypeArrow*)arrow recordType:(BGNTypeRecord*)record;

@end

@interface BGNTypeVariable : NSObject <BGNType>

@property (copy, nonatomic) NSString* name;

@end


@class BGNTypeRecordArgument;

@protocol BGNTypeArgument <NSObject>

- (void)caseRecord:(BGNTypeRecordArgument*)record type:(id <BGNType>)type;

@end

@interface BGNTypeRecordArgument : NSObject <BGNTypeArgument>

@property (copy, nonatomic) NSArray* fields; //BGNTypeRecordField

@end

@interface BGNTypeRecordField : NSObject

@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) BGNTypeRecordArgument* type;
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
@class BGNExpIfThenElse;
@class BGNExpRecord;
@class BGNExpExternalMethod;

@protocol BGNExpression <NSObject>

- (void)caseNumber:(BGNExpNumber*)number path:(BGNExpPath*)path app:(BGNExpApp*)app group:(BGNExpStmts*)group ifThenElse:(BGNExpIfThenElse*)ifThenElse record:(BGNExpRecord*)record externalMethod:(BGNExpExternalMethod*)externalMethod;

@end

@interface BGNExpFloat : NSObject <BGNExpression>

@property (retain, nonatomic) NSNumber* value;
@property (assign, nonatomic) BOOL isFloat;

@end

@interface BGNExpPath : NSObject <BGNExpression>

@property (retain, nonatomic) id <BGNExpression> base;

@property (copy, nonatomic) NSArray* parts;

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

@interface BGNExpRecordField : NSObject <BGNExpression>

@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNExpression> body;

@end


@interface BGNExpExternalMethod : NSObject <BGNExpression>

@property (retain, nonatomic) BGNExpPath* path;
@property (retain, nonatomic) NSString* method;
@property (retain, nonatomic) id <BGNType> resultType;

@end

@class BGNStmtLet;
@class BGNStmtExp;

@protocol BGNStatement <NSObject>

- (void)caseLet:(BGNStmtLet*)let exp:(id <BGNExpression>)exp;

@end

@interface BGNStmtLet : NSObject <BGNStatement>

@property (retain, nonatomic) id <BGNBindingArgument> binder;
@property (retain, nonatomic) id <BGNExpression> body;

@end

@interface BGNStmtExp : NSObject <BGNStatement>

@property (retain, nonatomic) id <BGNExpression> exp;

@end

//
//  BGNLang.h
//  Begonia
//
//  Created by Akiva Leffert on 10/3/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BGNLang)

@property (readonly) BOOL isOperatorSymbol;

@end


@interface BGNModule : NSObject

@property (copy, nonatomic) NSArray* imports; // BGNImport
@property (copy, nonatomic) NSArray* declarations; //BGNTopLevelDeclaration

@end

@interface BGNImport : NSObject

@property (assign, nonatomic) BOOL open;

@property (strong, nonatomic) NSString* name;

@end

@protocol BGNTopDeclVisitor;

@class BGNExternalTypeDeclaration;
@class BGNScopedFunctionBinding;
@class BGNScopedExpBinding;
@class BGNDatatypeBinding;
@class BGNTopExpression;
@protocol BGNExpression;


@protocol BGNTopLevelDeclaration

- (id)acceptVisitor:(id <BGNTopDeclVisitor>)visitor;

@end

@interface BGNExternalTypeDeclaration : NSObject <BGNTopLevelDeclaration>

@property (copy, nonatomic) NSString* name;

@end

@interface BGNDatatypeBinding : NSObject <BGNTopLevelDeclaration>

@property (strong, nonatomic) NSString* name;
@property (copy, nonatomic) NSArray* arms;

@end


@class BGNRecordBinding;

@interface BGNDatatypeArm : NSObject

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) BGNRecordBinding* type;

@end

typedef enum {
    BGNScopeLocal,
    BGNScopeLet
} BGNScope;


@protocol BGNType;

@interface BGNScopedFunctionBinding : NSObject <BGNTopLevelDeclaration>

@property (strong, nonatomic) id <BGNType> resultType;
@property (assign, nonatomic) BGNScope scope;
@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSArray* arguments; // id <BGNBindingArgument>
@property (strong, nonatomic) id <BGNExpression> body;

@end


@interface BGNScopedExpBinding : NSObject <BGNTopLevelDeclaration>

@property (assign, nonatomic) BGNScope scope;
@property (copy, nonatomic) NSString* name;
@property (strong, nonatomic) id <BGNExpression> body;

@end

@interface BGNTopExpression : NSObject <BGNTopLevelDeclaration>

@property (strong, nonatomic) id <BGNExpression> expression;

@end

@class BGNVarBinding;

@protocol BGNBindingArgument <NSObject>

@end


@interface BGNVarBinding : NSObject <BGNBindingArgument>

@property (copy, nonatomic) NSString* name;
@property (strong, nonatomic) id <BGNType> type;

@end

@interface BGNRecordBinding : NSObject <BGNBindingArgument>

@property (copy, nonatomic) NSArray* fields; // BGNRecordBindingField

@end

@interface BGNRecordBindingField : NSObject

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) id <BGNType> type;
@property (strong, nonatomic) id <BGNExpression> defaultValue;

@end


@class BGNTypeVariable;
@class BGNTypeArrow;
@class BGNTypeRecord;

@protocol BGNType <NSObject>
@end

@interface BGNTypeVariable : NSObject <BGNType>

@property (copy, nonatomic) NSString* name;

@end

@interface BGNTypeRecord : NSObject <BGNType>

@property (strong, nonatomic) BGNRecordBinding* fields;

@end

@interface BGNTypeArrow : NSObject <BGNType>

@property (strong, nonatomic) id <BGNType> domain;
@property (strong, nonatomic) id <BGNType> codomain;

@end

@class BGNExpNumber;
@class BGNExpPath;
@class BGNExpApp;
@class BGNExpStmts;
@class BGNExpVariable;
@class BGNExpIfThenElse;
@class BGNExpRecord;
@class BGNExpExternalMethod;

@protocol BGNExpVisitor;

@protocol BGNExpression <NSObject>

- (id)acceptVisitor:(id <BGNExpVisitor>)visitor;

@end

@interface BGNExpNumber : NSObject <BGNExpression>

@property (strong, nonatomic) NSNumber* value;
@property (assign, nonatomic) BOOL isFloat;

@end

@interface BGNExpString : NSObject <BGNExpression>

@property (strong, nonatomic) NSString* value;

@end

@interface BGNExpVariable : NSObject <BGNExpression>

@property (copy, nonatomic) NSString* name;

@end

@interface BGNExpProj : NSObject <BGNExpression>

@property (strong, nonatomic) id <BGNExpression> base;

@property (copy, nonatomic) NSString* proj;

@end

@interface BGNExpApp : NSObject <BGNExpression>

@property (strong, nonatomic) id <BGNExpression> function;
@property (strong, nonatomic) id <BGNExpression> argument;

@end

@interface BGNExpPrimOp : NSObject <BGNExpression>

@property (strong, nonatomic) NSArray* args;
@property (copy, nonatomic) NSString* name;

@end

@interface BGNExpStmts : NSObject <BGNExpression>

@property (copy, nonatomic) NSArray* statements; //BGNStatements

@end

@interface BGNExpIfThenElse : NSObject <BGNExpression>

@property (strong, nonatomic) id <BGNExpression> condition;
@property (strong, nonatomic) id <BGNExpression> thenCase;
@property (strong, nonatomic) id <BGNExpression> elseCase;

@end

@interface BGNExpRecord : NSObject <BGNExpression>

@property (copy, nonatomic) NSArray* fields; // BGNExpRecordField

@end

@interface BGNExpConstructor : NSObject <BGNExpression>

@property (copy, nonatomic) NSString* name;
@property (strong, nonatomic) id <BGNExpression> body;

@end

@protocol BGNPattern;

@interface BGNCaseArm : NSObject

@property (strong, nonatomic) id <BGNPattern> pattern;
@property (strong, nonatomic) id <BGNExpression> body;

@end

@interface BGNExpCase : NSObject <BGNExpression>

@property (strong, nonatomic) id <BGNExpression> test;
@property (strong, nonatomic) NSArray* branches;

@end

@interface BGNExpRecordField : NSObject

@property (copy, nonatomic) NSString* name;
@property (strong, nonatomic) id <BGNExpression> body;

@end

@interface BGNExpLambda : NSObject <BGNExpression>

@property (strong, nonatomic) NSArray* arguments; // BGNBindingArgument
@property (strong, nonatomic) id <BGNExpression> body;

@end

@interface BGNExpCheck : NSObject <BGNExpression>

@property (strong, nonatomic) id <BGNExpression> body;
@property (strong, nonatomic) id <BGNType> type;

@end

@interface BGNExpModuleProj : NSObject <BGNExpression>

@property (strong, nonatomic) NSString* moduleName;
@property (strong, nonatomic) NSString* proj;

@end

@class BGNStmtLet;
@class BGNStmtExp;

@protocol BGNStatement <NSObject>

@end

@interface BGNStmtLet : NSObject <BGNStatement>

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) id <BGNExpression> body;

@end

@interface BGNStmtExp : NSObject <BGNStatement>

@property (strong, nonatomic) id <BGNExpression> exp;

@end

@protocol BGNPatternVisitor;

@protocol BGNPattern <NSObject>

- (id)acceptVisitor:(id <BGNPatternVisitor>)visitor;

@end

@interface BGNPatternInt : NSObject <BGNPattern>

@property (assign, nonatomic) NSInteger value;

@end

@interface BGNPatternBool : NSObject <BGNPattern>

@property (assign, nonatomic) BOOL value;

@end

@interface BGNPatternString : NSObject <BGNPattern>

@property (assign, nonatomic) NSString* value;

@end

@interface BGNPatternVar : NSObject <BGNPattern>

@property (assign, nonatomic) NSString* name;

@end

@interface BGNPatternRecordField : NSObject

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) id <BGNPattern> body;

@end

@interface BGNPatternRecord : NSObject <BGNPattern>

@property (copy, nonatomic) NSArray* fields; // BGNPatternRecordField

@end

@interface BGNPatternConstructor : NSObject <BGNPattern>

@property (strong, nonatomic) NSString* constructor;
@property (strong, nonatomic) id <BGNPattern> body;

@end
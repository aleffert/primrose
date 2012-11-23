//
//  BGNExpVisitor.h
//  Begonia
//
//  Created by Akiva Leffert on 11/16/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BGNLang.h"

@protocol BGNExpVisitor <NSObject>

- (id)visitNumber:(BGNExpNumber*)number;
- (id)visitString:(BGNExpString*)string;
- (id)visitProjection:(BGNExpProj*)proj;
- (id)visitApplication:(BGNExpApp*)app;
- (id)visitStatements:(BGNExpStmts*)statements;
- (id)visitIfThenElse:(BGNExpIfThenElse*)conditional;
- (id)visitVar:(BGNExpVariable*)var;
- (id)visitRecord:(BGNExpRecord*)record;
- (id)visitCase:(BGNExpCase*)matcher;
- (id)visitCheck:(BGNExpCheck*)typeCheck;
- (id)visitModuleProj:(BGNExpModuleProj*)moduleProj;
- (id)visitLambda:(BGNExpLambda*)lambda;
- (id)visitConstructor:(BGNExpConstructor*)construction;
- (id)visitPrimop:(BGNExpPrimOp*)primOp;

@end


@interface BGNExpBlockVisitor : NSObject <BGNExpVisitor>

@property (copy, nonatomic) id (^numberBlock)(BGNExpNumber*);
@property (copy, nonatomic) id (^stringBlock)(BGNExpString*);
@property (copy, nonatomic) id (^projectionBlock)(BGNExpProj*);
@property (copy, nonatomic) id (^applicationBlock)(BGNExpApp*);
@property (copy, nonatomic) id (^statementsBlock)(BGNExpStmts*);
@property (copy, nonatomic) id (^conditionalBlock)(BGNExpIfThenElse*);
@property (copy, nonatomic) id (^varBlock)(BGNExpVariable*);
@property (copy, nonatomic) id (^recordBlock)(BGNExpRecord*);
@property (copy, nonatomic) id (^caseBlock)(BGNExpCase*);
@property (copy, nonatomic) id (^checkBlock)(BGNExpCheck*);
@property (copy, nonatomic) id (^moduleProjBlock)(BGNExpModuleProj*);
@property (copy, nonatomic) id (^lambdaBlock)(BGNExpLambda*);
@property (copy, nonatomic) id (^constructorBlock)(BGNExpConstructor*);
@property (copy, nonatomic) id (^primopBlock)(BGNExpPrimOp*);

@end

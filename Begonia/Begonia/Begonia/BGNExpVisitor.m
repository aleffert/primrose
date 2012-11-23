//
//  BGNExpVisitor.m
//  Begonia
//
//  Created by Akiva Leffert on 11/17/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNExpVisitor.h"

@implementation BGNExpBlockVisitor

- (id)visitNumber:(BGNExpNumber*)number {
    return self.numberBlock(number);
}

- (id)visitString:(BGNExpString*)string {
    return self.stringBlock(string);
}

- (id)visitProjection:(BGNExpProj*)proj {
    return self.projectionBlock(proj);
}

- (id)visitApplication:(BGNExpApp*)app {
    return self.applicationBlock(app);
}

- (id)visitStatements:(BGNExpStmts*)statements {
    return self.statementsBlock(statements);
}

- (id)visitIfThenElse:(BGNExpIfThenElse*)conditional {
    return self.conditionalBlock(conditional);
}

- (id)visitVar:(BGNExpVariable*)var {
    return self.varBlock(var);
}

- (id)visitRecord:(BGNExpRecord*)record {
    return self.recordBlock(record);
}

- (id)visitCase:(BGNExpCase *)matcher {
    return self.caseBlock(matcher);
}

- (id)visitCheck:(BGNExpCheck*)typeCheck {
    return self.checkBlock(typeCheck);
}

- (id)visitModuleProj:(BGNExpModuleProj*)moduleProj {
    return self.moduleProjBlock(moduleProj);
}

- (id)visitLambda:(BGNExpLambda*)lambda {
    return self.lambdaBlock(lambda);
}

- (id)visitConstructor:(BGNExpConstructor*)construction {
    return self.constructorBlock(construction);
}

- (id)visitPrimop:(BGNExpPrimOp *)primOp {
    return self.primopBlock(primOp);
}

@end

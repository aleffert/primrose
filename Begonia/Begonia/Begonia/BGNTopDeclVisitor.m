//
//  BGNTopDeclVisitor.m
//  Begonia
//
//  Created by Akiva Leffert on 11/11/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNTopDeclVisitor.h"

@implementation BGNTopDeclBlockVisitor

- (void)visitExpBinding:(BGNScopedExpBinding *)decl {
    self.expBinding(decl);
}

- (void)visitFunctionBinding:(BGNScopedFunctionBinding *)decl {
    self.functionBinding(decl);
}

- (void)visitDatatypeBinding:(BGNDatatypeBinding *)decl {
    self.datatypeDecl(decl);
}

- (void)visitExternalTypeDecl:(BGNExternalTypeDeclaration *)decl {
    self.externalTypeDecl(decl);
}

- (void)visitTopExp:(BGNTopExpression *)decl {
    self.exp(decl);
}

@end

//
//  BGNTopDeclVisitor.m
//  Begonia
//
//  Created by Akiva Leffert on 11/11/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNTopDeclVisitor.h"

@implementation BGNTopDeclBlockVisitor

- (id)visitExpBinding:(BGNScopedExpBinding *)decl {
    return self.expBinding(decl);
}

- (id)visitFunctionBinding:(BGNScopedFunctionBinding *)decl {
    return self.functionBinding(decl);
}

- (id)visitDatatypeBinding:(BGNDatatypeBinding *)decl {
    return self.datatypeDecl(decl);
}

- (id)visitExternalTypeDecl:(BGNExternalTypeDeclaration *)decl {
    return self.externalTypeDecl(decl);
}

- (id)visitTopExp:(BGNTopExpression *)decl {
    return self.exp(decl);
}

@end

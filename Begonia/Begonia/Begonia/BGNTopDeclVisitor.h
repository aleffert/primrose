//
//  BGNTopDeclVisitor.h
//  Begonia
//
//  Created by Akiva Leffert on 11/11/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNExternalTypeDeclaration;
@class BGNScopedFunctionBinding;
@class BGNScopedExpBinding;
@class BGNDatatypeBinding;
@class BGNTopExpression;

@protocol BGNTopDeclVisitor <NSObject>

- (id)visitExternalTypeDecl:(BGNExternalTypeDeclaration*)decl;
- (id)visitFunctionBinding:(BGNScopedFunctionBinding*)decl;
- (id)visitExpBinding:(BGNScopedExpBinding*)decl;
- (id)visitDatatypeBinding:(BGNDatatypeBinding*)decl;
- (id)visitTopExp:(BGNTopExpression*)decl;

@end


@interface BGNTopDeclBlockVisitor : NSObject <BGNTopDeclVisitor>

@property (copy, nonatomic) id (^externalTypeDecl)(BGNExternalTypeDeclaration*);
@property (copy, nonatomic) id (^functionBinding)(BGNScopedFunctionBinding*);
@property (copy, nonatomic) id (^expBinding)(BGNScopedExpBinding*);
@property (copy, nonatomic) id (^datatypeDecl)(BGNDatatypeBinding*);
@property (copy, nonatomic) id (^exp)(BGNTopExpression*);

@end
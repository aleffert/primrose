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

- (void)visitExternalTypeDecl:(BGNExternalTypeDeclaration*)decl;
- (void)visitFunctionBinding:(BGNScopedFunctionBinding*)decl;
- (void)visitExpBinding:(BGNScopedExpBinding*)decl;
- (void)visitDatatypeBinding:(BGNDatatypeBinding*)decl;
- (void)visitTopExp:(BGNTopExpression*)decl;

@end


@interface BGNTopDeclBlockVisitor : NSObject <BGNTopDeclVisitor>

@property (copy, nonatomic) void (^externalTypeDecl)(BGNExternalTypeDeclaration*);
@property (copy, nonatomic) void (^functionBinding)(BGNScopedFunctionBinding*);
@property (copy, nonatomic) void (^expBinding)(BGNScopedExpBinding*);
@property (copy, nonatomic) void (^datatypeDecl)(BGNDatatypeBinding*);
@property (copy, nonatomic) void (^exp)(BGNTopExpression*);

@end
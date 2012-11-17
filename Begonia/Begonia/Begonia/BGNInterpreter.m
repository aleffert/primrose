//
//  BGNInterpreter.m
//  Begonia
//
//  Created by Akiva Leffert on 9/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNInterpreter.h"

#import "BGNEnvironment.h"
#import "BGNLang.h"
#import "BGNParser.h"
#import "BGNParserResult.h"
#import "BGNTopDeclVisitor.h"
#import "BGNValue.h"

#import "NSArray+Functional.h"

@interface BGNInterpreter ()

@property (retain, nonatomic) BGNModuleManager* moduleManager;
@property (retain, nonatomic) BGNEnvironment* environment;

@end

@implementation BGNInterpreter

- (id)init {
    if((self = [super init])) {
        self.moduleManager = [[BGNModuleManager alloc] init];
        self.moduleManager.delegate = self;
        self.environment = [BGNEnvironment empty];
    }
    return self;
}

- (void)interpretFile:(NSString*)path {
    NSString* name = path.lastPathComponent.stringByDeletingPathExtension.capitalizedString;
    [self.moduleManager loadModuleNamed:name atPath:path];
}

- (id <BGNValue>)evaluateExp:(id <BGNExpression>)exp inEnvironment:(BGNEnvironment*)env {
    return nil;
}

- (BGNEnvironment*)evaluateDeclaration:(id <BGNTopLevelDeclaration>)decl inEnvironment:(BGNEnvironment*)env {
    BGNTopDeclBlockVisitor* visitor = [[BGNTopDeclBlockVisitor alloc] init];

    visitor.externalTypeDecl = ^(BGNExternalTypeDeclaration* decl) {
        // TODO write a type system
        return env;
    };
    visitor.expBinding = ^(BGNScopedExpBinding* binding) {
        // TODO deal with local/let
        id <BGNValue> value = [self evaluateExp:binding.body inEnvironment:env];
        return [env bindExpVar:binding.name withValue:value];
    };
    visitor.functionBinding = ^(BGNScopedFunctionBinding* binding) {
        // TODO deal with local/let
        BGNValueFunction* function = [[BGNValueFunction alloc] init];
        function.body = binding.body;
        function.vars = binding.arguments;
        BGNEnvironment* result = [env bindExpVar:binding.name withValue:function];
        
        function.env = result;
        return result;
    };
    visitor.datatypeDecl = ^(BGNDatatypeBinding* data) {
        return env;
    };
    visitor.exp = ^(BGNTopExpression* exp) {
        [self evaluateExp:exp.expression inEnvironment:env];
        return env;
    };
    
    return [decl acceptVisitor:visitor];
}

- (void)moduleManager:(BGNModuleManager *)manager loadedModule:(BGNModule *)module named:(NSString *)name {
    self.environment = [self.environment scopeModuleNamed:name inBody:^BGNEnvironment *(BGNEnvironment *env) {
        for(BGNImport* import in module.imports) {
            env = import.open ? [env openModuleNamed:import.name] : [env importModuleNamed:import.name];
        }
        for(id <BGNTopLevelDeclaration> decl in module.declarations) {
            env = [self evaluateDeclaration:decl inEnvironment:env];
        }
        return env;
    }];
}

@end

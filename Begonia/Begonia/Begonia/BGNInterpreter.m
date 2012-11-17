//
//  BGNInterpreter.m
//  Begonia
//
//  Created by Akiva Leffert on 9/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNInterpreter.h"

#import "BGNExpVisitor.h"
#import "BGNEnvironment.h"
#import "BGNLang.h"
#import "BGNParser.h"
#import "BGNParserResult.h"
#import "BGNTopDeclVisitor.h"
#import "BGNValue.h"

#import "NSArray+Functional.h"
#import "NSObject+BGNConstruction.h"

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

- (id <BGNValue>)unitValue {
    return [BGNValueRecord makeThen:^(BGNValueRecord* record) {
        record.fields = @[];
    }];
}

- (id <BGNValue>)callExternalMethodNamed:(NSString*)name onObject:(id)object args:(NSArray*)arguments {
    // TODO!
    return [self unitValue];
}

- (id <BGNValue>)fieldNamed:(NSString*)name inRecord:(BGNValueRecord*)record {
    NSUInteger index = [record.fields indexOfObjectPassingTest:^BOOL(BGNValueRecordField* field, NSUInteger idx, BOOL *stop) {
        return [field.name isEqualToString:name];
    }];
    NSAssert(index != NSNotFound, @"Unable to find field %@ in %@", name, record);
    BGNValueRecordField* field = record.fields[index];
    return field.value;
}

- (id <BGNValue>)evaluateExp:(id <BGNExpression>)exp inEnvironment:(BGNEnvironment*)env {
    BGNExpBlockVisitor* visitor = [[BGNExpBlockVisitor alloc] init];
    visitor.numberBlock = ^(BGNExpNumber* number) {
        if(number.isFloat) {
            return [BGNValueFloat makeThen:^(BGNValueInt* val) {
                val.value = [number.value floatValue];
            }];
        }
        else {
            return [BGNValueInt makeThen:^(BGNValueInt* val) {
                val.value = [number.value integerValue];
            }];
        }
    };
    visitor.stringBlock = ^(BGNExpString* string) {
        return [BGNValueString makeThen:^(BGNValueString* str) {
            str.value = string.value;
        }];
    };
    visitor.statementsBlock = ^(BGNExpStmts* stmts) {
        BGNEnvironment* e = env;
        id <BGNValue> unit = [self unitValue];
        
        id <BGNValue> result = unit;
        for(id <BGNStatement> statement in stmts.statements) {
            if([statement isKindOfClass:[BGNStmtExp class]]) {
                BGNStmtExp* exp = (BGNStmtExp*)statement;
                result = [self evaluateExp:exp.exp inEnvironment:e];
            }
            else if([statement isKindOfClass:[BGNStmtLet class]]) {
                BGNStmtLet* let = (BGNStmtLet*)statement;
                result = [self evaluateExp:let.body inEnvironment:e];
                e = [e bindExpVar:let.name withValue:result];
            }
            else {
                NSAssert(NO, @"Unexpected statement type %@", statement);
            }
        }
        return result;
    };
    visitor.conditionalBlock = ^id <BGNValue>(BGNExpIfThenElse* conditional) {
        id <BGNValue> value = [self evaluateExp:conditional.condition inEnvironment:env];
        if([value isKindOfClass:[BGNValueBool class]]) {
            BGNValueBool* boolean = (BGNValueBool*)value;
            return boolean.value ? [self evaluateExp:conditional.thenCase inEnvironment:env] : [self evaluateExp:conditional.elseCase inEnvironment:env];
        }
        else {
            NSAssert(NO, @"Type error. Expecting Bool, found %@", value);
            return nil;
        }
    };
    visitor.constructorBlock = ^(BGNExpConstructor* constructor) {
        return [BGNValueConstructor makeThen:^(BGNValueConstructor* c) {
            c.name = constructor.name;
            c.value = [self evaluateExp:constructor.body inEnvironment:env];
        }];
    };
    visitor.checkBlock = ^(BGNExpCheck* check) {
        return [self evaluateExp:check.body inEnvironment:env];
    };
    visitor.lambdaBlock = ^(BGNExpLambda* lambda) {
        return [BGNValueFunction makeThen:^(BGNValueFunction* function) {
            function.body = lambda.body;
            function.env = env;
            function.vars = lambda.arguments;
        }];
    };
    visitor.recordBlock = ^(BGNExpRecord* record) {
        return [BGNValueRecord makeThen:^(BGNValueRecord* r){
            r.fields = [record.fields map:^(BGNExpRecordField* field) {
                return [BGNValueRecordField makeThen:^(BGNValueRecordField* resultField) {
                    resultField.name = field.name;
                    resultField.value = [self evaluateExp:field.body inEnvironment:env];
                }];
            }];
        }];
    };
    visitor.moduleProjBlock = ^(BGNExpModuleProj* moduleProj) {
        return [env valueNamed:moduleProj.proj inModule:moduleProj.moduleName];
    };
    visitor.varBlock = ^(BGNExpVariable* var) {
        return [env valueNamed:var.name inModule:nil];
    };
    visitor.projectionBlock = ^id <BGNValue>(BGNExpProj* proj) {
        id <BGNValue> body = [self evaluateExp:proj.base inEnvironment:env];
        // Cases:
        // 1. record
        if([body isKindOfClass:[BGNValueRecord class]]) {
            BGNValueRecord* record = (BGNValueRecord*)body;
            return [self fieldNamed:proj.proj inRecord:record];
        }
        // 2. through a constructor
        else if([body isKindOfClass:[BGNValueConstructor class]]) {
            BGNValueConstructor* inj = (BGNValueConstructor*)body;
            NSAssert([inj.value isKindOfClass:[BGNValueRecord class]], @"Projecting %@ from datatype without record body: %@", proj.proj, inj);
            return [self fieldNamed:proj.proj inRecord:(BGNValueRecord*)inj.value];
        }
        // 3. external object
        else if([body isKindOfClass:[BGNValueExternalObject class]]) {
            BGNValueExternalObject* object = (BGNValueExternalObject*)body;
            return [self callExternalMethodNamed:proj.proj onObject:object args:@[]];
        }
        else {
            NSAssert(NO, @"Projection '%@' from unexpected value type %@", proj.proj, body);
            return nil;
        }
    };
    
    return [exp acceptVisitor:visitor];
}

- (BGNEnvironment*)evaluateDeclaration:(id <BGNTopLevelDeclaration>)decl inEnvironment:(BGNEnvironment*)env {
    BGNTopDeclBlockVisitor* visitor = [[BGNTopDeclBlockVisitor alloc] init];

    visitor.externalTypeDecl = ^(BGNExternalTypeDeclaration* decl) {
        // ignore. static action
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
        // TODO. Make functions for datatype arms
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

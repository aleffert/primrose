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
#import "BGNPrelude.h"
#import "BGNPrimops.h"
#import "BGNTopDeclVisitor.h"
#import "BGNValue.h"

#import <objc/runtime.h>
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
        self.environment = [BGNPrelude loadIntoEnvironment:[BGNEnvironment empty]];
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

- (id <BGNValue>)evaluatePrimop:(NSString*)name args:(NSArray*)args {
    return [BGNPrimops evaluatePrimop:name args:args inInterpreter:self];
}

- (id <BGNValue>)callExternalMethodNamed:(NSString*)name onObject:(id)object args:(NSArray*)arguments {
    SEL selector = NSSelectorFromString(name);
    NSMethodSignature* signature = [self methodSignatureForSelector:selector];
    NSAssert(signature != nil, @"DynamicError: Couldn't find selector %@ on %@", name, object);
    NSAssert(signature.numberOfArguments == arguments.count + 2, @"FFIError: Selector %@ argumentCount didn't match arguments %@", name, arguments);
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:object];
    [invocation setSelector:selector];
    for(NSUInteger i = 2; i < signature.numberOfArguments; i++) {
        const char* argType = [signature getArgumentTypeAtIndex:i];
        id <BGNValue> value = arguments[i - 2];
        if(strcmp(argType, @encode(CGFloat))) {
            NSAssert([value isKindOfClass:[BGNValueFloat class]], @"FFIError: Passing %@ to ffi call expecting float named %@", value, name);
            BGNValueFloat* wrappedV = (BGNValueFloat*)value;
            CGFloat v = wrappedV.value;
            [invocation setArgument:&v atIndex:i];
        }
        else if(strcmp(argType, @encode(NSUInteger)) || strcmp(argType, @encode(NSInteger))) {
            NSAssert([value isKindOfClass:[BGNValueInt class]], @"FFIError: Passing %@ to ffi call expecting int named %@", value, name);
            BGNValueInt* wrappedV = (BGNValueInt*)value;
            NSInteger v = wrappedV.value;
            [invocation setArgument:&v atIndex:i];
        }
        else if(strcmp(argType, @encode(BOOL))) {
            NSAssert([value isKindOfClass:[BGNValueBool class]], @"FFIError: Passing %@ to ffi call expecting bool named %@", value, name);
            BGNValueBool* wrappedV = (BGNValueBool*)value;
            BOOL v = wrappedV.value;
            [invocation setArgument:&v atIndex:i];
        }
        else if(strcmp(argType, @encode(CGPoint))) {
            NSAssert([value isKindOfClass:[BGNValueConstructor class]], @"FFIError: Expecting Point calling out to CGPoint FFI argument method %@, argument %@", name, value);
            BGNValueConstructor* data = (BGNValueConstructor*)value;
            NSAssert([data.value isKindOfClass:[BGNValueRecord class]], @"FFIError: Expecting datatype with record body coercing to CGPoint. Found %@ for method", data.value, name);
            BGNValueRecord* body = (BGNValueRecord*)data.value;
            id <BGNValue> xField = [self fieldNamed:@"x" inRecord:body];
            id <BGNValue> yField = [self fieldNamed:@"y" inRecord:body];
            NSAssert([xField isKindOfClass:[BGNValueFloat class]], @"FFIError: Expecting float arguments to method %@ expecting CGPoint", name);
            CGFloat x = ((BGNValueFloat*)xField).value;
            CGFloat y = ((BGNValueFloat*)yField).value;
            CGPoint v = CGPointMake(x, y);
            [invocation setArgument:&v atIndex:i];
        }
        else if(strcmp(argType, @encode(CGRect))) {
            NSAssert([value isKindOfClass:[BGNValueConstructor class]], @"FFIError: Expecting Rect calling out to CGPoint FFI argument method %@, argument %@", name, value);
            BGNValueConstructor* data = (BGNValueConstructor*)value;
            NSAssert([data.value isKindOfClass:[BGNValueRecord class]], @"FFIError: Expecting datatype with record body coercing to CGRect. Found %@ for method", data.value, name);
            BGNValueRecord* body = (BGNValueRecord*)data.value;
            id <BGNValue> xField = [self fieldNamed:@"x" inRecord:body];
            id <BGNValue> yField = [self fieldNamed:@"y" inRecord:body];
            id <BGNValue> widthField = [self fieldNamed:@"width" inRecord:body];
            id <BGNValue> heightField = [self fieldNamed:@"height" inRecord:body];
            NSAssert([xField isKindOfClass:[BGNValueFloat class]], @"FFIError: Expecting float arguments to method %@ expecting CGRect", name);
            CGFloat x = ((BGNValueFloat*)xField).value;
            CGFloat y = ((BGNValueFloat*)yField).value;
            CGFloat width = ((BGNValueFloat*)widthField).value;
            CGFloat height = ((BGNValueFloat*)heightField).value;
            CGRect v = CGRectMake(x, y, width, height);
            [invocation setArgument:&v atIndex:i];
        }
        else if(strcmp(argType, @encode(id))) {
            if([value isKindOfClass:[BGNValueString class]]) {
                NSString* string = ((BGNValueString*)value).value;
                [invocation setArgument:&string atIndex:i];
            }
            else if([value isKindOfClass:[BGNValueExternalObject class]]) {
                id object = ((BGNValueExternalObject*)value).value;
                [invocation setArgument:&object atIndex:i];
            }
            else {
                NSAssert(NO, @"FFIError: Unexpected object type %@ for external method named %@", value, name);
            }
        }
        // TODO deal with blocks. UGH
    }
    [invocation invoke];
    const char* returnType = signature.methodReturnType;
    if(strcmp(returnType, @encode(void))) {
        return [self unitValue];
    }
    else if(strcmp(returnType, @encode(id))) {
        id result = nil;
        [invocation getReturnValue:&result];
        if([result isKindOfClass:[NSString class]]) {
            return [BGNValueString makeThen:^(BGNValueString* s) {
                s.value = result;
            }];
        }
        else {
            return [BGNValueExternalObject makeThen:^(BGNValueExternalObject* o) {
                o.value = result;
            }];
        }
    }
    else if(strcmp(returnType, @encode(CGFloat))) {
        CGFloat v = 0;
        [invocation getReturnValue:&v];
        return [BGNValueFloat makeThen:^(BGNValueFloat* f){
            f.value = v;
        }];
    }
    else if(strcmp(returnType, @encode(NSInteger)) || strcmp(returnType, @encode(NSUInteger))) {
        NSUInteger r = 0;
        [invocation getReturnValue:&r];
        return [BGNValueFloat makeThen:^(BGNValueInt* i){
            i.value = r;
        }];
    }
    else if(strcmp(returnType, @encode(CGPoint))) {
        CGPoint result = CGPointZero;
        [invocation getReturnValue:&result];
        return [BGNValueRecord makeThen:^(BGNValueRecord* r){
            r.fields = @[
            [BGNValueRecordField makeThen:^(BGNValueRecordField* f){
                f.name = @"x"; f.value = [BGNValueFloat makeThen:^(BGNValueFloat* vf) {
                    vf.value = result.x;
                }];
            }],
            [BGNValueRecordField makeThen:^(BGNValueRecordField* f){
                f.name = @"y"; f.value = [BGNValueFloat makeThen:^(BGNValueFloat* vf) {
                    vf.value = result.y;
                }];
            }],
            ];
        }];
    }
    else if(strcmp(returnType, @encode(CGRect))) {
        CGRect result = CGRectZero;
        [invocation getReturnValue:&result];
        return [BGNValueRecord makeThen:^(BGNValueRecord* r){
            r.fields = @[
            [BGNValueRecordField makeThen:^(BGNValueRecordField* f){
                f.name = @"x"; f.value = [BGNValueFloat makeThen:^(BGNValueFloat* vf) {
                    vf.value = result.origin.x;
                }];
            }],
            [BGNValueRecordField makeThen:^(BGNValueRecordField* f){
                f.name = @"y"; f.value = [BGNValueFloat makeThen:^(BGNValueFloat* vf) {
                    vf.value = result.origin.y;
                }];
            }],
            [BGNValueRecordField makeThen:^(BGNValueRecordField* f){
                f.name = @"width"; f.value = [BGNValueFloat makeThen:^(BGNValueFloat* vf) {
                    vf.value = result.size.width;
                }];
            }],
            [BGNValueRecordField makeThen:^(BGNValueRecordField* f){
                f.name = @"height"; f.value = [BGNValueFloat makeThen:^(BGNValueFloat* vf) {
                    vf.value = result.size.height;
                }];
            }],
            ];
        }];
    }
    else {
        NSAssert(NO, @"Unhandled return type %s from %@", returnType, name);
        return nil;
    }
}

- (id <BGNValue>)fieldNamed:(NSString*)name inRecord:(BGNValueRecord*)record {
    NSUInteger index = [record.fields indexOfObjectPassingTest:^BOOL(BGNValueRecordField* field, NSUInteger idx, BOOL *stop) {
        return [field.name isEqualToString:name];
    }];
    NSAssert(index != NSNotFound, @"StaticError: Unable to find field %@ in %@", name, record);
    BGNValueRecordField* field = record.fields[index];
    return field.value;
}

- (BGNEnvironment*)bindArgument:(id <BGNBindingArgument>)bind toValue:(id <BGNValue>)arg inEnvironment:(BGNEnvironment*)env {
    if([bind isKindOfClass:[BGNVarBinding class]]) {
        BGNVarBinding* var = (BGNVarBinding*)bind;
        return [env bindExpVar:var.name withValue:arg];
    }
    else if([bind isKindOfClass:[BGNRecordBinding class]]) {
        NSAssert([arg isKindOfClass:[BGNValueRecord class]], @"StaticError: binding non-record %@ to record argument %@", arg, bind);
        BGNRecordBinding* recordBinder = (BGNRecordBinding*)bind;
        BGNValueRecord* recordValue = (BGNValueRecord*)arg;
        for(BGNRecordBindingField* bindingField in recordBinder.fields) {
            NSUInteger index = [recordValue.fields indexOfObjectPassingTest:^BOOL(BGNValueRecordField* valueField, NSUInteger idx, BOOL *stop) {
                return [valueField.name isEqualToString:bindingField.name];
            }];
            if(index == NSNotFound) {
                NSAssert(bindingField.defaultValue != nil, @"StaticError: Missing field in binding %@ of argument %@", bind, arg);
                id <BGNValue> defaultValue = [self evaluateExp:bindingField.defaultValue inEnvironment:env];
                return [env bindExpVar:bindingField.name withValue:defaultValue];
            }
            else {
                BGNValueRecordField* valueField = recordValue.fields[index];
                env = [env bindExpVar:bindingField.name withValue:valueField.value];
            }
        }
        return env;
    }
    else {
        NSAssert(NO, @"Unexpected binding argument type: %@", bind);
        return env;
    }
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
            NSAssert(NO, @"StaticError: Expecting Bool for if condition, found %@", value);
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
            NSAssert([inj.value isKindOfClass:[BGNValueRecord class]], @"StaticError: Projecting %@ from datatype without record body: %@", proj.proj, inj);
            return [self fieldNamed:proj.proj inRecord:(BGNValueRecord*)inj.value];
        }
        // 3. external object
        else if([body isKindOfClass:[BGNValueExternalObject class]]) {
            BGNValueExternalObject* object = (BGNValueExternalObject*)body;
            return [self callExternalMethodNamed:proj.proj onObject:object args:@[]];
        }
        else {
            NSAssert(NO, @"StaticError: Projection '%@' from unexpected value type %@", proj.proj, body);
            return nil;
        }
    };
    visitor.applicationBlock = ^id <BGNValue> (BGNExpApp* app) {
        id <BGNValue> function = [self evaluateExp:app.function inEnvironment:env];
        id <BGNValue> arg = [self evaluateExp:app.argument inEnvironment:env];
        // Two cases
        // 1. Actual function
        if([function isKindOfClass:[BGNValueFunction class]]) {
            BGNValueFunction* f = (BGNValueFunction*)function;
            NSAssert(f.vars.count > 0, @"function with no arguments getting applied", app);
            id <BGNBindingArgument> binder = f.vars[0];
            BGNEnvironment* e = [self bindArgument:binder toValue:arg inEnvironment:env];
            if(f.vars.count == 1) {
                return [self evaluateExp:f.body inEnvironment:e];
            }
            else {
                return [BGNValueFunction makeThen:^(BGNValueFunction* result) {
                    result.body = f.body;
                    result.vars = [f.vars subarrayWithRange:NSMakeRange(1, f.vars.count - 1)];
                    result.env = e;
                }];
            }
        }
        // 2. External object
        if([function isKindOfClass:[BGNValueExternalObject class]]) {
            BGNValueExternalObject* object = (BGNValueExternalObject*)function;
            NSAssert([arg isKindOfClass:[BGNValueRecord class]], @"StaticError: Calling external method with non record argument %@", arg);
            BGNValueRecord* record = (BGNValueRecord*)arg;
            NSString* selector = [[record.fields map:^(BGNValueRecordField* field) {
                return [NSString stringWithFormat:@"%@:",field.name];
            }] componentsJoinedByString:@""];
            
            NSArray* args = [record.fields map:^(BGNValueRecordField* field) {
                return field.value;
            }];
            return [self callExternalMethodNamed:selector onObject:object args:args];
        }
        else {
            NSAssert(NO, @"StaticError: Unexpected value in function position: %@", function);
            return nil;
        }
        
    };
    visitor.primopBlock = ^(BGNExpPrimOp* primOp) {
        NSArray* args = [primOp.args map:^(id <BGNExpression> e) {
            return [self evaluateExp:e inEnvironment:env];
        }];
        return [self evaluatePrimop:primOp.name args:args];
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

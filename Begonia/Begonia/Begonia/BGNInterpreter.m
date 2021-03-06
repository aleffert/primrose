//
//  BGNInterpreter.m
//  Begonia
//
//  Created by Akiva Leffert on 9/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNInterpreter.h"

#import "BGNCocoaRouter.h"
#import "BGNExpVisitor.h"
#import "BGNEnvironment.h"
#import "BGNLang.h"
#import "BGNPatternVisitor.h"
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

@property (strong, nonatomic) BGNModuleManager* moduleManager;
@property (strong, nonatomic) BGNEnvironment* environment;

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

- (id <BGNModuleLoader>)moduleLoader {
    return self.moduleManager;
}

- (void)interpretFile:(NSString*)path {
    NSString* name = path.lastPathComponent.stringByDeletingPathExtension.capitalizedString;
    [self.moduleManager loadModuleNamed:name atPath:path];
//    NSLog(@"the value of x is %@", [self.environment valueNamed:@"x" inModule:@"Test"]);
}

- (void)importModuleNamed:(NSString*)name bindings:(NSDictionary*)bindings {
    self.environment = [self.environment scopeModuleNamed:name inBody:^BGNEnvironment *(BGNEnvironment *env) {
        __block BGNEnvironment* result = env;
        [bindings enumerateKeysAndObjectsUsingBlock:^(NSString* key, id obj, BOOL *stop) {
            result = [env bindExpVar:key withValue:[self valueForCocoaObject:obj]];
        }];
        return result;
    }];
}

- (id)objectNamed:(NSString*)name inModule:(NSString *)module {
    id <BGNValue> value = [self.environment valueNamed:name inModule:module];
    if([value isKindOfClass:[BGNValueExternalObject class]]) {
        return ((BGNValueExternalObject*)value).object;
    }
    return nil;
}

- (id <BGNValue>)unitValue {
    return [BGNValueRecord makeThen:^(BGNValueRecord* record) {
        record.fields = @[];
    }];
}

- (id <BGNValue>)evaluatePrimop:(NSString*)name args:(NSArray*)args {
    return [BGNPrimops evaluatePrimop:name args:args inInterpreter:self];
}

- (BGNEnvironment*)matchPattern:(id <BGNPattern>)pattern againstValue:(id <BGNValue>)value inEnvironment:(BGNEnvironment*)env {
    BGNPatternBlockVisitor* visitor = [[BGNPatternBlockVisitor alloc] init];
    visitor.varBlock = ^(BGNPatternVar* var) {
        return [env bindExpVar:var.name withValue:value];
    };
    visitor.intBlock = ^BGNEnvironment*(BGNPatternInt* pat) {
        if([value isKindOfClass:[BGNValueInt class]]) {
            BGNValueInt* i = (BGNValueInt*)value;
            if(i.value == pat.value) {
                return env;
            }
            else {
                return nil;
            }
        }
        else {
            return nil;
        }
    };
    
    visitor.stringBlock = ^BGNEnvironment*(BGNPatternString* pat) {
        if([value isKindOfClass:[BGNValueString class]]) {
            BGNValueString* s = (BGNValueString*)value;
            if([s.value isEqualToString:pat.value]) {
                return env;
            }
            else {
                return nil;
            }
        }
        else {
            return nil;
        }
    };
    
    visitor.boolBlock = ^BGNEnvironment*(BGNPatternBool* pat) {
        if([value isKindOfClass:[BGNValueBool class]]) {
            BGNValueBool* b = (BGNValueBool*)value;
            if(b.value == pat.value) {
                return env;
            }
            else {
                return nil;
            }
        }
        else {
            return nil;
        }
    };
    
    visitor.constructorBlock = ^BGNEnvironment*(BGNPatternConstructor* pat) {
        if([value isKindOfClass:[BGNValueConstructor class]]) {
            BGNValueConstructor* c = (BGNValueConstructor*)value;
            if([c.name isEqualToString:pat.constructor]) {
                return [self matchPattern:pat.body againstValue:c.value inEnvironment:env];
            }
            else {
                return nil;
            }
        }
        else {
            return nil;
        }
    };
    
    visitor.recordBlock = ^BGNEnvironment*(BGNPatternRecord* pat) {
        if([value isKindOfClass:[BGNValueRecord class]]) {
            BGNValueRecord* record = (BGNValueRecord*)value;
            BGNEnvironment* result = env;
            for(BGNPatternRecordField* field in pat.fields) {
                id <BGNValue> value = [self fieldNamed:field.name inRecord:record];
                if(value == nil) {
                    return nil;
                }
                else {
                    result = [self matchPattern:field.body againstValue:value inEnvironment:result];
                    if(result == nil) {
                        return nil;
                    }
                }
            }
            return result;
        }
        else {
            return nil;
        }
    };
    
    return [pattern acceptVisitor:visitor];
}

- (id <BGNValue>)valueForCocoaObject:(id)object {
    
    if([object isKindOfClass:[NSString class]]) {
        return [BGNValueString makeThen:^(BGNValueString* s) {
            s.value = object;
        }];
    }
    else {
        return [BGNValueExternalObject externWithObject:object];
    }
}

- (id <BGNValue>)callExternalMethodNamed:(NSString*)name onObject:(id)object args:(NSArray*)arguments {
    SEL selector = NSSelectorFromString(name);
    NSMethodSignature* signature = [object methodSignatureForSelector:selector];
    NSAssert(signature != nil, @"DynamicError: Couldn't find selector %@ on %@", name, object);
    NSAssert(signature.numberOfArguments == arguments.count + 2, @"FFIError: Selector %@ argumentCount didn't match arguments %@", name, arguments);
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:object];
    [invocation setSelector:selector];
    for(NSUInteger i = 2; i < signature.numberOfArguments; i++) {
        const char* argType = [signature getArgumentTypeAtIndex:i];
        id <BGNValue> value = arguments[i - 2];
        if(!strcmp(argType, @encode(CGFloat))) {
            NSAssert([value isKindOfClass:[BGNValueFloat class]], @"FFIError: Passing %@ to ffi call expecting float named %@", value, name);
            BGNValueFloat* wrappedV = (BGNValueFloat*)value;
            CGFloat v = wrappedV.value;
            [invocation setArgument:&v atIndex:i];
        }
        else if(!strcmp(argType, @encode(NSUInteger)) || !strcmp(argType, @encode(NSInteger))) {
            NSAssert([value isKindOfClass:[BGNValueInt class]], @"FFIError: Passing %@ to ffi call expecting int named %@", value, name);
            BGNValueInt* wrappedV = (BGNValueInt*)value;
            NSInteger v = wrappedV.value;
            [invocation setArgument:&v atIndex:i];
        }
        else if(!strcmp(argType, @encode(BOOL))) {
            NSAssert([value isKindOfClass:[BGNValueBool class]], @"FFIError: Passing %@ to ffi call expecting bool named %@", value, name);
            BGNValueBool* wrappedV = (BGNValueBool*)value;
            BOOL v = wrappedV.value;
            [invocation setArgument:&v atIndex:i];
        }
        else if(!strcmp(argType, @encode(CGPoint))) {
            NSAssert([value isKindOfClass:[BGNValueConstructor class]], @"FFIError: Expecting Point calling out to CGPoint FFI argument method %@, argument %@", name, value);
            BGNValueConstructor* data = (BGNValueConstructor*)value;
            NSAssert([data.value isKindOfClass:[BGNValueRecord class]], @"FFIError: Expecting datatype with record body coercing to CGPoint. Found %@ for method", data.value, name);
            BGNValueRecord* body = (BGNValueRecord*)data.value;
            id <BGNValue> xField = [self fieldNamed:@"x" inRecord:body];
            id <BGNValue> yField = [self fieldNamed:@"y" inRecord:body];
            NSAssert(xField != nil, @"FFIError: Unable to find field x in %@", body);
            NSAssert(yField != nil, @"FFIError: Unable to find field y in %@", body);
            NSAssert([xField isKindOfClass:[BGNValueFloat class]], @"FFIError: Expecting float arguments to method %@ expecting CGPoint", name);
            CGFloat x = ((BGNValueFloat*)xField).value;
            CGFloat y = ((BGNValueFloat*)yField).value;
            CGPoint v = CGPointMake(x, y);
            [invocation setArgument:&v atIndex:i];
        }
        else if(!strcmp(argType, @encode(CGRect))) {
            NSAssert([value isKindOfClass:[BGNValueConstructor class]], @"FFIError: Expecting Rect calling out to CGPoint FFI argument method %@, argument %@", name, value);
            BGNValueConstructor* data = (BGNValueConstructor*)value;
            NSAssert([data.value isKindOfClass:[BGNValueRecord class]], @"FFIError: Expecting datatype with record body coercing to CGRect. Found %@ for method", data.value, name);
            BGNValueRecord* body = (BGNValueRecord*)data.value;
            id <BGNValue> xField = [self fieldNamed:@"x" inRecord:body];
            id <BGNValue> yField = [self fieldNamed:@"y" inRecord:body];
            id <BGNValue> widthField = [self fieldNamed:@"width" inRecord:body];
            id <BGNValue> heightField = [self fieldNamed:@"height" inRecord:body];
            NSAssert(xField != nil, @"FFIError: Unable to find field x in %@", body);
            NSAssert(yField != nil, @"FFIError: Unable to find field y in %@", body);
            NSAssert(widthField != nil, @"FFIError: Unable to find field width in %@", body);
            NSAssert(heightField != nil, @"FFIError: Unable to find field height in %@", body);
            NSAssert([xField isKindOfClass:[BGNValueFloat class]], @"FFIError: Expecting float arguments to method %@ expecting CGRect", name);
            CGFloat x = ((BGNValueFloat*)xField).value;
            CGFloat y = ((BGNValueFloat*)yField).value;
            CGFloat width = ((BGNValueFloat*)widthField).value;
            CGFloat height = ((BGNValueFloat*)heightField).value;
            CGRect v = CGRectMake(x, y, width, height);
            [invocation setArgument:&v atIndex:i];
        }
        else if(!strcmp(argType, @encode(id))) {
            if([value isKindOfClass:[BGNValueString class]]) {
                NSString* string = ((BGNValueString*)value).value;
                [invocation setArgument:&string atIndex:i];
            }
            else if([value isKindOfClass:[BGNValueExternalObject class]]) {
                id object = ((BGNValueExternalObject*)value).object;
                [invocation setArgument:&object atIndex:i];
            }
            else {
                NSAssert(NO, @"FFIError: Unexpected object type %@ for external method named %@", value, name);
            }
        }
        // TODO deal with blocks. UGH
    }
    [invocation retainArguments];
    [invocation invoke];
    const char* returnType = signature.methodReturnType;
    if(!strcmp(returnType, @encode(void))) {
        return [self unitValue];
    }
    else if(!strcmp(returnType, @encode(id)) || !strcmp(returnType, @encode(Class))) {
        __unsafe_unretained id result = nil;
        [invocation getReturnValue:&result];
        
        return [self valueForCocoaObject:result];
    }
    else if(!strcmp(returnType, @encode(CGFloat))) {
        CGFloat v = 0;
        [invocation getReturnValue:&v];
        return [BGNValueFloat makeThen:^(BGNValueFloat* f){
            f.value = v;
        }];
    }
    else if(!strcmp(returnType, @encode(NSInteger)) || !strcmp(returnType, @encode(NSUInteger))) {
        NSUInteger r = 0;
        [invocation getReturnValue:&r];
        return [BGNValueFloat makeThen:^(BGNValueInt* i){
            i.value = r;
        }];
    }
    else if(!strcmp(returnType, @encode(CGPoint))) {
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
    else if(!strcmp(returnType, @encode(CGRect))) {
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
    if(index == NSNotFound) {
        return nil;
    }
    else {
        BGNValueRecordField* field = record.fields[index];
        return field.value;
    }
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
            return [BGNValueFloat makeThen:^(BGNValueFloat* val) {
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
            __block BGNEnvironment* e = env;
            r.fields = [record.fields map:^(BGNExpRecordField* field) {
                return [BGNValueRecordField makeThen:^(BGNValueRecordField* resultField) {
                    resultField.name = field.name;
                    resultField.value = [self evaluateExp:field.body inEnvironment:e];
                    e = [e bindExpVar:resultField.name withValue:resultField.value];
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
            id <BGNValue> value = [self fieldNamed:proj.proj inRecord:record];
            NSAssert(value != nil, @"StaticError: Unable to find field %@ in %@", proj.proj, record);
            return value;
        }
        // 2. through a constructor
        else if([body isKindOfClass:[BGNValueConstructor class]]) {
            BGNValueConstructor* inj = (BGNValueConstructor*)body;
            NSAssert([inj.value isKindOfClass:[BGNValueRecord class]], @"StaticError: Projecting %@ from datatype without record body: %@", proj.proj, inj);
            id <BGNValue> value = [self fieldNamed:proj.proj inRecord:(BGNValueRecord*)inj.value];
            
            NSAssert(value != nil, @"StaticError: Unable to find field %@ in %@", proj.proj, (BGNValueRecord*)inj.value);
            return value;
        }
        // 3. external object
        else if([body isKindOfClass:[BGNValueExternalObject class]]) {
            BGNValueExternalObject* object = (BGNValueExternalObject*)body;
            return [self callExternalMethodNamed:proj.proj onObject:object.object args:@[]];
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
            BGNEnvironment* e = [self bindArgument:binder toValue:arg inEnvironment:f.env];
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
            return [self callExternalMethodNamed:selector onObject:object.object args:args];
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
    visitor.caseBlock = ^id <BGNValue>(BGNExpCase* matcher) {
        id <BGNValue> testValue = [self evaluateExp:matcher.test inEnvironment:env];
        for(BGNCaseArm* arm in matcher.branches) {
            BGNEnvironment* e = [self matchPattern:arm.pattern againstValue:testValue inEnvironment:env];
            if(e != nil) {
                return [self evaluateExp:arm.body inEnvironment:e];
            }
        }
        NSAssert(NO, @"StaticError: Unable to match %@ against patterns %@", testValue, matcher.branches);
        return nil;
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
        return [data.arms foldLeft:^BGNEnvironment*(BGNDatatypeArm* arm, NSUInteger index, BGNEnvironment* e) {
            BGNValueFunction* constructor = [BGNValueFunction makeThen:^(BGNValueFunction* f){
                f.vars = @[[BGNVarBinding makeThen:^(BGNVarBinding* v) {v.name = @"x";}]];
                f.body = [BGNExpConstructor makeThen:^(BGNExpConstructor* c) {
                    c.name = arm.name;
                    c.body = [BGNExpVariable makeThen:^(BGNExpVariable* v) {v.name = @"x";}];
                }];
                f.env = [BGNEnvironment empty];
            }];
            return [env bindExpVar:arm.name withValue:constructor];
        } base:env];
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
        
        if([name isEqualToString:@"Cocoa"]) {
            env = [env bindExpVar:@"classNamed" withValue:[BGNValueExternalObject externWithObject:[[BGNCocoaRouter router] classNamed]]];
        }
        
        return env;
    }];
}

@end

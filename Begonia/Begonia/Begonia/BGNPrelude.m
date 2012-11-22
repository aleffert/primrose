//
//  BGNPrelude.m
//  Begonia
//
//  Created by Akiva Leffert on 11/21/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNPrelude.h"

#import "BGNEnvironment.h"
#import "BGNLang.h"
#import "BGNValue.h"

#import "NSArray+Functional.h"
#import "NSObject+BGNConstruction.h"

NSString* BGNPreludeModuleName = @"$prelude";

@implementation BGNPrelude

+ (id <BGNValue>)primopFunctionNamed:(NSString*)name args:(NSArray*)args {
    return [BGNValueFunction makeThen:^(BGNValueFunction* lambda) {
        lambda.body = [BGNExpPrimOp makeThen:^(BGNExpPrimOp* op) {
            op.name = name;
            op.args = [args map:^(NSString* name) {
                return [BGNExpVariable makeThen:^(BGNExpVariable* v) {v.name = name;}];
            }];
            
        }];
        lambda.vars = [args map:^(NSString* name) {
            return [BGNVarBinding makeThen:^(BGNVarBinding* b) {b.name = name;}];
        }];
        lambda.env = [BGNEnvironment empty];
    }];
}

+ (id <BGNValue>)arithmeticOpNamed:(NSString*)name {
    return [self primopFunctionNamed:name args:@[@"x", @"y"]];
}

+ (id <BGNValue>)ffFunction {
    return [self primopFunctionNamed:@"$intToFloat" args:@[@"x"]];
}

+ (id <BGNValue>)negateFunction {
    return [self primopFunctionNamed:@"$UMINUS" args:@[@"x"]];
}

+ (id <BGNValue>)appFunction {
    return [BGNValueFunction makeThen:^(BGNValueFunction* lambda) {
        lambda.body = [BGNExpApp makeThen:^(BGNExpApp* app) {
            app.function = [BGNExpVariable makeThen:^(BGNExpVariable* o) {
                o.name = @"x";
            }];
            app.argument = [BGNExpVariable makeThen:^(BGNExpVariable* o) {
                o.name = @"y";
            }];
        }];
        lambda.vars = [@[@"x", @"y"] map:^(NSString* name) {
            return [BGNVarBinding makeThen:^(BGNVarBinding* b) {b.name = name;}];
        }];
        lambda.env = [BGNEnvironment empty];
    }];
}

+ (BGNEnvironment*)loadIntoEnvironment:(BGNEnvironment*)env {
    return [env scopeModuleNamed:BGNPreludeModuleName inBody:^BGNEnvironment *(BGNEnvironment *env) {
        env = [env bindExpVar:@"+" withValue:[self arithmeticOpNamed:@"+"]];
        env = [env bindExpVar:@"-" withValue:[self arithmeticOpNamed:@"-"]];
        env = [env bindExpVar:@"*" withValue:[self arithmeticOpNamed:@"*"]];
        env = [env bindExpVar:@"/" withValue:[self arithmeticOpNamed:@"/"]];
        env = [env bindExpVar:@"<" withValue:[self arithmeticOpNamed:@"<"]];
        env = [env bindExpVar:@">" withValue:[self arithmeticOpNamed:@">"]];
        env = [env bindExpVar:@"<=" withValue:[self arithmeticOpNamed:@"<="]];
        env = [env bindExpVar:@">=" withValue:[self arithmeticOpNamed:@">="]];
        env = [env bindExpVar:@"ff" withValue:[self ffFunction]];
        env = [env bindExpVar:@"$UMINUS" withValue:[self negateFunction]];
        env = [env bindExpVar:@"$" withValue:[self appFunction]];
        return env;
    }];
}

@end

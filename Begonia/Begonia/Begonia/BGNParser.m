//
//  BGNParser.m
//  Begonia
//
//  Created by Akiva Leffert on 10/2/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ParseKit.h"

#import "BGNParser.h"

#import "BGNEndOfLineTokenizerState.h"
#import "BGNLang.h"
#import "BGNParserResult.h"
#import "BGNPrecedenceParser.h"

#import "NSArray+Functional.h"
#import "NSObject+BGNConstruction.h"

@implementation PKAssembly (BGNAdditions)

- (void)pushEnumerator:(NSEnumerator*)enumerator {
    id object = nil;
    while((object = [enumerator nextObject]) != nil) {
        [self push:object];
    }
}

- (NSArray*)popWhileMatching:(BOOL (^)(id object))pred {
    NSMutableArray* array = [NSMutableArray array];
    BOOL done = NO;
    while(!self.isStackEmpty && !done) {
        id object = [self pop];
        if(pred(object)) {
            [array insertObject:object atIndex:0];
        }
        else {
            [self push:object];
            done = YES;
        }
    }
    return array;
}

- (id)popIf:(BOOL (^)(id object))pred {
    if(!self.isStackEmpty) {
        id object = [self pop];
        if(pred(object)) {
            return object;
        }
        else {
            [self push:object];
            return nil;
        }
    }
    return nil;
}

- (void)updateFrontForNullOrList {
    NSArray* fields = [self pop];
    if([fields isEqual:[NSNull null]]) {
        fields = [NSArray array];
        [self push:[NSArray array]];
    }
    else {
        [self pop];
        [self push:fields];
    }
    
}


@end

@implementation BGNParser

- (id <BGNParserResult>)parseFile:(NSString *)path {
    NSError* error = nil;
    NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if(error != nil) {
        return [BGNParserResult resultWithError:error];
    }
    
    return [self parseString:contents sourceName:path.lastPathComponent];
}

- (NSString*)grammarPath {
    return [[NSBundle mainBundle] pathForResource:@"begonia" ofType:@"grammar"];
}

- (id <BGNParserResult>)parseString:(NSString *)string sourceName:(NSString *)sourceName {
    NSString* grammarString = [NSString stringWithContentsOfFile:self.grammarPath encoding:NSUTF8StringEncoding error:nil];
    
    PKParser* moduleParser = [[PKParserFactory factory] parserFromGrammar:grammarString assembler:self];
    PKTokenizer* tokenizer = moduleParser.tokenizer;
    PKTokenizerState* eolState = [[BGNEndOfLineTokenizerState alloc] init];

    [tokenizer setTokenizerState:eolState from:'\n' to:'\n' + 1];

    
    BGNModule* module = [moduleParser parse:string];
    
    NSLog(@"got a module: imports = %@, topDecls= %@", module.imports, module.declarations);
    
    return [BGNParserResult resultWithModule:module];
}

#pragma mark Module

- (void)parser:(PKParser*)parser didMatchModule:(PKAssembly*)a {
    NSArray* topDecls = [a pop];
    NSArray* imports = [a pop];
    BGNModule* module = [[BGNModule alloc] init];
    module.imports = imports;
    module.declarations = topDecls;
    [a push:module];
}

- (void)parser:(PKParser*)parser didMatchImports:(PKAssembly*)a {
    NSArray* imports = [a popWhileMatching:^(id object) {
        return [object isKindOfClass:[BGNImport class]];
    }];
    [a push:imports];
}


- (void)parser:(PKParser*)parser didMatchImport:(PKAssembly*)a {
    PKToken* name = [a pop];
    BGNImport* import = [[BGNImport alloc] init];
    import.name = [name stringValue];
    [a push:import];
}

#pragma mark General

- (void)parser:(PKParser*)parser didMatchNullOpt:(PKAssembly*)a {
    [a push:[NSNull null]];
}

- (void)parser:(PKParser*)parser didMatchScope:(PKAssembly*)a {
    PKToken* scope = [a pop];
    if([scope.stringValue isEqualToString:@"local"]) {
        [a push:[NSNumber numberWithInt:BGNScopeLocal]];
    }
    else {
        [a push:[NSNumber numberWithInt:BGNScopeLet]];
    }
}

- (BGNPrecedenceParser*)precedenceParser {
    NSDictionary* unaryOperators = @{@"-" : @5};
    NSDictionary* binaryOperators = @{@"+" : @2, @"-" : @2, @"$" : @1, @"*" : @3, @"/" : @4};
    
    return [BGNPrecedenceParser makeThen:^(BGNPrecedenceParser* parser) {
        parser.unOp = ^(BGNPrecedenceTokenOp* token, id arg) {
            return [BGNExpApp makeThen:^(BGNExpApp* app) {
                app.function = token.value;
                app.argument = arg;
            }];
        };
        parser.binOp = ^(BGNPrecedenceTokenOp* token, id arg1, id arg2) {
            if([token isKindOfClass:[BGNPrecedenceTokenJuxtapose class]]) {
                return [BGNExpApp makeThen:^(BGNExpApp* app) {
                    app.function = arg1;
                    app.argument = arg2;
                }];
            }
            return [BGNExpApp makeThen:^(BGNExpApp* app1) {
                app1.function = [BGNExpApp makeThen:^(BGNExpApp* app2) {
                    app2.function = token.value;
                    app2.argument = arg1;
                }];
                app1.argument = arg2;
            }];
        };
        parser.getAssoc = ^BGNAssociativity(BGNPrecedenceTokenOp* token) {
            if([token isKindOfClass:[BGNPrecedenceTokenJuxtapose class]]) {
                return BGNAssociativityLeft;
            }
            else {
                BGNExpVariable* var = token.value;
                return [var.name isEqualToString:@"-"] && token.isUnary ? BGNAssociativityRight : BGNAssociativityLeft;
            }
        };
        parser.getPrecedence = ^NSUInteger(BGNPrecedenceTokenOp* token) {
            if([token isKindOfClass:[BGNPrecedenceTokenJuxtapose class]]) {
                return 1;
            }
            else {
                BGNExpVariable* var = token.value;
                return [token.isUnary ? unaryOperators[var.name] : binaryOperators[var.name] unsignedIntegerValue];   
            }
        };
    }];
}

#pragma mark TopDecls

- (void)parser:(PKParser*)parser didMatchTopDecls:(PKAssembly*)a {
    NSArray* topDecls = [a popWhileMatching:^(id object) {
        return [object conformsToProtocol:@protocol(BGNTopLevelDeclaration)];
    }];
    [a push:topDecls];
}

- (void)parser:(PKParser*)parser didMatchTopDeclExternalType:(PKAssembly*)a {
    PKToken* token = [a pop];
    BGNExternalTypeDeclaration* decl = [[BGNExternalTypeDeclaration alloc] init];
    decl.name = token.stringValue;
    [a push:decl];
}

- (void)parser:(PKParser*)parser didMatchTopDeclValBinding:(PKAssembly*)a {
    id <BGNExpression> body = [a pop];
    NSString* name = [[a pop] stringValue];
    BGNScope scope = [[a pop] intValue];
    BGNScopedValueBinding* binding = [[BGNScopedValueBinding alloc] init];
    binding.scope = scope;
    binding.name = name;
    binding.body = body;
    [a push:binding];
}

#pragma mark Exp

- (void)parser:(PKParser*)parser didMatchExp:(PKAssembly*)a {
    NSArray* items = [a popWhileMatching:^BOOL(id t) {
        return [t conformsToProtocol:@protocol(BGNExpression)];
    }];
    NSArray* tokens = [items map:^(id <BGNExpression> exp) {
        // TODO Check if expvar and is an operator
        if([exp isKindOfClass:[BGNExpVariable class]] && ((BGNExpVariable*)exp).name.isOperatorSymbol) {
            BGNExpVariable* var = (BGNExpVariable*)exp;
            return [BGNPrecedenceTokenOp makeThen:^(BGNPrecedenceTokenOp* op) {
                op.value = var;
            }];
        }
        else {
            return [BGNPrecedenceTokenAtom makeThen:^(BGNPrecedenceTokenAtom* atom) {
                atom.value = exp;
            }];
        }
    }];
    
    BGNPrecedenceParser* precedenceParser = [self precedenceParser];
    
    id <BGNExpression> result = [precedenceParser parseTokens:tokens];
    [a push:result];
}


- (void)parser:(PKParser*)parser didMatchExpNum:(PKAssembly*)a {
    PKToken* number = [a pop];
    BGNExpNumber* result = [[BGNExpNumber alloc] init];
    result.value = [NSNumber numberWithFloat:number.floatValue];
    result.isFloat = YES;
    [a push:result];
}

- (void)parser:(PKParser*)parser didMatchExpVar:(PKAssembly*)a {
    PKToken* token = [a pop];
    BGNExpVariable* var = [[BGNExpVariable alloc] init];
    var.name = token.stringValue;
    [a push:var];
}

- (void)parser:(PKParser*)parser didMatchExternalMethod:(PKAssembly*)a {
    id <BGNType> type = [a pop];
    id <BGNExpression> argument = [a pop];
    id <BGNExpression> exp = [a pop];
    BGNExpExternalMethod* call = [[BGNExpExternalMethod alloc] init];
    call.base = exp;
    call.argument = argument;
    call.resultType = type;
    [a push:call];
}

- (void)parser:(PKParser*)parser didMatchTopDeclFunBinding:(PKAssembly*)a {
    id <BGNExpression> body = [a pop];
    NSArray* bindingArguments = [a pop];
    NSString* ident = [[a pop] stringValue];
    BGNScope scope = [[a pop] intValue];
    BGNScopedFunctionBinding* binding = [[BGNScopedFunctionBinding alloc] init];
    binding.body = body;
    binding.arguments = bindingArguments;
    binding.name = ident;
    binding.scope = scope;
    [a push:binding];
}

- (void)parser:(PKParser*)parser didMatchExpLambda:(PKAssembly*)a {
    id <BGNExpression> body = [a pop];
    NSArray* bindingArguments = [a pop];
    BGNExpLambda* lam = [[BGNExpLambda alloc] init];
    lam.arguments = bindingArguments;
    lam.body = body;
    [a push:lam];
}

- (void)parser:(PKParser*)parser didMatchBindingArgument:(PKAssembly*)a {
    NSArray* arguments = [a popWhileMatching:^(id object) {
        return [object conformsToProtocol:@protocol(BGNBindingArgument)];
    }];
    [a push:arguments];
}

- (void)parser:(PKParser*)parser didMatchVarBinding:(PKAssembly*)a {
    id <BGNTypeArgument> type = [a pop];
    NSString* name = [[a pop] stringValue];
    BGNVarBinding* binding = [[BGNVarBinding alloc] init];
    binding.name = name;
    binding.argumentType = type;
    [a push: binding];
}

- (void)parser:(PKParser*)parser didMatchRecordBinding:(PKAssembly*)a {
    NSArray* fields = [a pop];
    BGNRecordBinding* binding = [[BGNRecordBinding alloc] init];
    binding.fields = fields;
    [a push:binding];
}

- (void)parser:(PKParser*)parser didMatchRecordBindingFieldsOpt:(PKAssembly*)a {
    [a updateFrontForNullOrList];
}

- (void)parser:(PKParser*)parser didMatchDefaultValueOpt:(PKAssembly*)a {
    id <BGNExpression> defaultValue = [a pop];
    if(![defaultValue isEqual:[NSNull null]]) {
        [a pop];
    }
    [a push:defaultValue];
}

- (void)parser:(PKParser*)parser didMatchRecordBindingFields:(PKAssembly *)a {
    NSArray* items = [a popWhileMatching:^(id object) {
        return [object isKindOfClass:[BGNRecordBindingField class]];
    }];
    [a push:items];
}

- (void)parser:(PKParser*)parser didMatchRecordBindingField:(PKAssembly *)a {
    id <BGNExpression> defaultValue = [a pop];
    if([defaultValue isEqual:[NSNull null]]) {
        defaultValue = nil;
    }
    id <BGNTypeArgument> type = [a pop];
    NSString* name = [[a pop] stringValue];
    BGNRecordBindingField* field = [[BGNRecordBindingField alloc] init];
    field.name = name;
    field.type = type;
    field.defaultValue = defaultValue;
    [a push:field];
}

- (void)parser:(PKParser*)parser didMatchExpRecord:(PKAssembly*)a {
    NSArray* fields = [a pop];
    BGNExpRecord* record = [[BGNExpRecord alloc] init];
    record.fields = fields;
    [a push:record];
}

- (void)parser:(PKParser*)parser didMatchExpRecordFieldsOpt:(PKAssembly *)a {
    [a updateFrontForNullOrList];
}

- (void)parser:(PKParser*)parser didMatchExpRecordFields:(PKAssembly *)a {
    NSArray* items = [a popWhileMatching:^(id object) {
        return [object isKindOfClass:[BGNExpRecordField class]];
    }];
    [a push:items];
}

- (void)parser:(PKParser*)parser didMatchExpRecordField:(PKAssembly*)a {
    id <BGNExpression> body = [a pop];
    NSArray* arguments = [a popIf:^(id object) {
        return [object isKindOfClass:[NSArray class]];
    }];
    if(arguments != nil) {
        BGNExpLambda* lam = [[BGNExpLambda alloc] init];
        lam.body = body;
        lam.arguments = arguments;
        body = lam;
    }
    NSString* name = [[a pop] stringValue];
    BGNExpRecordField* field = [[BGNExpRecordField alloc] init];
    field.name = name;
    field.body = body;
    [a push:field];
}

#pragma mark Statements

- (void)parser:(PKParser*)parser didMatchExpStmt:(PKAssembly*)a {
    NSArray* stmts = [a popWhileMatching:^(id object) {
        return [object conformsToProtocol:@protocol(BGNStatement)];
    }];
    BGNExpStmts* exp = [[BGNExpStmts alloc] init];
    exp.statements = stmts;
    [a push:exp];
}

- (void)parser:(PKParser*)parser didMatchStmtExp:(PKAssembly*)a {
    id <BGNExpression> exp = [a pop];
    BGNStmtExp* stmt = [[BGNStmtExp alloc] init];
    stmt.exp = exp;
    [a push:stmt];
}

- (void)parser:(PKParser*)parser didMatchStmtBind:(PKAssembly*)a {
    id <BGNExpression> body = [a pop];
    NSArray* arguments = [a popIf:^(id object) {
        return [object isKindOfClass:[NSArray class]];
    }];
    if(arguments != nil) {
        BGNExpLambda* lam = [[BGNExpLambda alloc] init];
        lam.body = body;
        lam.arguments = arguments;
        body = lam;
    }
    NSString* name = [[a pop] stringValue];
    BGNStmtLet* let = [[BGNStmtLet alloc] init];
    let.body = body;
    let.name = name;
    [a push:let];
}

#pragma mark Types


- (void)parser:(PKParser*)parser didMatchTypeVar:(PKAssembly*)a {
    PKToken* var = [a pop];
    BGNTypeVariable* tyVar = [[BGNTypeVariable alloc] init];
    tyVar.name = var.stringValue;
    [a push:tyVar];
}

- (void)parser:(PKParser*)parser didMatchTypeArgumentType:(PKAssembly*)a {
    id <BGNType> type = [a pop];
    BGNTypeArgumentType* arg = [[BGNTypeArgumentType alloc] init];
    arg.type = type;
    [a push:type];
}


@end

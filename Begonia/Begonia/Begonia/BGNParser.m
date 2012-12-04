//
//  BGNParser.m
//  Begonia
//
//  Created by Akiva Leffert on 10/2/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//


#import "BGNParser.h"

#import <ParseKit/ParseKit.h>
#import <ParseKit/PKParserFactory.h>

#import "BGNEndOfLineTokenizerState.h"
#import "BGNLang.h"
#import "BGNParserResult.h"
#import "BGNPrecedenceParser.h"

#import "NSArray+Functional.h"
#import "NSObject+BGNConstruction.h"

static NSString* BGNParserErrorDomain = @"BGNParserErrorDomain";

@interface BGNPathToken : NSObject

@property (retain, nonatomic) NSString* name;

@end

@implementation BGNPathToken

@end

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
        [self popIf:^BOOL(id object) {return [object isKindOfClass:[NSNull class]];}];
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
    
    NSError* error = nil;
    PKParser* moduleParser = [[PKParserFactory factory] parserFromGrammar:grammarString assembler:self error:&error];
    NSAssert(error == nil, @"Error reading grammar %@", error);
    
    PKTokenizer* tokenizer = moduleParser.tokenizer;
    tokenizer.numberState.allowsFloatingPoint = YES;
    
    PKTokenizerState* eolState = [[BGNEndOfLineTokenizerState alloc] init];
    [tokenizer setTokenizerState:eolState from:'\n' to:'\n' + 1];
    
    // The grammar requires a new line after the last statement, so stick one in at the end
    // So we don't require an extra line at the end of inputs
    NSString* processedString = [string stringByAppendingString:@"\n"];

    BGNModule* module = [moduleParser parse:processedString error:&error];
    
    if(module == nil || error != nil) {
        return [BGNParserResult resultWithError:error];
    }
    else {
        return [BGNParserResult resultWithModule:module];
    }
    
}

- (void)parser:(PKParser*)parser didMatchIdent:(PKAssembly*)a {
    PKToken* token = [a pop];
    [a push:token];
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
    PKToken* kind = [a pop];
    BGNImport* import = [[BGNImport alloc] init];
    import.name = [name stringValue];
    import.open = [kind.stringValue isEqualToString:@"open"];
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

- (BGNPrecedenceParser*)expPrecedenceParser {
    NSDictionary* unaryOperators = @{@"-" : @5};
    NSDictionary* binaryOperators = @{@"+" : @2, @"-" : @2, @"$" : @1, @"*" : @3, @"/" : @4};
    
    return [BGNPrecedenceParser makeThen:^(BGNPrecedenceParser* parser) {
        parser.unOp = ^(BGNPrecedenceTokenOp* token, id arg) {
            if([arg isKindOfClass:[BGNExpVariable class]]) {
                BGNExpVariable* argExp = (BGNExpVariable*)arg;
                if([argExp.name isEqualToString:@"-"]) {
                    argExp.name = @"$UMINUS";
                }
            }
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
    [a pop];
    NSString* name = [[a pop] stringValue];
    BGNScope scope = [[a pop] intValue];
    BGNScopedExpBinding* binding = [[BGNScopedExpBinding alloc] init];
    binding.scope = scope;
    binding.name = name;
    binding.body = body;
    [a push:binding];
}

- (void)parser:(PKParser*)parser didMatchTopDeclFunBinding:(PKAssembly*)a {
    id <BGNExpression> body = [a pop];
    [a pop];
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

- (void)parser:(PKParser*)parser didMatchDatatypeArm:(PKAssembly*)a {
    BGNDatatypeArm* arm = [[BGNDatatypeArm alloc] init];
    arm.type = [a pop];
    arm.name = [[a pop] stringValue];
    [a push:arm];
}

- (void)parser:(PKParser*)parser didMatchDatatypeArms:(PKAssembly *)a {
    NSArray* items = [a popWhileMatching:^BOOL(id item) {
        return [item isKindOfClass:[BGNDatatypeArm class]];
    }];
    [a push:items];
}

- (void)parser:(PKParser*)parser didMatchTopDeclTypeBinding:(PKAssembly*) a {
    BGNDatatypeBinding* binding = [[BGNDatatypeBinding alloc] init];
    binding.arms = [a pop];
    binding.name = [a pop];
    [a push:binding];
}

- (void)parser:(PKParser*)parser didMatchTopDeclExp:(PKAssembly*)a {
    id <BGNExpression> exp = [a pop];
    [a push:[BGNTopExpression makeThen:^(BGNTopExpression* e) {
        e.expression = exp;
    }]];
}

#pragma mark Exp

- (void)parser:(PKParser*)parser didMatchPathItem:(PKAssembly*)a {
    PKToken* readToken = [a pop];
    [a push:[BGNPathToken makeThen:^(BGNPathToken* token) {
        token.name = readToken.stringValue;
    }]];
}

- (void)parser:(PKParser*)parser didMatchProjections:(PKAssembly*)a {
    NSArray* items = [a popWhileMatching:^BOOL(id t) {
        return [t isKindOfClass:[BGNPathToken class]];
    }];
    [a push:items];
}

- (void)parser:(PKParser*)parser didMatchPath:(PKAssembly*)a {
    NSArray* projections = [a pop];
    id <BGNExpression> exp = [a pop];
    if([exp isKindOfClass:[BGNExpVariable class]] && projections.count > 0) {
        // Check for a module access
        BGNExpVariable* var = exp;
        if([var.name rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location == 0) {
            BGNPathToken* accessedField = [projections objectAtIndex:0];
            projections = [projections subarrayWithRange:NSMakeRange(1, projections.count - 1)];
            exp = [BGNExpModuleProj makeThen:^(BGNExpModuleProj* proj) {
                proj.moduleName = var.name;
                proj.proj = accessedField.name;
            }];
        }
    }
    
    id <BGNExpression> result = [projections foldLeft:^id(BGNPathToken* proj, NSUInteger index, id <BGNExpression> acc) {
        return [BGNExpProj makeThen:^(BGNExpProj* output) {
            output.base = acc;
            output.proj = proj.name;
        }];
    } base:exp];
    [a push:result];
}

- (void)parser:(PKParser*)parser didMatchExp:(PKAssembly*)a {
    id <BGNType> checkAgainst = [a pop];
    if(![checkAgainst isKindOfClass:[NSNull class]]) {
        [a pop];
    }
    
    NSArray* items = [a popWhileMatching:^BOOL(id t) {
        return [t conformsToProtocol:@protocol(BGNExpression)];
    }];
    NSArray* tokens = [items map:^(id <BGNExpression> exp) {
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
    
    BGNPrecedenceParser* precedenceParser = [self expPrecedenceParser];
    
    id <BGNExpression> result = [precedenceParser parseTokens:tokens];
    if(![checkAgainst isKindOfClass:[NSNull class]]) {
        result = [BGNExpCheck makeThen:^(BGNExpCheck* check) {
            check.body = result;
            check.type = checkAgainst;
        }];
    }
    [a push:result];
}


- (void)parser:(PKParser*)parser didMatchExpNum:(PKAssembly*)a {
    PKToken* number = [a pop];
    if([number.stringValue rangeOfString:@"."].location == NSNotFound) {
        BGNExpNumber* result = [[BGNExpNumber alloc] init];
        result.isFloat = NO;
        result.value = [NSNumber numberWithFloat:number.stringValue.integerValue];
        [a push:result];
    }
    else {
        BGNExpNumber* result = [[BGNExpNumber alloc] init];
        result.isFloat = YES;
        result.value = [NSNumber numberWithFloat:number.floatValue];
        [a push:result];
    }
}

- (void)parser:(PKParser*)parser didMatchExpString:(PKAssembly*)a {
    PKToken* string = [a pop];
    BGNExpString* result = [[BGNExpString alloc] init];
    result.value = string.quotedStringValue;
    [a push:result];
}

- (void)parser:(PKParser*)parser didMatchExpVar:(PKAssembly*)a {
    PKToken* token = [a pop];
    BGNExpVariable* var = [[BGNExpVariable alloc] init];
    var.name = token.stringValue;
    [a push:var];
}

- (void)parser:(PKParser*)parser didMatchExpLambda:(PKAssembly*)a {
    id <BGNExpression> body = [a pop];
    NSArray* bindingArguments = [a pop];
    BGNExpLambda* lam = [[BGNExpLambda alloc] init];
    lam.arguments = bindingArguments;
    lam.body = body;
    [a push:lam];
}

- (void)parser:(PKParser*)parser didMatchBindingArguments:(PKAssembly*)a {
    NSArray* arguments = [a popWhileMatching:^(id object) {
        return [object conformsToProtocol:@protocol(BGNBindingArgument)];
    }];
    [a push:arguments];
}

- (void)parser:(PKParser*)parser didMatchVarBinding:(PKAssembly*)a {
    id <BGNType> type = [a pop];
    NSString* name = [[a pop] stringValue];
    BGNVarBinding* binding = [[BGNVarBinding alloc] init];
    binding.name = name;
    binding.type = type;
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
    id <BGNType> type = [a pop];
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

- (void)parser:(PKParser*)parser didMatchExpCase:(PKAssembly*)a {
    [a pop];
    NSArray* branches = [a popWhileMatching:^BOOL(id object) {
        return [object isKindOfClass:[BGNCaseArm class]];
    }];
    id <BGNExpression> test = [a pop];
    [a pop];
    [a push: [BGNExpCase makeThen:^(BGNExpCase* o) {
        o.branches = branches;
        o.test = test;
    }]];
}

- (void)parser:(PKParser*)parser didMatchCaseClause:(PKAssembly*)a {
    id <BGNExpression> body = [a pop];
    [a pop];
    id <BGNPattern> pattern = [a pop];
    [a pop];
    [a push: [BGNCaseArm makeThen:^(BGNCaseArm* arm) {
        arm.body = body;
        arm.pattern = pattern;
    }]];
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
    NSArray* arguments = [a popWhileMatching:^BOOL(id object) {
        return [object conformsToProtocol:@protocol(BGNBindingArgument)];
    }];
    if(arguments.count > 0) {
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

- (void)parser:(PKParser*)parser didMatchExpIf:(PKAssembly*)a {
    BGNExpIfThenElse* cond = [[BGNExpIfThenElse alloc] init];
    cond.elseCase = [a pop];
    [a pop];
    cond.thenCase = [a pop];
    [a pop];
    cond.condition = [a pop];
    [a pop];
    [a push:cond];
}

#pragma mark Statements

- (void)parser:(PKParser*)parser didMatchExpStmt:(PKAssembly*)a {
    id <BGNExpression> lastExp = [a pop];
    NSArray* stmts = [a popWhileMatching:^(id object) {
        return [object conformsToProtocol:@protocol(BGNStatement)];
    }];
    BGNExpStmts* exp = [[BGNExpStmts alloc] init];
    exp.statements = [stmts arrayByAddingObject:[BGNStmtExp makeThen:^(BGNStmtExp* o) {
        o.exp = lastExp;
    }]];
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

- (BGNPrecedenceParser*)typePrecedenceParser {
    NSDictionary* unaryOperators = @{};
    NSDictionary* binaryOperators = @{@"->" : @5};
    
    return [BGNPrecedenceParser makeThen:^(BGNPrecedenceParser* parser) {
        parser.unOp = ^id <BGNType>(BGNPrecedenceTokenOp* token, id arg) {
            // TODO support type application
            NSAssert(NO, @"Unexpected unary operator in types", 0);
            return nil;
        };
        parser.binOp = ^id <BGNType>(BGNPrecedenceTokenOp* token, id arg1, id arg2) {
            if([token isKindOfClass:[BGNPrecedenceTokenJuxtapose class]]) {
                NSAssert(NO, @"Unexpected type application in types", 0);
                return nil;
            }
            else if ([token.value isKindOfClass:[BGNTypeVariable class]] && [[token.value name] isEqual:@"->"]) {
                return [BGNTypeArrow makeThen:^(BGNTypeArrow* arrow) {
                    arrow.domain = arg1;
                    arrow.codomain = arg2;
                }];
            }
            else {
                NSAssert(NO, @"Unexpected type operator %@", token.value);
                return nil;
            }
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

- (void)parser:(PKParser*)parser didMatchType:(PKAssembly*)a {
    NSArray* items = [a popWhileMatching:^BOOL(id t) {
        return [t conformsToProtocol:@protocol(BGNType)];
    }];
    NSArray* tokens = [items map:^(id <BGNType> exp) {
        if([exp isKindOfClass:[BGNTypeVariable class]] && ((BGNTypeVariable*)exp).name.isOperatorSymbol) {
            BGNTypeVariable* var = (BGNTypeVariable*)exp;
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
    
    BGNPrecedenceParser* precedenceParser = [self typePrecedenceParser];
    
    id <BGNExpression> result = [precedenceParser parseTokens:tokens];
    [a push:result];
}

- (void)parser:(PKParser*)parser didMatchTypeVar:(PKAssembly*)a {
    PKToken* var = [a pop];
    BGNTypeVariable* tyVar = [[BGNTypeVariable alloc] init];
    tyVar.name = var.stringValue;
    [a push:tyVar];
}

- (void)parser:(PKParser*)parser didMatchTypeRecord:(PKAssembly*)a {
    BGNTypeRecord* record = [[BGNTypeRecord alloc] init];
    record.fields = [a pop];
    [a push:record];
}

#pragma mark Patterns

- (void)parser:(PKParser*)parser didMatchPatVar:(PKAssembly*)a {
    PKToken* var = [a pop];
    [a push:[BGNPatternVar makeThen:^(BGNPatternVar* o) {
        o.name = var.stringValue;
    }]];
}

- (void)parser:(PKParser*)parser didMatchPatInt:(PKAssembly*)a {
    PKToken* var = [a pop];
    // TODO: properly deal with ints
    [a push:[BGNPatternInt makeThen:^(BGNPatternInt* o){
        o.value = (NSInteger)[var floatValue];
    }]];
}

- (void)parser:(PKParser*)parser didMatchPatBool:(PKAssembly*)a {
    PKToken* var = [a pop];
    [a push:[BGNPatternBool makeThen:^(BGNPatternBool* o) {
        o.value = [var.stringValue isEqualToString:@"True"];
    }]];
}

- (void)parser:(PKParser*)parser didMatchPatString:(PKAssembly*)a {
    PKToken* var = [a pop];
    [a push:[BGNPatternString makeThen:^(BGNPatternString* o){
        o.value = var.quotedStringValue;
    }]];
}

- (void)parser:(PKParser*)parser didMatchPatDatatype:(PKAssembly*)a {
    id <BGNPattern> body = [a pop];
    PKToken* name = [a pop];
    
    [a push:[BGNPatternConstructor makeThen:^(BGNPatternConstructor* o){
        o.body = body;
        o.constructor = name.stringValue;
    }]];
}

- (void)parser:(PKParser*)parser didMatchPatRecord:(PKAssembly*)a {
    NSArray* fields = [a pop];
    [a push:[BGNPatternRecord makeThen:^(BGNPatternRecord* record) {
        record.fields = fields;
    }]];
}

- (void)parser:(PKParser*)parser didMatchPatRecordFieldsOpt:(PKAssembly *)a {
    [a updateFrontForNullOrList];
}

- (void)parser:(PKParser*)parser didMatchPatRecordFields:(PKAssembly *)a {
    NSArray* items = [a popWhileMatching:^(id object) {
        return [object isKindOfClass:[BGNPatternRecordField class]];
    }];
    [a push:items];
}

- (void)parser:(PKParser*)parser didMatchPatRecordField:(PKAssembly*)a {
    id <BGNPattern> pat = [a pop];
    NSString* name = [[a pop] stringValue];
    [a push: [BGNPatternRecordField makeThen:^(BGNPatternRecordField* field) {
        field.name = name;
        field.body = pat;
    }]];
}

@end

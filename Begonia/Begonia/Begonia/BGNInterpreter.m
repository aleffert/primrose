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

- (BGNEnvironment*)processDeclaration:(id <BGNTopLevelDeclaration>)decl inEnvironment:(BGNEnvironment*)env {
    return env;
}

- (void)moduleManager:(BGNModuleManager *)manager loadedModule:(BGNModule *)module named:(NSString *)name {
    self.environment = [self.environment scopeModuleNamed:name inBody:^BGNEnvironment *(BGNEnvironment *env) {
        for(BGNImport* import in module.imports) {
            env = import.open ? [env openModuleNamed:import.name] : [env importModuleNamed:import.name];
        }
        for(id <BGNTopLevelDeclaration> decl in module.declarations) {
            env = [self processDeclaration:decl inEnvironment:env];
        }
        return env;
    }];
}

@end

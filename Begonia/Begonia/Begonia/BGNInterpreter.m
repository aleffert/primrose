//
//  BGNInterpreter.m
//  Begonia
//
//  Created by Akiva Leffert on 9/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNInterpreter.h"

#import "BGNEnvironment.h"
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

- (void)moduleManager:(BGNModuleManager *)manager loadedModule:(BGNModule *)module named:(NSString *)name {
    self.environment = [self.environment scopeModuleNamed:name inBody:^BGNEnvironment *(BGNEnvironment *env) {
        // TODO evaluate
        return env;
    }];
}

@end

//
//  BGNEnvironment.m
//  Begonia
//
//  Created by Akiva Leffert on 11/10/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNEnvironment.h"
#import "NSObject+BGNConstruction.h"
#import "BGNPrelude.h"

@interface BGNModuleEnvironment : NSObject <NSCopying>

@property (copy, nonatomic) NSDictionary* expMap;

@property (copy, nonatomic) NSArray* openModules;
@property (copy, nonatomic) NSArray* importedModules;
@property (copy, nonatomic) NSString* name;

@end

@implementation BGNModuleEnvironment

- (id)init {
    if((self = [super init])) {
        self.expMap = @{};
        self.openModules = @[];
        self.importedModules = @[];
        self.name = nil;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    BGNModuleEnvironment* me = [[BGNModuleEnvironment alloc] init];
    me.expMap = self.expMap;
    me.openModules = self.openModules;
    me.importedModules = self.importedModules;
    me.name = self.name;
    return me;
}

@end

@interface BGNEnvironment ()

@property (copy, nonatomic) NSArray* moduleStack;
@property (copy, nonatomic) BGNModuleEnvironment* currentModule;
@property (copy, nonatomic) NSDictionary* loadedModules;

@end

@implementation BGNEnvironment

+ (BGNEnvironment*)empty {
    return [BGNEnvironment makeThen:^(BGNEnvironment* env) {
        env.loadedModules = @{};
        env.currentModule = [BGNModuleEnvironment makeThen:^(BGNModuleEnvironment* me) {
            me.name = @"__topLevel";
        }];
        env.moduleStack = @[];
    }];
}

- (id)copyWithZone:(NSZone*)zone {
    BGNEnvironment* result = [[BGNEnvironment allocWithZone:zone] init];
    result.moduleStack = self.moduleStack;
    result.currentModule = self.currentModule.copy;
    result.loadedModules = self.loadedModules.copy;
    return result;
}

- (BGNEnvironment*)bindExpVar:(NSString*)name withValue:(id <BGNValue>)value {
    BGNModuleEnvironment* me = self.currentModule.copy;
    NSMutableDictionary* updatedMap = me.expMap.mutableCopy;
    [updatedMap setObject:value forKey:name];
    me.expMap = updatedMap;
    
    BGNEnvironment* result = self.copy;
    result.currentModule = me;
    
    return result;
}

- (id <BGNValue>)valueNamed:(NSString*)name inModule:(NSString*)moduleName {
    if(moduleName == nil) {
        id <BGNValue> value = self.currentModule.expMap[name];
        if(value == nil) {
            for(BGNModuleEnvironment* me in self.currentModule.openModules.reverseObjectEnumerator) {
                id <BGNValue> value = me.expMap[name];
                if(value != nil) {
                    return value;
                }
            }
            // Didn't find it
            NSAssert(NO, @"Couldn't find %@", name);
            return nil;
        }
        else {
            return value;
        }
    }
    else {
        NSAssert([self.currentModule.openModules containsObject:moduleName] || self.currentModule == nil, @"No module named, %@", moduleName);
        BGNModuleEnvironment* me = self.loadedModules[moduleName];
        NSAssert(me != nil, @"Couldn't lookup module named %@", moduleName);
        
        id <BGNValue> value = me.expMap[name];
        NSAssert(value != nil, @"Couldn't lookup %@.%@", moduleName, name);
        return value;
    }
}

- (BGNEnvironment*)scopeModuleNamed:(NSString*)name inBody:(BGNEnvironment* (^)(BGNEnvironment* env))body {
    BGNModuleEnvironment* me = [BGNModuleEnvironment makeThen:^(BGNModuleEnvironment* me) {
        me.name = name;
    }];
    
    BGNEnvironment* env = self.copy;
    env.moduleStack = [self.moduleStack arrayByAddingObject:me];
    env.currentModule = me;
    
    if(![name isEqualToString:BGNPreludeModuleName]) {
        env = [env openModuleNamed:BGNPreludeModuleName];
    }
    
    BGNEnvironment* result = body(env).copy;
    NSMutableDictionary* loadedModules = result.loadedModules.mutableCopy;
    loadedModules[name] = result.currentModule;
    result.loadedModules = loadedModules;
    result.currentModule = result.moduleStack.count == 1 ? nil : self.moduleStack[result.moduleStack.count - 2];
    result.moduleStack = [result.moduleStack subarrayWithRange:NSMakeRange(0, result.moduleStack.count - 1)];
    
    return result;
}

- (BGNEnvironment*)importModuleNamed:(NSString*)moduleName {
    BGNModuleEnvironment* module = self.loadedModules[moduleName];
    NSAssert(module != nil, @"Couldn't find module named %@", moduleName);
    
    BGNModuleEnvironment* me = self.currentModule.copy;
    me.importedModules = [me.importedModules arrayByAddingObject:module];
    
    BGNEnvironment* env = self.copy;
    env.currentModule = me;
    return env;
}

- (BGNEnvironment*)openModuleNamed:(NSString*)moduleName {
    BGNModuleEnvironment* module = self.loadedModules[moduleName];
    NSAssert(module != nil, @"Couldn't find module named %@", moduleName);
    
    BGNModuleEnvironment* me = self.currentModule.copy;
    me.openModules = [me.openModules arrayByAddingObject:module];
    
    BGNEnvironment* env = self.copy;
    env.currentModule = me;
    return env;
}

@end

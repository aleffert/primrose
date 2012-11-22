//
//  BGNModuleManager.m
//  Begonia
//
//  Created by Akiva Leffert on 11/4/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNModuleManager.h"

#import "BGNLang.h"
#import "BGNParser.h"
#import "BGNParserResult.h"

#import "NSArray+Functional.h"
#import "NSMutableArray+BGNStack.h"
#import "NSObject+BGNConstruction.h"

@interface BGNModuleDescription : NSObject

@property (retain, nonatomic) NSString* name;
@property (retain, nonatomic) NSString* path;

@end

@implementation BGNModuleDescription

@end

@interface BGNLoadedModule : NSObject

@property (retain, nonatomic) BGNModuleDescription* description;
@property (retain, nonatomic) NSDate* modificationDate;
@property (retain, nonatomic) BGNModule* content;

@end

@implementation BGNLoadedModule

@end

@interface BGNModuleManager ()

@property (retain, nonatomic) NSMutableDictionary* modules; // NSString -> BGNLoadedModule

@end

@implementation BGNModuleManager

- (id)init {
    if((self = [super init])) {
        self.modules = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (NSDate*)modificationDateForPath:(NSString*)path {
    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSDate* modificationDate = attributes[NSFileModificationDate];
    return modificationDate;
}

- (NSString*)pathForModuleNamed:(NSString*)name basedAt:(NSString*)base {
    return [NSString stringWithFormat:@"%@/%@.bgn", base, name.lowercaseString];
}

// Also parses and caches these modules
- (NSArray*)recursiveDependenciesOfModuleNamed:(NSString*)name atPath:(NSString*)path {
    NSMutableArray* loadedModules = [[NSMutableArray alloc] init];
    
    BGNModuleDescription* loadingModule = [BGNModuleDescription makeThen:^(BGNModuleDescription* description) {
        description.name = name;
        description.path = path;
    }];
    
    NSString* pathBase = path.stringByDeletingLastPathComponent;
    
    NSMutableArray* modulesToLoad = [NSMutableArray arrayWithObject:loadingModule];
    while(modulesToLoad.count > 0) {
        BGNModuleDescription* description = [modulesToLoad pop];
        if(description.path == nil) {
            description.path = [self pathForModuleNamed:description.name basedAt:pathBase];
        }
        
        BGNParser* parser = [[BGNParser alloc] init];
        id <BGNParserResult> result = [parser parseFile:description.path];
        [result caseModule:^(BGNModule* module) {
            [self.modules setObject:[BGNLoadedModule makeThen:^(BGNLoadedModule* md) {
                md.description = description;
                md.modificationDate = [self modificationDateForPath:description.path];
                md.content = module;
            }] forKey:description.name];
            [loadedModules addObject:description];
            
            for(BGNImport* import in module.imports) {
                BGNLoadedModule* loadedModule = [self.modules objectForKey:import.name];
                if(loadedModule == nil) {
                    [modulesToLoad push:[BGNModuleDescription makeThen:^(BGNModuleDescription* md) {
                        md.name = import.name;
                    }]];
                }
                else {
                    NSString* path = loadingModule.path ? loadingModule.path : [self pathForModuleNamed:loadingModule.path basedAt:pathBase];
                    NSDate* modificationDate = [self modificationDateForPath:path];
                    if([modificationDate compare:loadedModule.modificationDate] == NSOrderedDescending) {
                        [modulesToLoad push:[BGNModuleDescription makeThen:^(BGNModuleDescription* md) {
                            md.name = import.name;
                            md.path = path;
                        }]];
                    }
                }
            }
        } error:^(NSError* error) {
            NSLog(@"parse error %@", error);
        }];
        
    }
    return loadedModules;

}

- (void)loadModuleNamed:(NSString*)name atPath:(NSString*)path {
    NSArray* updatedModules = [self recursiveDependenciesOfModuleNamed:name atPath:path];
    NSMutableArray* updatedModuleNames = [updatedModules map:^(BGNModuleDescription* md) {
        return md.name;
    }].mutableCopy;
    while(updatedModuleNames.count > 0) {
        NSString* nextCandidate = nil;
        for(NSString* currentName in updatedModuleNames) {
            BGNLoadedModule* loadInfo = self.modules[currentName];
            NSArray* activeDependencies = [loadInfo.content.imports filter:^BOOL(BGNImport* import) {
                return [updatedModuleNames containsObject:import.name];
            }];
            if(activeDependencies.count == 0) {
                nextCandidate = currentName;
                break;
            }
        }
        if(nextCandidate == nil) {
            NSLog(@"Cyclic dependency. Aborting!");
            return;
        }
        else {
            BGNLoadedModule* info = self.modules[nextCandidate];
            [self.delegate moduleManager:self loadedModule:info.content named:info.description.name];
            [updatedModuleNames removeObject:info.description.name];
        }
    }
    
    NSLog(@"loaded %@", self.modules.allKeys);

}

@end

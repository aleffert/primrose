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

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* path;

@end

@implementation BGNModuleDescription

@end

@interface BGNLoadedModule : NSObject

@property (strong, nonatomic) BGNModuleDescription* description;
@property (strong, nonatomic) NSDate* modificationDate;
@property (strong, nonatomic) BGNModule* content;

@end

@implementation BGNLoadedModule

@end

@interface BGNModuleManager ()

@property (strong, nonatomic) NSMutableDictionary* modules; // NSString -> BGNLoadedModule
@property (strong, nonatomic) NSMutableDictionary* contentOverrides; // NSString -> NSString

@end

@implementation BGNModuleManager

@synthesize searchPaths = _searchPaths;

- (id)init {
    if((self = [super init])) {
        self.modules = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (NSDate*)modificationDateForPath:(NSString*)path {
    if(path == nil) {
        // TODO restore the saved modification date here
        return [NSDate distantPast];
    }
    else {
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        NSDate* modificationDate = attributes[NSFileModificationDate];
        return modificationDate;
    }
}

- (NSString*)pathForModuleNamed:(NSString*)name basedAt:(NSString*)base {
    
    if(base != nil) {
        NSString* path = [NSString stringWithFormat:@"%@/%@.bgn", base, name.lowercaseString];
        if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return path;
        }
    }
    
    for(NSString* searchBase in self.searchPaths) {
        NSString* path = [NSString stringWithFormat:@"%@/%@.bgn", searchBase, name.lowercaseString];
        if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return path;
        }
    }
    return nil;
}

- (NSString*)contentOfModuleNamed:(NSString*)moduleName atPath:(NSString*)path {
    NSString* override = self.contentOverrides[moduleName];
    if(override != nil) {
        return override;
    }
    else {
        NSError* error = nil;
        NSString* result = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        
        NSAssert(result != nil, @"Couldn't find content of module %@ at %@: %@", moduleName, path, error);
        return result;
    }
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
        NSString* content = [self contentOfModuleNamed:description.name atPath:description.path];
        id <BGNParserResult> result = [parser parseString:content sourceName:description.name];
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

- (void)loadModuleNamed:(NSString *)module {
    [self loadModuleNamed:module atPath:nil];
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

- (void)setContent:(NSString *)text ofModuleNamed:(NSString *)module {
    // TODO save current date as the modification date
    self.contentOverrides[module] = text;
}

@end

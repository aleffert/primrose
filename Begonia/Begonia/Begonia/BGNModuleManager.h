//
//  BGNModuleManager.h
//  Begonia
//
//  Created by Akiva Leffert on 11/4/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BGNModuleManagerDelegate;
@class BGNModule;

@protocol BGNModuleLoader

@property (copy, nonatomic) NSArray* searchPaths;
- (void)loadModuleNamed:(NSString*)name atPath:(NSString*)path;
- (void)loadModuleNamed:(NSString*)module;
- (void)setContent:(NSString*)text ofModuleNamed:(NSString*)module;

@end

@interface BGNModuleManager : NSObject <BGNModuleLoader>


@property (weak, nonatomic) id <BGNModuleManagerDelegate> delegate;

@end


@protocol BGNModuleManagerDelegate <NSObject>

- (void)moduleManager:(BGNModuleManager*)manager loadedModule:(BGNModule*)module named:(NSString*)name;

@end
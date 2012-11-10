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

@interface BGNModuleManager : NSObject

- (void)loadModuleNamed:(NSString*)name atPath:(NSString*)path;

@property (weak, nonatomic) id <BGNModuleManagerDelegate> delegate;

@end


@protocol BGNModuleManagerDelegate <NSObject>

- (void)moduleManager:(BGNModuleManager*)manager loadedModule:(BGNModule*)module named:(NSString*)name;

@end
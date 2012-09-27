//
//  ADLFileWatcher.h
//  Begonia
//
//  Created by Akiva Leffert on 9/22/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ADLFileWatcher;

typedef void (^ADLFileWatcherBlock)(ADLFileWatcher*);

@interface ADLFileWatcher : NSObject

- (void)stopWatching;
- (void)startWatching;

@property (copy, nonatomic) ADLFileWatcherBlock changedAction;
@property (copy, nonatomic) NSString* filePath;

@end

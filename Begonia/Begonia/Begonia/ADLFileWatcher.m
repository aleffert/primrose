//
//  ADLFileWatcher.m
//  Begonia
//
//  Created by Akiva Leffert on 9/22/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ADLFileWatcher.h"

@interface ADLFileWatcher ()

@property (assign, nonatomic) FSEventStreamRef streamRef;

@end

@implementation ADLFileWatcher

void ADLFileWatcherPathChanged(
                      ConstFSEventStreamRef streamRef,
                      void *clientCallBackInfo,
                      size_t numEvents,
                      void *eventPaths,
                      const FSEventStreamEventFlags eventFlags[],
                      const FSEventStreamEventId eventIds[]) {
    ADLFileWatcher* watcher = (__bridge ADLFileWatcher*)clientCallBackInfo;
    watcher.changedAction(watcher);
}

- (void)dealloc {
    [self stopWatching];
}

- (void)setFilePath:(NSString *)filePath {
    [self stopWatching];
    _filePath = filePath;
    [self startWatching];
}

- (NSString*)fileDirectoryPath {
    return [[self filePath] stringByDeletingLastPathComponent];
}

- (void)startWatching {
    FSEventStreamContext context;
    context.version = 0;
    context.info = (__bridge void*)self;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    
    CFArrayRef paths = (__bridge_retained CFArrayRef)[NSArray arrayWithObject:[self fileDirectoryPath]];
    
    
    self.streamRef =
    FSEventStreamCreate(NULL, ADLFileWatcherPathChanged, &context, (CFArrayRef)paths, kFSEventStreamEventIdSinceNow, .5,
                        kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf);
    FSEventStreamScheduleWithRunLoop(self.streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.streamRef);
    CFRelease(paths);
}

- (void)setWatchPath:(NSString*)path{
    [self stopWatching];
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"FilePath"];
    [self startWatching];
    self.changedAction(self);
}


- (void)stopWatching {
    if(self.streamRef != nil) {
        FSEventStreamStop(self.streamRef);
        FSEventStreamInvalidate(self.streamRef);
        FSEventStreamRelease(self.streamRef);
        self.streamRef = nil;
    }
}

@end

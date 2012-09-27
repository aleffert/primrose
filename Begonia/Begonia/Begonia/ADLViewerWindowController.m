//
//  ADLViewerWindowController.m
//  Begonia
//
//  Created by Akiva Leffert on 9/22/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ADLViewerWindowController.h"

#import "BGNInterpreter.h"
#import "ADLFileWatcher.h"

@interface ADLViewerWindowController ()

@property (strong, nonatomic) IBOutlet ADLFileAcceptorView* acceptorView;
@property (strong, nonatomic) ADLFileWatcher* fileWatcher;
@property (strong, nonatomic) BGNInterpreter* interpreter;
@property (strong, nonatomic) NSView* bodyView;

@end

@implementation ADLViewerWindowController

- (void)windowDidLoad {
    self.fileWatcher = [[ADLFileWatcher alloc] init];
    __weak ADLViewerWindowController* owner = self;
    self.fileWatcher.changedAction = ^(ADLFileWatcher* watcher) {
        NSString* path = watcher.filePath;
        [owner clearDisplay];
        if(path != nil && owner != nil) {
            CALayer* container = [owner makeNewDisplay];
            owner.interpreter = [[BGNInterpreter alloc] init];
            owner.interpreter.display = container;
            owner.interpreter.errorHandler = ^(NSString* error) {
                NSLog(@"Error interpreting file %@: %@", path, error);
            };
            [owner.interpreter interpretFile:path];
        }
    };
    self.acceptorView.currentPath = self.fileWatcher.filePath;
}

- (void)clearDisplay {
    self.bodyView.subviews = [NSArray array];
}

- (CALayer*)makeNewDisplay {
    NSView* contentView = [[NSView alloc] initWithFrame:self.bodyView.bounds];
    contentView.layer = [CALayer layer];
    contentView.wantsLayer = YES;
    
    [self.bodyView addSubview:contentView];
    return contentView.layer;
}

- (void)useFile:(NSString*)path {
    self.fileWatcher.filePath = path;
    self.acceptorView.currentPath = path;
}

- (void)acceptorViewGotPath:(NSString *)path {
    [self useFile:path];
}

@end

//
//  ADLAppDelegate.m
//  Begonia
//
//  Created by Akiva Leffert on 9/22/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ADLAppDelegate.h"

#import "BGNPrecedenceParser.h"
#import "ADLViewerWindowController.h"

@interface ADLAppDelegate ()

@property (strong, nonatomic) NSWindowController* controller;

@end

@implementation ADLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.controller = [[ADLViewerWindowController alloc] initWithWindowNibName:@"ADLViewerWindowController"];
    [self.controller.window makeKeyAndOrderFront:nil];
    
    [BGNPrecedenceParser test];
}

@end

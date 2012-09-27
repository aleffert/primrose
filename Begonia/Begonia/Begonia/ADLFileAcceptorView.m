//
//  ADLFileAcceptorView.m
//  Begonia
//
//  Created by Akiva Leffert on 9/22/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ADLFileAcceptorView.h"

#import "ADLGradientView.h"

@interface ADLFileAcceptorView ()

@property (strong, nonatomic) IBOutlet NSTextField* currentPathLabel;
@property (strong, nonatomic) NSView* focusRing;

@end

@implementation ADLFileAcceptorView

- (id)initWithFrame:(NSRect)frameRect {
    if((self = [super initWithFrame:frameRect])) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [[NSBundle mainBundle] loadNibNamed:@"ADLFileAcceptorView" owner:self topLevelObjects:nil];
    [self addSubview:self.currentPathLabel];
    [self registerForDraggedTypes:[NSArray arrayWithObject: @"public.file-url"]];
    
    
    ADLGradientView* backgroundView = [[ADLGradientView alloc] initWithFrame:self.bounds];
    [backgroundView useVerticalGradientFromColor:[NSColor lightGrayColor] toColor:[NSColor darkGrayColor]];
    [self addSubview:backgroundView positioned:NSWindowBelow relativeTo:nil];
    
    self.focusRing = [[NSView alloc] initWithFrame:self.bounds];
    self.focusRing.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:self.focusRing positioned:NSWindowBelow relativeTo:self.currentPathLabel];
    self.focusRing.layer = [CALayer layer];
    [self.focusRing setWantsLayer:YES];
    self.focusRing.layer.borderWidth = 3;
    self.focusRing.layer.borderColor = [NSColor keyboardFocusIndicatorColor].CGColor;
    self.focusRing.layer.opacity = 0;
}

- (void)setFocusRingVisible:(BOOL)visible {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    self.focusRing.layer.opacity = visible;
    [CATransaction commit];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender
{
    NSPasteboard* draggingPasteboard = [sender draggingPasteboard];
    NSArray* items = [draggingPasteboard pasteboardItems];
    if(items.count != 1){
        [self setFocusRingVisible:NO];
        return NSDragOperationNone;
    }
    
    
    if ((NSDragOperationCopy & [sender draggingSourceOperationMask])) {
        [self setFocusRingVisible:YES];
        return NSDragOperationCopy;
    }
    
    // not a drag we can use
    [self setFocusRingVisible:NO];
    return NSDragOperationNone;
    
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    [self setFocusRingVisible:NO];
}

- (void)setCurrentPath:(NSString *)currentPath {
    _currentPath = currentPath;
    if(currentPath == nil) {
        self.currentPathLabel.stringValue = @"No Current File";
    }
    else {
        self.currentPathLabel.stringValue = currentPath;
    }
    [self.currentPathLabel sizeToFit];
    [self.currentPathLabel setFrameOrigin:NSMakePoint(10, (self.frame.size.height - self.currentPathLabel.frame.size.height) / 2)];
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    self.focusRing.layer.opacity = 0;
    NSPasteboard* draggingPasteboard = [sender draggingPasteboard];
    NSArray* items = [draggingPasteboard pasteboardItems];
    if(items.count == 1) {
        NSPasteboardItem* item = [items objectAtIndex:0];
        NSString* path = [item stringForType:@"public.file-url"];
        NSURL* fileURL = [[NSURL alloc] initWithString:path];
        [self.delegate acceptorViewGotPath:fileURL.path];
        return YES;
    }
    else {
        return NO;
    }
}


@end

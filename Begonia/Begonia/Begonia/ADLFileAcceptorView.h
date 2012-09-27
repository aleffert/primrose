//
//  ADLFileAcceptorView.h
//  Begonia
//
//  Created by Akiva Leffert on 9/22/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ADLFileAcceptorViewDelegate;

@interface ADLFileAcceptorView : NSView

@property (weak, nonatomic) IBOutlet id <ADLFileAcceptorViewDelegate> delegate;
@property (copy, nonatomic) NSString* currentPath;

@end


@protocol ADLFileAcceptorViewDelegate <NSObject>

- (void)acceptorViewGotPath:(NSString*)path;

@end
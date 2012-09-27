//
//  ADLGradientView.h
//  Begonia
//
//  Created by Akiva Leffert on 9/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ADLGradientView : NSView

@property (readonly, strong, nonatomic) CAGradientLayer* gradientLayer;

- (void)useVerticalGradientFromColor:(NSColor*)color1 toColor:(NSColor*)color2;

@end

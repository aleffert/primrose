//
//  ADLGradientView.m
//  Begonia
//
//  Created by Akiva Leffert on 9/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ADLGradientView.h"

@interface ADLGradientView ()

@property (strong, nonatomic) CAGradientLayer* gradientLayer;

@end

@implementation ADLGradientView

- (id)initWithFrame:(NSRect)frameRect {
    if(self = [super initWithFrame:frameRect]) {
        self.gradientLayer = [CAGradientLayer layer];
        [self setLayer:self.gradientLayer];
        [self setWantsLayer:YES];
    }
    return self;
}

- (void)useVerticalGradientFromColor:(NSColor*)color1 toColor:(NSColor*)color2 {
    self.gradientLayer.startPoint = CGPointMake(0, 1);
    self.gradientLayer.endPoint = CGPointMake(0, 0);
    
    self.gradientLayer.colors = @[(__bridge id)color1.CGColor, (__bridge id)color2.CGColor];
}

@end

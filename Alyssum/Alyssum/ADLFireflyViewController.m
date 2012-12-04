//
//  ADLFireflyViewController.m
//  Alyssum
//
//  Created by Akiva Leffert on 9/9/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ADLFireflyViewController.h"

#import "BGNInterpreter.h"

@interface ADLFireflyViewController ()

@property (strong, nonatomic) CATextLayer* rainText;
@property (strong, nonatomic) CAShapeLayer* cloudLayer;

@end


@implementation ADLFireflyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (UIBezierPath*)fullCloudPath {
    BGNInterpreter* interpreter = [[BGNInterpreter alloc] init];
    NSString* path = [[NSBundle mainBundle] pathForResource:@"Script/cloud" ofType:@"bgn"];
    [interpreter.moduleLoader loadModuleNamed:@"Cloud" atPath:path];
    return [interpreter objectNamed:@"cloudPath" inModule:@"Cloud"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cloudLayer = [CAShapeLayer layer];
    self.cloudLayer.strokeColor = [UIColor colorWithWhite:.1 alpha:1.].CGColor;
    self.cloudLayer.fillColor = [UIColor grayColor].CGColor;
    self.cloudLayer.lineWidth = 4;
    self.cloudLayer.path = [self fullCloudPath].CGPath;
    [self.view.layer addSublayer:self.cloudLayer];
    
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef) @"HelveticaNeue-Bold", 40, NULL);
    
    self.rainText = [CATextLayer layer];
    self.rainText.font = font;
    CFRelease(font);
    self.rainText.string = @"It was a rainy day.";
    
    [self.view.layer addSublayer:self.rainText];
    self.rainText.position = CGPointMake(200, 100);
    self.rainText.bounds = CGRectMake(0, 0, 330, 100);
    self.rainText.foregroundColor = [UIColor whiteColor].CGColor;
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any stronged subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end

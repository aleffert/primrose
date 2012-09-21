//
//  ADLAppDelegate.m
//  Alyssum
//
//  Created by Akiva Leffert on 9/9/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "ADLAppDelegate.h"

#import "ADLFireflyViewController.h"

@implementation ADLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    ADLFireflyViewController* root = [[ADLFireflyViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = root;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end

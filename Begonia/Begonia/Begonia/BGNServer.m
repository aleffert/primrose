//
//  BGNServer.m
//  Begonia
//
//  Created by Akiva Leffert on 11/30/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNServer.h"

#import "BGNInterpreter.h"
#import "BLIP.h"

@interface BGNServer ()

@property (strong) BGNInterpreter* interpreter;
@property (strong) BLIPListener* listener;

@end

@implementation BGNServer

- (instancetype)initWithPort:(uint16_t)port {
    if((self = [super init])) {
        self.interpreter = [[BGNInterpreter alloc] init];
        self.listener = [[BLIPListener alloc] initWithPort:port];
    }
    return self;
}

- (void)startServer {
    NSError* error = nil;
    [self.listener open:&error];
    if(error != nil) {
        NSLog(@"Error opening server: %@", error);
    }
}

- (void)stopServer {
    [self.listener close];
}

@end

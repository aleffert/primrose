//
//  BGNServer.m
//  Begonia
//
//  Created by Akiva Leffert on 11/30/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNServer.h"

#import "BGNInterpreter.h"

@interface BGNServer ()

@property (strong) BGNInterpreter* interpreter;

@end

@implementation BGNServer

- (id)init {
    if((self = [super init])) {
        self.interpreter = [[BGNInterpreter alloc] init];
    }
    return self;
}

- (void)startServerAtPoint:(NSUInteger)port {
}

- (void)stopServer {
    
}

@end

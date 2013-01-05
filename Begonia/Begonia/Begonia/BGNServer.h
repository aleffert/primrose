//
//  BGNServer.h
//  Begonia
//
//  Created by Akiva Leffert on 11/30/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNInterpreter;

@interface BGNServer : NSObject <NSPortDelegate>

- (void)startServerAtPort:(NSUInteger)port;
- (void)stopServer;

@property (strong, readonly) BGNInterpreter* interpreter;

@end

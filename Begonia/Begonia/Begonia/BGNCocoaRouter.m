//
//  BGNCocoaRouter.m
//  Begonia
//
//  Created by Akiva Leffert on 11/25/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNCocoaRouter.h"

#import <Foundation/NSObjCRuntime.h>

@interface BGNClassFetcher : NSObject
@end

@implementation BGNClassFetcher

- (BOOL)respondsToSelector:(SEL)aSelector {
    Class result = NSClassFromString(NSStringFromSelector(aSelector));
    if(result != nil) {
        return YES;
    }
    else {
        return [super respondsToSelector:aSelector];
    }
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    Class result = NSClassFromString(NSStringFromSelector(aSelector));
    if(result != nil) {
        return [NSMethodSignature signatureWithObjCTypes:"#@:"];
    }
    else {
        return [super methodSignatureForSelector:aSelector];
    }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    
    Class result = NSClassFromString(NSStringFromSelector(selector));
    if(result != nil) {
        [anInvocation setReturnValue:&result];
    }
    else {
        [super forwardInvocation:anInvocation];
    }
}

@end

@implementation BGNCocoaRouter

+ (BGNCocoaRouter*)router {
    return [[BGNCocoaRouter alloc] init];
}

- (BGNClassFetcher*)classNamed {
    return [[BGNClassFetcher alloc] init];
}

@end

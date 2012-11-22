//
//  BGNPrimops.m
//  Begonia
//
//  Created by Akiva Leffert on 11/18/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNPrimops.h"

#import "BGNInterpreter.h"
#import "BGNValue.h"
#import "NSObject+BGNConstruction.h"

@interface BGNPrimops ()

@property (copy, nonatomic) NSDictionary* opTable;

@end

@implementation BGNPrimops

+ (id <BGNValue>)evaluatePrimop:(NSString*)name args:(NSArray*)args inInterpreter:(BGNInterpreter*)interpreter {
    return [[self sharedPrimops] evaluatePrimop:name args:args inInterpreter:interpreter];
}

+ (BGNPrimops*)sharedPrimops {
    static BGNPrimops* sharedPrimops;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPrimops = [[BGNPrimops alloc] init];
    });
    return sharedPrimops;
}

- (id)init {
    if((self = [super init])) {
        self.opTable = @{
        @"+" : ^(NSArray* args, BGNInterpreter* interpreter) {
            return [self evaluateAdd:args];
        },
        @"-" : ^(NSArray* args, BGNInterpreter* interpreter) {
            return [self evaluateSub:args];
        },
        @"*" : ^(NSArray* args, BGNInterpreter* interpreter) {
            return [self evaluateMul:args];
        },
        @"/" : ^(NSArray* args, BGNInterpreter* interpreter) {
            return [self evaluateDiv:args];
        },
        @"$UMINUS" : ^(NSArray* args, BGNInterpreter* interpreter) {
            return [self evaluateUnaryMinus:args];
        },
        @"$intToFloat" : ^(NSArray* args, BGNInterpreter* interpreter) {
            return [self evaluateIntToFloat:args];
        }
        };
    }
    return self;
}

- (id <BGNValue>)binaryMathOpWithArgs:(NSArray*)args asFloats:(CGFloat(^)(CGFloat, CGFloat))floats ints:(NSInteger(^)(NSInteger, NSInteger))ints {
    NSAssert(args.count == 2, @"StaticError: Expecting two args to arithmetic operation, found %@", args);
    id <BGNValue> left = args[0];
    id <BGNValue> right = args[1];
    if([left isKindOfClass:[BGNValueFloat class]]) {
        NSAssert([right isKindOfClass:[BGNValueFloat class]], @"StaticError: Expecting arithmetic arguments to match %@ and %@", left, right);
        return [BGNValueFloat makeThen:^(BGNValueFloat* f) {
            f.value = floats(((BGNValueFloat*)left).value, ((BGNValueFloat*)right).value);
        }];
    }
    else {
        NSAssert([right isKindOfClass:[BGNValueFloat class]], @"StaticError: Expecting arithmetic arguments to match %@ and %@", left, right);
        return [BGNValueInt makeThen:^(BGNValueInt* f) {
            f.value = ints(((BGNValueInt*)left).value, ((BGNValueInt*)right).value);
        }];
    }
}

- (id <BGNValue>)evaluateAdd:(NSArray*)args {
    return [self binaryMathOpWithArgs:args asFloats:^(CGFloat l, CGFloat r) {return l + r;}
                          ints:^(NSInteger l, NSInteger r) {return l + r;}];
}


- (id <BGNValue>)evaluateSub:(NSArray*)args {
    return [self binaryMathOpWithArgs:args asFloats:^(CGFloat l, CGFloat r) {return l - r;}
                          ints:^(NSInteger l, NSInteger r) {return l - r;}];
}

- (id <BGNValue>)evaluateMul:(NSArray*)args {
    return [self binaryMathOpWithArgs:args asFloats:^(CGFloat l, CGFloat r) {return l * r;}
                          ints:^(NSInteger l, NSInteger r) {return l * r;}];
}

- (id <BGNValue>)evaluateDiv:(NSArray*)args {
    return [self binaryMathOpWithArgs:args asFloats:^(CGFloat l, CGFloat r) {return l / r;}
                          ints:^(NSInteger l, NSInteger r) {return l / r;}];
}

- (id <BGNValue>)evaluateUnaryMinus:(NSArray*)args {
    NSAssert(args.count == 1, @"StaticError: Expecting one arg to arithmetic operation, found %@",args);
    id <BGNValue> value = args[0];
    if([value isKindOfClass:[BGNValueInt class]]) {
        return [BGNValueInt makeThen:^(BGNValueInt* i) {
            i.value = -((BGNValueInt*)value).value;
        }];
    }
    else {
        NSAssert([value isKindOfClass:[BGNValueFloat class]], @"StaticError: Unexpected unary minus argument: %@", args);
        return [BGNValueInt makeThen:^(BGNValueFloat* f) {
            f.value = -((BGNValueFloat*)value).value;
        }];
    }
}

- (id <BGNValue>)evaluateIntToFloat:(NSArray*)args {
    NSAssert(args.count == 1, @"StaticError: Expecting one arg to arithmetic conversion, found %@",args);
    id <BGNValue> v = args[0];
    NSAssert([v isKindOfClass:[BGNValueInt class]], @"StaticError: Expecting int to float conversion to get an int, found %@", v);
    BGNValueInt* i = (id <BGNValue>)v;
    return [BGNValueFloat makeThen:^(BGNValueFloat* f) {
        f.value = i.value;
    }];
}

- (id <BGNValue>)evaluatePrimop:(NSString*)name args:(NSArray*)args inInterpreter:(BGNInterpreter*)interpreter {
    id <BGNValue> (^op)(NSArray*, BGNInterpreter*) = self.opTable[name];
    return op(args, interpreter);
}

@end

//
//  BGNValue.h
//  Begonia
//
//  Created by Akiva Leffert on 11/10/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNEnvironment;
@protocol BGNExpression;

@protocol BGNValue <NSObject>

@end

@interface BGNValueInt : NSObject <BGNValue>

@property (assign, nonatomic) NSInteger value;

@end

@interface BGNValueFloat : NSObject <BGNValue>

@property (assign, nonatomic) CGFloat value;

@end

@interface BGNValueString : NSObject <BGNValue>

@property (retain, nonatomic) NSString* value;

@end

@interface BGNValueExternalObject : NSObject <BGNValue>

@property (strong, nonatomic) id object;

@end

@interface BGNValueFunction : NSObject <BGNValue>

@property (retain, nonatomic) NSArray* vars; // BGNBindingArgument
@property (retain, nonatomic) id <BGNExpression> body;
@property (retain, nonatomic) BGNEnvironment* env;

@end

@interface BGNValueConstructor : NSObject <BGNValue>

@property (retain, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNValue> value;

@end

@interface BGNValueRecordField : NSObject

@property (copy, nonatomic) NSString* name;
@property (retain, nonatomic) id <BGNValue> value;

@end

@interface BGNValueRecord : NSObject <BGNValue>

@property (copy, nonatomic) NSArray* fields; // BGNValueRecordField

@end

// This should probably be a datatype, but this is simpler for now.
@interface BGNValueBool : NSObject <BGNValue>

@property (assign, nonatomic) BOOL value;

@end

//
//  BGNValue.m
//  Begonia
//
//  Created by Akiva Leffert on 11/10/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNValue.h"

@implementation BGNValueInt

- (NSString*)description {
    return [NSString stringWithFormat:@"%ld", self.value];
}

@end

@implementation BGNValueFloat

- (NSString*)description {
    return [NSString stringWithFormat:@"%f", self.value];
}

@end

@implementation BGNValueString

- (NSString*)description {
    return [NSString stringWithFormat:@"\"%@\"", self.value];
}

@end

@implementation BGNValueBool

- (NSString*)description {
    return self.value ? @"True" : @"False";
}

@end

@implementation BGNValueExternalObject

- (NSString*)description {
    return [self.object description];
}

@end

@implementation BGNValueFunction

- (NSString*)description {
    return [NSString stringWithFormat:@"fun %@ = %@", self.vars, self.body];
}

@end

@implementation BGNValueRecord

- (NSString*)description {
    return [NSString stringWithFormat:@"{%@}", self.fields];
}

@end

@implementation BGNValueConstructor

- (NSString*)description {
    return [NSString stringWithFormat:@"%@(%@)", self.name, self.value];
}

@end

@implementation BGNValueRecordField

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ : %@", self.name, self.value];
}

@end
//
//  BGNPatternVisitor.m
//  Begonia
//
//  Created by Akiva Leffert on 11/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import "BGNPatternVisitor.h"

@implementation BGNPatternBlockVisitor

- (id)visitInt:(BGNPatternInt *)pat {
    return self.intBlock(pat);
}

- (id)visitBool:(BGNPatternBool *)pat {
    return self.boolBlock(pat);
}

- (id)visitString:(BGNPatternString *)pat {
    return self.stringBlock(pat);
}

- (id)visitVar:(BGNPatternVar *)pat {
    return self.varBlock(pat);
}

- (id)visitRecord:(BGNPatternRecord *)pat {
    return self.recordBlock(pat);
}

- (id)visitConstructor:(BGNPatternConstructor *)pat {
    return self.constructorBlock(pat);
}


@end

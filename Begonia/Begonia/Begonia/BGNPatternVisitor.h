//
//  BGNPatternVisitor.h
//  Begonia
//
//  Created by Akiva Leffert on 11/23/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BGNLang.h"

@protocol BGNPatternVisitor <NSObject>

- (id)visitInt:(BGNPatternInt*)pat;
- (id)visitString:(BGNPatternString*)pat;
- (id)visitBool:(BGNPatternBool*)pat;
- (id)visitVar:(BGNPatternVar*)pat;
- (id)visitRecord:(BGNPatternRecord*)pat;
- (id)visitConstructor:(BGNPatternConstructor*)pat;

@end

@interface BGNPatternBlockVisitor : NSObject <BGNPatternVisitor>

@property (copy, nonatomic) id (^intBlock)(BGNPatternInt*);
@property (copy, nonatomic) id (^stringBlock)(BGNPatternString*);
@property (copy, nonatomic) id (^boolBlock)(BGNPatternBool*);
@property (copy, nonatomic) id (^varBlock)(BGNPatternVar*);
@property (copy, nonatomic) id (^recordBlock)(BGNPatternRecord*);
@property (copy, nonatomic) id (^constructorBlock)(BGNPatternConstructor*);

@end

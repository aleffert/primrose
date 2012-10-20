//
//  NSMutableArray+BGNStack.h
//  Begonia
//
//  Created by Akiva Leffert on 10/20/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (BGNStack)

- (id)peek;
- (void)push:(id)object;
- (id)pop;

@end

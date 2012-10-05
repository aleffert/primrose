//
//  BGNParser.h
//  Begonia
//
//  Created by Akiva Leffert on 10/2/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BGNParserResult;

@interface BGNParser : NSObject

- (BGNParserResult*)parseFile:(NSString*)path;
- (BGNParserResult*)parseString:(NSString*)string sourceName:(NSString*)sourceName;

@end

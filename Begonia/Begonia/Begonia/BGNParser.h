//
//  BGNParser.h
//  Begonia
//
//  Created by Akiva Leffert on 10/2/12.
//  Copyright (c) 2012 Akiva Leffert. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BGNParserResult;

@interface BGNParser : NSObject

- (id <BGNParserResult>)parseFile:(NSString*)path;
- (id <BGNParserResult>)parseString:(NSString*)string sourceName:(NSString*)sourceName;

@end
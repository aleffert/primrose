//  Copyright 2010 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <ParseKit/ParseKit.h>

@interface TDArithmeticParser : PKSequence {
    PKCollectionParser *exprParser;
    PKCollectionParser *termParser;
    PKCollectionParser *plusTermParser;
    PKCollectionParser *minusTermParser;
    PKCollectionParser *factorParser;
    PKCollectionParser *timesFactorParser;
    PKCollectionParser *divFactorParser;
    PKCollectionParser *exponentFactorParser;
    PKCollectionParser *phraseParser;
}
- (double)parse:(NSString *)s;

@property (nonatomic, retain) PKCollectionParser *exprParser;
@property (nonatomic, retain) PKCollectionParser *termParser;
@property (nonatomic, retain) PKCollectionParser *plusTermParser;
@property (nonatomic, retain) PKCollectionParser *minusTermParser;
@property (nonatomic, retain) PKCollectionParser *factorParser;
@property (nonatomic, retain) PKCollectionParser *timesFactorParser;
@property (nonatomic, retain) PKCollectionParser *divFactorParser;
@property (nonatomic, retain) PKCollectionParser *exponentFactorParser;
@property (nonatomic, retain) PKCollectionParser *phraseParser;
@end

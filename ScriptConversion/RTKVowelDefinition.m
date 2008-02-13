//
//  RTKVowelDefinition.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKVowelDefinition.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKIDDatabase.h"
#import "RTKGlobals.h"

@implementation RTKVowelDefinition


// persistence

NSString *RTKVowelPhoneme = @"RTKVowelPhoneme";
NSString *RTKScriptVowel = @"RTKScriptVowel";
NSString *RTKSeries = @"RTKSeries";

-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:NSStringFromClass([self class])
             forKey:RTKClass];

    [dict setObject:[RTKSharedDatabase stringForID:phoneme]
             forKey:RTKVowelPhoneme];
    [dict setObject:[RTKSharedDatabase stringForID:character]
             forKey:RTKScriptVowel];
    [dict setObject:[RTKSharedDatabase stringForID:series]
             forKey:RTKSeries];

    return dict;
}


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    phoneme = [RTKSharedDatabase idForString:[dict objectForKey:RTKVowelPhoneme]];
    character = [RTKSharedDatabase idForString:[dict objectForKey:RTKScriptVowel]];
    series = [RTKSharedDatabase idForString:[dict objectForKey:RTKSeries]];
}


-(void)display
{
    NSLog(@"RTKVowelDefinition -- phoneme: %i, character: %i, series: %i", phoneme, character, series);
}


-(int)phoneme
{
    return phoneme;
}


-(int)order:(id)other
{
    Class selfClass = [self class];
    Class otherClass = [other class];
    
    if(otherClass > selfClass)
	return 1; // after
    if(otherClass < selfClass)
	return -1; // before

    {
	int otherPhoneme = [other phoneme];
	
	if(otherPhoneme > phoneme)
	    return 1;
	if(otherPhoneme < phoneme)
	    return -1;
    }
    return 0;
}

-(id)initWithPhoneme:(int)thePhoneme
{
    if(self = [super init])
    {
	character = 0;
	series = 0;
	phoneme = thePhoneme;
    }
    return self;
}

-(int)character
{
    return character;
}

-(int)series
{
    return series;
}
@end

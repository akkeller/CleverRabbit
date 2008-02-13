//
//  RTKConsonantDefinition.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//



#import "RTKConsonantDefinition.h"
#import "RTKLinkedListHeader.h"
#import "RTKIDDatabase.h"
#import "RTKLinkedListNode.h"
#import "RTKGlobals.h"

@implementation RTKConsonantDefinition


// persistence

NSString *RTKConsonantPhoneme = @"RTKConsonantPhoneme";
NSString *RTKPresyllable = @"RTKPresyllable";
NSString *RTKFirstSeriesMain = @"RTKFirstSeriesMain";
NSString *RTKSecondSeriesMain = @"RTKSecondSeriesMain";
NSString *RTKDefaultSeriesMain = @"RTKDefaultSeriesMain";
NSString *RTKFoot = @"RTKFoot";
NSString *RTKPresyllableFinal = @"RTKPresyllableFinal";
NSString *RTKFinal = @"RTKFinal";

-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:NSStringFromClass([self class])
             forKey:RTKClass];

    [dict setObject:[RTKSharedDatabase stringForID:phoneme]
                     forKey:RTKConsonantPhoneme];
    [dict setObject:[RTKSharedDatabase stringForID:presyllable]
             forKey:RTKPresyllable];
    [dict setObject:[RTKSharedDatabase stringForID:firstSeriesMain]
             forKey:RTKFirstSeriesMain];
    [dict setObject:[RTKSharedDatabase stringForID:secondSeriesMain]
             forKey:RTKSecondSeriesMain];
    [dict setObject:[RTKSharedDatabase stringForID:defaultSeriesMain]
             forKey:RTKDefaultSeriesMain];
    [dict setObject:[RTKSharedDatabase stringForID:foot]
             forKey:RTKFoot];
    [dict setObject:[RTKSharedDatabase stringForID:presyllableFinal]
             forKey:RTKPresyllableFinal];
    [dict setObject:[RTKSharedDatabase stringForID:final]
             forKey:RTKFinal];

    return dict;
}


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    phoneme = [RTKSharedDatabase idForString:[dict objectForKey:RTKConsonantPhoneme]];
    presyllable = [RTKSharedDatabase idForString:[dict objectForKey:RTKPresyllable]];
    firstSeriesMain = [RTKSharedDatabase idForString:[dict objectForKey:RTKFirstSeriesMain]];
    secondSeriesMain = [RTKSharedDatabase idForString:[dict objectForKey:RTKSecondSeriesMain]];
    defaultSeriesMain = [RTKSharedDatabase idForString:[dict objectForKey:RTKDefaultSeriesMain]];
    foot = [RTKSharedDatabase idForString:[dict objectForKey:RTKFoot]];
    presyllableFinal = [RTKSharedDatabase idForString:[dict objectForKey:RTKPresyllableFinal]];
    final = [RTKSharedDatabase idForString:[dict objectForKey:RTKFinal]];
}


-(id)initWithPhoneme:(int)thePhoneme
{
    if(self = [super init])
    {
	presyllable = 0;
	firstSeriesMain = 0;
	secondSeriesMain = 0;
	defaultSeriesMain = 0;
	presyllableFinal = 0;
	final = 0;
	foot = 0;
	
	phoneme = thePhoneme;
    }
    return self;
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


-(int)phoneme
{
    return phoneme;
}


-(int)presyllable
{
    return presyllable;
}


-(int)firstSeriesMain
{
    return firstSeriesMain;
}


-(int)secondSeriesMain
{
    return secondSeriesMain;
}


-(int)defaultSeriesMain
{
    return defaultSeriesMain;
}


-(int)foot
{
    return foot;
}


-(int)presyllableFinal
{
    return presyllableFinal;
}


-(int)final
{
    return final;
}

@end

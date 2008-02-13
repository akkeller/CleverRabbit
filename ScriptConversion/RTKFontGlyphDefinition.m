//
//  RTKFontGlyphDefinition.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKFontGlyphDefinition.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKIDDatabase.h"
#import "RTKIDMarker.h"
#import "RTKGlobals.h"



@implementation RTKFontGlyphDefinition

// persistence

NSString *RTKGlyphName = @"RTKGlyphName";
NSString *RTKRegionList = @"RTKRegionList";
NSString *RTKIncompatibleCharList = @"RTKIncompatibleCharList";
NSString *RTKNeededCharList = @"RTKNeededCharList";
NSString *RTKIncompatibleGlyphList = @"RTKIncompatibleGlyphList";
NSString *RTKBeforePartialGlyphList = @"RTKBeforePartialGlyphList";
NSString *RTKPositionPartialGlyphList = @"RTKPositionPartialGlyphList";
NSString *RTKAfterPartialGlyphList = @"RTKAfterPartialGlyphList";

- (void)dealloc
{
    [regionList release];
    
    [incompatibleCharList release];
    [neededCharList release];
    [incompatibleGlyphList release];
    
    [beforePartialGlyphList release];
    [positionPartialGlyphList release];
    [afterPartialGlyphList release];
    
    [super dealloc];
}

-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *array;

    [dict setObject:NSStringFromClass([self class])
             forKey:RTKClass];

    [dict setObject:[RTKSharedDatabase stringForID:name]
             forKey:RTKGlyphName];
    if(array = [regionList propertyListRepresentation])
        [dict setObject:array
                 forKey:RTKRegionList];
    if(array = [incompatibleCharList propertyListRepresentation])
        [dict setObject:array
                 forKey:RTKIncompatibleCharList];
    if(array = [neededCharList propertyListRepresentation])
        [dict setObject:array
                 forKey:RTKNeededCharList];
    if(array = [incompatibleGlyphList propertyListRepresentation])
        [dict setObject:array
                 forKey:RTKIncompatibleGlyphList];
    if(array = [beforePartialGlyphList propertyListRepresentation])
        [dict setObject:array
                 forKey:RTKBeforePartialGlyphList];
    if(array = [positionPartialGlyphList propertyListRepresentation])
        [dict setObject:array
                 forKey:RTKPositionPartialGlyphList];
    if(array = [afterPartialGlyphList propertyListRepresentation])
        [dict setObject:array
                 forKey:RTKAfterPartialGlyphList];

    return dict;
}


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    name = [RTKSharedDatabase idForString:[dict objectForKey:RTKGlyphName]];
    regionList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKRegionList]];
    incompatibleCharList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKIncompatibleCharList]];
    neededCharList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKNeededCharList]];
    incompatibleGlyphList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKIncompatibleGlyphList]];
    beforePartialGlyphList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKBeforePartialGlyphList]];
    positionPartialGlyphList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKPositionPartialGlyphList]];
    afterPartialGlyphList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKAfterPartialGlyphList]];
}


-(int)name
{
    return name;
}

-(RTKLinkedListHeader *)regionList
{
    return regionList;
}

-(RTKLinkedListHeader *)incompatibleCharList
{
    return incompatibleCharList;
}

-(RTKLinkedListHeader *)neededCharList
{
    return neededCharList;
}

-(RTKLinkedListHeader *)incompatibleGlyphList
{
    return incompatibleGlyphList;
}

-(RTKLinkedListHeader *)beforePartialGlyphList
{
    return beforePartialGlyphList;
}

-(RTKLinkedListHeader *)positionPartialGlyphList
{
    return positionPartialGlyphList;
}

-(RTKLinkedListHeader *)afterPartialGlyphList
{
    return afterPartialGlyphList;
}


@end

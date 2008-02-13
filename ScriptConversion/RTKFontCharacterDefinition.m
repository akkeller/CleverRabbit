//
//  RTKFontCharacterDefinition.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKFontCharacterDefinition.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKIDDatabase.h"

#import "RTKFontGlyphDefinition.h"
#import "RTKGlobals.h"

@implementation RTKFontCharacterDefinition

// persistence

NSString *RTKFontCharacterKey = @"RTKFontCharacterKey";
NSString *RTKGlyphList = @"RTKGlyphList";


-(id)initWithCharacter:(int)theCharacter
{
    if(self = [super init])
     {
        glyphList = nil;
        character = theCharacter;
     }
    return self;
}

- (void)dealloc
{
    [glyphList release];
    [super dealloc];
}

-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *array;

    [dict setObject:NSStringFromClass([self class])
             forKey:RTKClass];

    [dict setObject:[RTKSharedDatabase stringForID:character]
             forKey:RTKFontCharacterKey];
    if(array = [glyphList propertyListRepresentation])
        [dict setObject:array
                 forKey:RTKGlyphList];

    return dict;
}


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    character = [RTKSharedDatabase idForString:[dict objectForKey:RTKFontCharacterKey]];
    glyphList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKGlyphList]];
}


-(int)character
{
    return character;
}

- (void)setGlyphList:(RTKLinkedListHeader *)theGlyphList
{
    [theGlyphList retain];
    [glyphList release];
    glyphList = theGlyphList;
}


-(RTKLinkedListHeader *)glyphList
{
    return glyphList;
}

-(int)order:(RTKFontCharacterDefinition *)other
{
    Class selfClass = [self class];
    Class otherClass = [other class];

    if(otherClass > selfClass)
        return 1; // after
    if(otherClass < selfClass)
        return -1; // before

    {
        int otherCharacter = [other character];

        if(otherCharacter > character)
            return 1;
        if(otherCharacter < character)
            return -1;
    }
    return 0;
}



@end

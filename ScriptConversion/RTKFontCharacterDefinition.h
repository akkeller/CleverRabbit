//
//  RTKFontCharacterDefinition.h
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import <Foundation/Foundation.h>
#import "RTKLinkedListHeader.h"
#import "RTKIDDatabase.h"

@interface RTKFontCharacterDefinition : NSObject 
{
    int character;
    RTKLinkedListHeader *glyphList;
}

-(id)initWithChildList:(RTKLinkedListHeader *)childList
       usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(RTKLinkedListHeader *)fontGlyphDefinitionListFromChildList:(RTKLinkedListHeader *)childList
					  usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(id)initWithCharacter:(int)theCharacter;
-(int)character;
-(RTKLinkedListHeader *)glyphList;
-(int)order:(RTKFontCharacterDefinition *)other;

@end

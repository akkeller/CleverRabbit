//
//  RTKFontGlyphDefinition.h
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

@interface RTKFontGlyphDefinition : NSObject 
{
    int name;

    RTKLinkedListHeader *regionList; // regions of cluster occupied
    
    RTKLinkedListHeader *incompatibleCharList;
    RTKLinkedListHeader *neededCharList;
    RTKLinkedListHeader *incompatibleGlyphList;
    
    RTKLinkedListHeader *beforePartialGlyphList;
    RTKLinkedListHeader *positionPartialGlyphList;
    RTKLinkedListHeader *afterPartialGlyphList;
}

-(RTKLinkedListHeader *)regionList;
-(RTKLinkedListHeader *)incompatibleCharList;
-(RTKLinkedListHeader *)neededCharList;
-(RTKLinkedListHeader *)incompatibleGlyphList;
-(RTKLinkedListHeader *)beforePartialGlyphList;
-(RTKLinkedListHeader *)positionPartialGlyphList;
-(RTKLinkedListHeader *)afterPartialGlyphList;

-(RTKLinkedListHeader *)regionListFromChildList:(RTKLinkedListHeader *)childList
			     usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(RTKLinkedListHeader *)charListFromChildList:(RTKLinkedListHeader *)childList
			   usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(RTKLinkedListHeader *)partialGlyphListFromChildList:(RTKLinkedListHeader *)childList
				   usingIDDatabase:(RTKIDDatabase *)idDatabase;

@end

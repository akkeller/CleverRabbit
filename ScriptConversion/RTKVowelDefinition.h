//
//  RTKVowelDefinition.h
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

@interface RTKVowelDefinition : NSObject 
{
    int phoneme;
    
    int character;
    int series;
}


-(id)initWithPhoneme:(int)thePhoneme;
-(id)initWithChildList:(RTKLinkedListHeader *)childList
       usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(NSDictionary *)propertyListRepresentation;
-(void)loadPropertyListRepresentation:(NSDictionary *)dict;
-(void)display;
-(int)phoneme;
-(int)order:(id)other;
-(int)character;
-(int)series;


@end

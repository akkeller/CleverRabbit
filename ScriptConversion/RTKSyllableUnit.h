//
//  RTKPunctuationGroupUnit.h
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


@interface RTKSyllableUnit : NSObject 
{
    int type;
    int idNumber;
    RTKLinkedListHeader * phonemeList;
    
    int firstConsonant;
    int secondConsonant;
    int vowel;
    int finalConsonant;
}

-(void)setFirstConsonant:(int)theFirstConsonant;
-(int)firstConsonant;
-(void)setSecondConsonant:(int)theSecondConsonant;
-(int)secondConsonant;
-(void)setVowel:(int)theVowel;
-(int)vowel;
-(void)setFinalConsonant:(int)theFinalConsonant;
-(int)finalConsonant;

-(void)setType:(int)theType;
-(int)type;
-(void)setID:(int)theID;
-(int)ID;
-(RTKLinkedListHeader *)phonemeList;
-(void)display;

@end

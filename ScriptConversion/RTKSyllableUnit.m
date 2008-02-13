//
//  RTKPunctuationGroupUnit.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKSyllableUnit.h"


@implementation RTKSyllableUnit


-(id)init
{
    if(self = [super init])
    {
        type = nil;
        idNumber = nil;
        phonemeList = [[RTKLinkedListHeader alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [phonemeList release];
    [super dealloc];
}

-(void)setFirstConsonant:(int)theFirstConsonant
{
    firstConsonant = theFirstConsonant;
}


-(int)firstConsonant
{
    return firstConsonant;
}


-(void)setSecondConsonant:(int)theSecondConsonant
{
    secondConsonant = theSecondConsonant;
}


-(int)secondConsonant
{
    return secondConsonant;
}


-(void)setVowel:(int)theVowel
{
    vowel = theVowel;
}


-(int)vowel
{
    return vowel;
}


-(void)setFinalConsonant:(int)theFinalConsonant
{
    finalConsonant = theFinalConsonant;
}


-(int)finalConsonant
{
    return finalConsonant;
}


-(void)setType:(int)theType
{
    type = theType;
}

-(int)type
{
    return type;
}

-(void)setID:(int)theID
{
    idNumber = theID;
}

-(int)ID
{
    return idNumber;
}

-(RTKLinkedListHeader *)phonemeList
{
    return phonemeList;
}

-(void)display
{
    NSLog(@"RTKPunctuationGroupUnit type: %i -- phonemeList...", type);
    [phonemeList display];
}

@end

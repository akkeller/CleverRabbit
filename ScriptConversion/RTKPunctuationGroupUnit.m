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



#import "RTKPunctuationGroupUnit.h"


@implementation RTKPunctuationGroupUnit


-(id)init
{
    if(self = [super init])
    {
		type = nil;
		idNumber = nil;
		punctuationList = [[RTKLinkedListHeader alloc] init];
    }
    return self;
}


// TODO: Fix later. Something here is autoreleased. Releasing it here results in an autorelease exception later.
/*
-(void)dealloc
{
    [punctuationList release];
    [super dealloc];
}
*/

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

-(RTKLinkedListHeader *)punctuationList
{
    return punctuationList;
}

-(void)display
{
    NSLog(@"RTKPunctuationGroupUnit -- punctuationList...");
    [punctuationList display];
}

@end

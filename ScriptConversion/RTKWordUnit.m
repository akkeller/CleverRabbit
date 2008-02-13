//
//  RTKWordUnit.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKWordUnit.h"


@implementation RTKWordUnit


-(id)init
{
    if(self = [super init])
    {
		type = nil;
		idNumber = nil;
		syllableList = [[RTKLinkedListHeader alloc] init];
    }
    return self;
}

-(void)dealloc
{
    [syllableList release];
    [super dealloc];
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

-(RTKLinkedListHeader *)syllableList
{
    return syllableList;
}


-(void)display
{
    NSLog(@"RTKWordUnit -- syllableList...");
    [syllableList display];
}


@end

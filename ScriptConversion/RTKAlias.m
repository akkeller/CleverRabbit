//
//  RTKAlias.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//


#import "RTKAlias.h"


@implementation RTKAlias

-(void)setOriginal:(id)theOriginal
{
    [theOriginal retain];
    [original release];
    
    original = theOriginal;
}

-(id)original
{
    return original;
}

-(id)initWithData:(id)data
{
    if(self = [super init])
    {
        [data retain];
        original = data;
    }
    return self;
}

-(void)dealloc
{
    [original release];
    [super dealloc];
}


@end

//
//  RTKLinkedListNode.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//



#import "RTKLinkedListNode.h"
#import "RTKLinkedListHeader.h"

@implementation RTKLinkedListNode


-(id)clone
{
	id theData = [data clone];
    id node = [[RTKLinkedListNode alloc] initWithData:theData];
	[theData release];
	return node;
}

-(void)setNext:(id)theNext
{
    next = theNext;
}

-(void)setBack:(id)theBack
{
    back = theBack;
}

-(void)setData:(id)theData
{
    [theData retain];
    [data release];
    data = theData;
}

-(id)next
{
    return next;
}

-(id)back
{
    return back;
}

-(id)data
{
    return data;
}


-(void)display
{
    [data display];
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[self data]];
}

-(id)initWithCoder:(NSCoder *)coder
{
    NSLog(@"initWithCoder--RTKLinkedListNode");
    if(self = [super init])
    {
        [self setData:[coder decodeObject]];
    }
    return self;
}



-(id)initWithData:(id)theData
{
    if(self = [super init])
    {
        [theData retain];
        data = theData;
    }
    return self;
}

-(id)initWithData:(id)theData
     atBackOfList:(RTKLinkedListHeader *)list
{
    if(self = [super init])
    {
        [theData retain];
        data = theData;
        [list insertAtBack:self];
        [self release];
    }
    return self;
}

-(id)initWithData:(id)theData
    atFrontOfList:(RTKLinkedListHeader *)list
{
    if(self = [super init])
    {
        [theData retain];
        data = theData;
        [list insertAtFront:self];
        [self release];
    }
    return self;
}

-(NSString *)description
{
    return [super description];
}

- (void)dealloc
{
    [data release];
    [super dealloc];
}


@end

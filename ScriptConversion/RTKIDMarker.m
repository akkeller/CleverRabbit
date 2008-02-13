//
//  RTKIDMarker.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKIDMarker.h"
#import "RTKIDDatabase.h"
#import "RTKGlobals.h"


@implementation RTKIDMarker


// persistence
NSString *RTKType = @"RTKType";
NSString *RTKidNumber = @"RTKidNumber";


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    type = [RTKSharedDatabase idForString:[dict objectForKey:RTKType]];
    idNumber = [RTKSharedDatabase idForString:[dict objectForKey:RTKidNumber]];
}



-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *idMarkerDict = [NSMutableDictionary dictionary];
	
    [idMarkerDict setObject:NSStringFromClass([self class])
                     forKey:RTKClass];
    [idMarkerDict setObject:[RTKSharedDatabase stringForID:type]
					 forKey:RTKType];
    [idMarkerDict setObject:[RTKSharedDatabase stringForID:idNumber]
                     forKey:RTKidNumber];
    return idMarkerDict;
}



-(void)display
{
    NSLog(@"RTKIDMarker -- idNumber %i type: %i", idNumber, type);
    
}

-(int)idNumber
{
    return idNumber;
}

-(void)setIDNumber:(int)theIDNumber
{
    idNumber = theIDNumber;
}

-(int)type
{
    return type;
}

-(void)setType:(int)theType
{
    type = theType;
}

-(int)order:(id)other
{
    {
		Class selfClass = [self class];
		Class otherClass = [other class];
		
		if(otherClass > selfClass)
			return 1; // after
		if(otherClass < selfClass)
			return -1; // before
    }
	
    if(type != 0)
    {
		int otherType = [(RTKIDMarker *)other type];
		
		if(otherType > type)
			return 1; // after
		if(otherType < type)
			return -1; // before
    }
    
    if(idNumber != 0)
    {
		int otherIDNumber = [other idNumber];
		
		if(otherIDNumber > idNumber)
			return 1; // after
		if(otherIDNumber < idNumber)
			return -1; // before
    }
    return 0; // same
}


-(BOOL)compare:(id)other
{
    if([other respondsToSelector:@selector(idNumber)]
	   && [other respondsToSelector:@selector(type)])
    {
		return ((idNumber == [other idNumber] || idNumber == 0)
				&& (type == (int)[(RTKIDMarker *)other type] || type == 0));
    }
    return NO;
}

-(id)init
{
    if(self = [super init])
    {
		idNumber = 0;
		type = 0;
    }
    return self;
}

-(id)initWithIDNumber:(int)theIDNumber
				 type:(int)theType
{
    if(self = [super init])
    {
		idNumber = theIDNumber;
		type = theType;
    }
    return self;
}


-(id)initWithIDNumber:(int)theIDNumber
{
    if(self = [super init])
    {
		idNumber = theIDNumber;
		type = 0;
    }
    return self;
}


-(id)clone
{
    return [[RTKIDMarker alloc] initWithIDNumber:idNumber
											type:type];
}

-(id)initWithIDCharList:(RTKLinkedListHeader *)idCharList
		   typeCharList:(RTKLinkedListHeader *)typeCharList
		  usingDatabase:(RTKIDDatabase *)idDatabase
{
    if(self = [super init])
    {
		if(idCharList != nil)
			idNumber = [idDatabase lookupIDNumber:idCharList];
		else
			idNumber = 0;
	    
		if(typeCharList != nil)    
			type = [idDatabase lookupIDNumber:typeCharList];
		else
			type = 0;
    }
    return self;
}


-(NSString *)description
{
    NSString *temp = [RTKSharedDatabase stringForID:idNumber];
    temp = [temp stringByAppendingString:@"/"];
    temp = [temp stringByAppendingString:[RTKSharedDatabase stringForID:type]];
	
    return temp;
}

@end

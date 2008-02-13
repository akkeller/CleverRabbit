//
//  RTKWrapper.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKWrapper.h"
#import "RTKLinkedListHeader.h"
#import "RTKIDDatabase.h"
#import "RTKGlobals.h"
#import "RTKIDMarker.h"

@implementation RTKWrapper


-(void)display // need to elaborate on this
{
    NSLog(@"RTKWrapper data");
    [data display];
    NSLog(@"RTKWrapper deleteFlag: %i", [self deleteFlag]);
    NSLog(@"RTKWrapper rightInsertList");
    [rightInsertList display];
    NSLog(@"RTKWrapper leftInsertList");
    [leftInsertList display];
}

-(void)setData:(id)theData
{
    [theData retain];
    [data release];
	
    data = theData;
}

-(id)data
{
    return data;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:data];
    [coder encodeValueOfObjCType:@encode(BOOL) 
                              at:&deleteFlag];
    [coder encodeObject:leftInsertList];
    [coder encodeObject:rightInsertList];
}

-(id)initWithCoder:(NSCoder *)coder
{
    if(self = [super init])
    {
		[self setData:[coder decodeObject]];
		[coder decodeValueOfObjCType:@encode(BOOL) 
                                  at:&deleteFlag];
		
		// don't do insertLink; that is only for use during parse
		
		[self setLeftInsertList:[coder decodeObject]];
		[self setRightInsertList:[coder decodeObject]];
    }
    return self;
}

-(id)initWithData:(id)theData
{
    if(self = [super init])
    {
		[theData retain];
        data = theData;
		
		deleteFlag = YES;
		leftInsertList = [[RTKLinkedListHeader alloc] init];
		rightInsertList = [[RTKLinkedListHeader alloc] init];
    }
    return self;
}

-(id)initWithData:(id)theData
       deleteFlag:(BOOL)theDeleteFlag
   leftInsertList:(id)theLeftInsertList
  rightInsertList:(id)theRightInsertList
{
    if(self = [super init])
    {
		[theData retain];
        data = theData;
		
		deleteFlag = theDeleteFlag;
		
		[theLeftInsertList retain];
		leftInsertList = theLeftInsertList;
		
		[theRightInsertList retain];
		rightInsertList = theRightInsertList;
    }
    return self;
}

-(id)init
{
    if(self = [super init])
    {
		deleteFlag = YES;
		leftInsertList = [[RTKLinkedListHeader alloc] init];
		rightInsertList = [[RTKLinkedListHeader alloc] init];
    }
    return self;
}


-(int)order:(id)other
{
    Class selfClass = [self class];
    Class otherClass = [other class];
    
    if(otherClass > selfClass)
		return 1; // after
    if(otherClass < selfClass)
		return -1; // before
	
    return [data order:(id)[other data]];
}

-(void)dealloc
{
    NSLog(@"RTKWrapper being dealloc-ed");
    [data release];
    [leftInsertList release];
    [rightInsertList release];
    [super dealloc];
}

-(void)setDeleteFlag:(BOOL)theDeleteFlag
{
    deleteFlag = theDeleteFlag;
}

-(BOOL)deleteFlag
{
    return deleteFlag;
}

-(void)setInsertLink:(id)theInsertLink
{
    insertLink = theInsertLink;  // don't want to retain
								 // should never be released while this is being used
}

-(id)insertLink
{
    return insertLink;
}

-(void)setLeftInsertList:(id)theList
{
    [theList retain];
    [leftInsertList release];
    
    leftInsertList = theList;
}

-(id)leftInsertList
{
    return leftInsertList;
}

-(void)setRightInsertList:(id)theList
{
    [theList retain];
    [rightInsertList release];
    
    rightInsertList = theList;
}

-(id)rightInsertList
{
    return rightInsertList;
}


// persistence

NSString *RTKData = @"RTKData";
NSString *RTKDeleteFlag = @"RTKDeleteFlag";
NSString *RTKLeftInsertList = @"RTKLeftInsertList";
NSString *RTKRightInsertList = @"RTKRightInsertList";


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    Class class = (Class) NSClassFromString([[dict objectForKey:RTKData] objectForKey:RTKClass]);
    if(class != nil)
    {
        data = [[class alloc] init];
        [data loadPropertyListRepresentation:[dict objectForKey:RTKData]];
    }
	
    deleteFlag = ([[dict objectForKey:RTKDeleteFlag] isEqualToString:@"YES"] ? YES : NO);
    
    if([dict objectForKey:RTKLeftInsertList])
        leftInsertList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKLeftInsertList]];
    if([dict objectForKey:RTKRightInsertList])
        rightInsertList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKRightInsertList]];
}


-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
    [dict setObject:NSStringFromClass([self class])
             forKey:RTKClass];
    
    if(data != nil)
        [dict setObject:[(RTKIDMarker *)data propertyListRepresentation] 
                 forKey:RTKData];

    [dict setObject:(deleteFlag ? @"YES" : @"NO") forKey:RTKDeleteFlag];
    
    if(leftInsertList != nil)
        [dict setObject:[leftInsertList propertyListRepresentation] 
                 forKey:RTKLeftInsertList];
    
    if(rightInsertList != nil)
        [dict setObject:[rightInsertList propertyListRepresentation] 
                 forKey:RTKRightInsertList];
	
    return dict;
}





-(NSString *)description
{
    return [data description];
}



@end

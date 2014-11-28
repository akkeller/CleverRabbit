//
//  RTKParsePattern.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//



#import "RTKParsePattern.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKWrapper.h"
#import "RTKIDDatabase.h"
#import "RTKFontCharacter.h"
#import "RTKIDMarker.h"
#import "RTKAlias.h"
#import "RTKGLobals.h"



@implementation RTKParsePattern

-(void)display
{
    NSLog(@"RTKParsePattern -- wrapperList");
    //[wrapperList display];
    [self shortDisplay];
}

-(void)shortDisplay
{
    NSMutableString *testString = [[NSMutableString alloc] init];
    
    RTKLinkedListNode *currentWrapperNode = [wrapperList first];
    while(currentWrapperNode != nil)
    {
        id currentWrapper = [currentWrapperNode data];
        unichar tempChar;
        
        if([[currentWrapper data] respondsToSelector:@selector(character)])
            tempChar = [(RTKFontCharacter *)[currentWrapper data] character];
        else if([[currentWrapper data] respondsToSelector:@selector(type)])
            tempChar = [(RTKIDMarker *)[currentWrapper data] type];
        else
            tempChar = '#';
        
        [testString appendString:
            [[NSString alloc] initWithCharacters:&tempChar
                                          length:(unsigned) 1]];
        currentWrapperNode = [currentWrapperNode next];
    }
    NSLog(@"%@", testString);
    [testString release];
}


-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[self wrapperList]];
}

-(id)initWithCoder:(NSCoder *)coder
{
    //NSLog(@"initWithCoder--RTKParsePattern");
    if(self = [super init])
    {
        [self setWrapperList:[coder decodeObject]];
    }
    return self;
}

-(id)init
{
    if(self = [super init]);
    {
        wrapperList = [[RTKLinkedListHeader alloc] init];
    }
    return self;
}

-(void)dealloc
{
    [wrapperList release];
    [super dealloc];
}

-(int)orderByString:(id)other
{
    Class selfClass = [self class];
    Class otherClass = [other class];
    
    if(otherClass > selfClass)
        return 1; // after
    if(otherClass < selfClass)
        return -1; // before
    
    return [wrapperList order:[other wrapperList]];
}

-(int)order:(id)other
{
    return [self orderByString:other];
}


-(void)setWrapperList:(RTKLinkedListHeader *)theWrapperList
{
    [theWrapperList retain];
    [wrapperList release];
    wrapperList = theWrapperList;
}


-(RTKLinkedListHeader *)wrapperList
{
    return wrapperList;
}


// persistence

NSString *RTKWrapperArray = @"RTKWrapperArray";


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    [wrapperList release];
    
    wrapperList = [[RTKLinkedListHeader alloc] initWithArray:[dict objectForKey:RTKWrapperArray]];
}


-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *wrapperArray = [wrapperList propertyListRepresentation];
    
    [dict setObject:NSStringFromClass([self class])
             forKey:RTKClass];
    
    if(wrapperArray != nil)
        [dict setObject:wrapperArray
                 forKey:RTKWrapperArray];
    
    return dict;
}


-(id)initWithWrapperList:(RTKLinkedListHeader *)theWrapperList
{
    if(self = [super init])
    {
        [theWrapperList retain];
        wrapperList = theWrapperList;
    }
    return self;
}


// --Takes a list of objects to insert clones of
// --Takes a list to insert them into
// --Takes a position to insert them to the left of
-(void)insert:(RTKLinkedListHeader *)insertList
         into:(RTKLinkedListHeader *)dataList
       leftOf:(id)insertionPosition
{
    if(insertionPosition != nil)
    {
        id currentDataUnit = [insertList first];
        while(currentDataUnit != nil)
        {
            RTKLinkedListNode *clone = [currentDataUnit clone];
            
            [dataList insert:clone before:insertionPosition];
            
            [clone release];
            
            currentDataUnit = [currentDataUnit next];
        }
    }
}

// --Takes a list of objects to insert clones of
// --Takes a list to insert them into
// --Takes a position to insert them to the right of
-(void)insert:(RTKLinkedListHeader *)insertList
         into:(RTKLinkedListHeader *)dataList
      rightOf:(id)insertionPosition
{
    if(insertionPosition != nil)
    {
        id currentDataUnit = [insertList last];
        while(currentDataUnit != nil)
        {
            RTKLinkedListNode *clone = [currentDataUnit clone];
            
            [dataList insert:clone after:insertionPosition];
            
            [clone release];
            
            currentDataUnit = [currentDataUnit back];
        }
    }
}


// --Takes a list to insert them into
-(void)insertInto:(RTKLinkedListHeader *)dataList
{
    id currentWrapperNode = [wrapperList first];
    while(currentWrapperNode != nil)
    {
        id insertLink = [(RTKWrapper *)[currentWrapperNode data] insertLink];
        if(insertLink != nil)
        {
            id leftInsertList = [(RTKWrapper *)[currentWrapperNode data] leftInsertList];
            id rightInsertList = [(RTKWrapper *)[currentWrapperNode data] rightInsertList];
            
            if(leftInsertList != nil)
                [self insert:leftInsertList into:dataList leftOf:insertLink];
            
            if(rightInsertList != nil)
                [self insert:rightInsertList into:dataList rightOf:insertLink];
            
            [(RTKWrapper *)[currentWrapperNode data] setInsertLink:nil];
        }
        currentWrapperNode = [currentWrapperNode next];
    }
}

// --Takes a list of aliases to objects to remove
// --Takes a list to remove them from
-(void)remove:(RTKLinkedListHeader *)aliasListToRemove
         from:(RTKLinkedListHeader *)dataList
{
    RTKLinkedListNode * currentAliasNode = [aliasListToRemove first];
    while(currentAliasNode != nil)
    {
        RTKLinkedListNode *original = [[currentAliasNode data] original];
        
        [dataList remove:original];
        
        currentAliasNode = [currentAliasNode next];
    }
    //[aliasListToRemove empty];
}


-(RTKLinkedListNode *)applyTo:(RTKLinkedListNode *)startingNode
                       inList:(RTKLinkedListHeader *)list
{
    RTKLinkedListHeader *aliasListToRemove = [[RTKLinkedListHeader alloc] init];
    RTKLinkedListNode *nextNode = [startingNode next];
    
    RTKLinkedListNode *currentWrapperNode = [wrapperList first];
    RTKLinkedListNode *currentDataNode = startingNode;
    
    while(currentDataNode != nil && currentWrapperNode != nil)
    {
        RTKWrapper *currentWrapper = [currentWrapperNode data];
        
        if([currentWrapper deleteFlag])
        {
            RTKAlias *alias = [[RTKAlias alloc] initWithData:(id)currentDataNode];
            [[RTKLinkedListNode alloc] initWithData:alias
                                       atBackOfList:aliasListToRemove];
            [alias release];
            
            if(nextNode == currentDataNode)
                nextNode = [nextNode next];
        }
        
        if([[currentWrapper rightInsertList] first] != nil
           || [[currentWrapper leftInsertList] first] != nil)
        {
            [currentWrapper setInsertLink:currentDataNode];
            
            if(nextNode == currentDataNode)
                nextNode = [nextNode next];
        }
        currentWrapperNode = [currentWrapperNode next];
        currentDataNode = [currentDataNode next];
    }
    [self insertInto:list];
    [self remove:aliasListToRemove from:list];
    [aliasListToRemove release];
    
    return nextNode;
}


-(NSString *)description
{
    NSString *temp = [[NSString alloc] init];
    RTKLinkedListNode *currentNode = [wrapperList first];
    while(currentNode != nil)
    {
        RTKWrapper *current = [currentNode data];
        temp = [temp stringByAppendingString:[current description]];
        temp = [temp stringByAppendingString:@" "];
        currentNode = [currentNode next];
    }
    return temp;
}


@end

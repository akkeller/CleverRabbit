//
//  RTKFilter.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKFilter.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKBinaryTreeHeader.h"
#import "RTKBinaryTreeNode.h"
#import "RTKAlias.h"
#import "RTKParsePattern.h"
#import "RTKIDDatabase.h"
#import "RTKWrapper.h"
#import "RTKFontCharacter.h"
#import "RTKGlobals.h"



@implementation RTKFilter

-(void)display
{
    NSLog(@"RTKFilter -- patternList %@", patternList);
    [patternList display];
}


-(id)init
{
    if(self = [super init])
    {
        patternList = [[RTKLinkedListHeader alloc] init];
        patternTree = nil;
    }
    return self;
}


-(void)dealloc
{
    [patternList release];
    [patternTree release];
    [super dealloc];
}


// Updates patternTree with the contents of patternList
-(void)updateTree
{
    RTKLinkedListNode *currentPatternNode;
    
    [patternTree release];
    patternTree = [[RTKBinaryTreeHeader alloc] init];
    
    currentPatternNode = [patternList first];
    while(currentPatternNode != nil)
    {
        RTKParsePattern *currentPattern = [currentPatternNode data];
        
        [patternTree insert:currentPattern];
        
        currentPatternNode = [currentPatternNode next];
    }
    [patternTree balance];
}


-(void)setPatternList:(RTKLinkedListHeader *)thePatternList
{
    [thePatternList retain];
    [patternList release];
    
    patternList = thePatternList;
    
    [self updateTree];
}


-(RTKLinkedListHeader *)patternList
{
    return patternList;
}


-(int)findPartialOrder:(RTKParsePattern *)pattern
                atNode:(RTKLinkedListNode *)dataNode
                 level:(int)level
               testing:(BOOL)testing
{
    int currentLevel = 0;
    RTKLinkedListNode *currentWrapperNode = [[pattern wrapperList] first];
    RTKLinkedListNode *currentDataNode = dataNode;
    
    if(level > [[pattern wrapperList] count])
        return 1;
    
    while(currentLevel++ < level && currentWrapperNode != nil && currentDataNode != nil)
    {
        RTKLinkedListNode *nextWrapperNode = [currentWrapperNode next];
        id currentWrapperData = [[currentWrapperNode data] data];
        id currentData = [currentDataNode data];
        
        int order = [currentWrapperData order:currentData];
        switch(order)
        {
            case 1: // after
            case -1: // before
                return order;
                break;
            case 0:
                if(nextWrapperNode == nil)
                    return 2; // complete match
                break;
        }
        
        currentWrapperNode = nextWrapperNode;
        currentDataNode = [currentDataNode next];
    }
    
    if(currentDataNode == nil && currentWrapperNode != nil)
        return -1; // before if data shorter than pattern
    
    return 0; // match but not complete
}


// Takes a starting position in a list of data
// returns longest pattern in patternTree that matches
-(RTKParsePattern *)findMatchingPattern:(RTKLinkedListNode *)startingNode
                                testing:(BOOL)testing
{
    RTKLinkedListHeader *partialMatchStack = [[RTKLinkedListHeader alloc] init];
    RTKParsePattern *matchingPattern = nil;
    RTKBinaryTreeNode *currentTreeNode = [patternTree first];
    int currentLevel = 1;
    BOOL partialMatch = NO;
    
    while(currentTreeNode != nil)
    {
        int order = [self findPartialOrder:[[[currentTreeNode instanceList] first] data]
                                    atNode:startingNode
                                     level:currentLevel
                                   testing:testing];	    
        switch(order)
        {
            case 1: // after  // could tune this up so it doesn't have to go to end of tree
                if(partialMatch == YES)
                {
                    if([currentTreeNode left] != nil)
                    {
                        [[RTKLinkedListNode alloc] initWithData:[currentTreeNode left]
                                                   atBackOfList:partialMatchStack];
                    }
                    partialMatch = NO;
                }
                currentTreeNode = [currentTreeNode right];
                currentLevel = 1;
                break;
            case -1: // before
                if(partialMatch == YES)
                {
                    if([currentTreeNode right] != nil)
                    {
                        [[RTKLinkedListNode alloc] initWithData:[currentTreeNode right]
                                                   atBackOfList:partialMatchStack];
                    }
                    partialMatch = NO;
                }
                currentTreeNode = [currentTreeNode left];
                currentLevel = 1;
                break;
            case 2: // match complete
                matchingPattern = [[[currentTreeNode instanceList] first] data];
                currentTreeNode = [currentTreeNode right];
                partialMatch = NO;                
                break;
            case 0: // matched but not complete
                partialMatch = YES;
                currentLevel++;
                break;
        }        
        if(currentTreeNode == nil)  
        {
            if(matchingPattern == nil)
            {
                // if we are at the end of the tree and nothing has completely matched,
                // pop another path off the stack
                currentTreeNode = [[partialMatchStack last] data];
                [partialMatchStack removeFromBack];
            }
        }        
    }
    [partialMatchStack release];
    return matchingPattern;
}


-(void)binaryParse:(RTKLinkedListHeader *)list
           testing:(BOOL)testing
{
    RTKLinkedListNode *currentUnitNode = [list first];
    
    if(patternTree == nil)
    {
        [self updateTree];
    }
    
    while(currentUnitNode != nil)
    {
        RTKParsePattern *matchingPattern = [self findMatchingPattern:currentUnitNode testing:testing];
        
        if(matchingPattern != nil)
        {
            currentUnitNode = [matchingPattern applyTo:currentUnitNode inList:list];
        }
        else
        {
            currentUnitNode = [currentUnitNode next];
        }
    } 
}


// --Takes a list of objects and parses it according to
// a list of patterns. 
-(void)parse:(RTKLinkedListHeader *)list
		   testing:(BOOL)testing
{
    [self binaryParse:list testing:testing];
}

// persistence

NSString *RTKPatternArray = @"RTKPatternArray";


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    id obj = [dict objectForKey:RTKPatternArray];
    
    if(obj != nil)
    {
        [patternList release];
        patternList = [[RTKLinkedListHeader alloc] initWithArray:obj];
    }
}


-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *filterDict = [NSMutableDictionary dictionary];
    NSMutableArray *patternArray = [patternList propertyListRepresentation];
    
    [filterDict setObject:NSStringFromClass([self class])
                   forKey:RTKClass];
    
    if(patternArray != nil)
        [filterDict setObject:patternArray
                       forKey:RTKPatternArray];
    
    return filterDict;
}


-(NSString *)description
{
    NSString *temp = [[NSString alloc] init];
    
    temp = [temp stringByAppendingString:[[[patternList first] data] description]];
    if([patternList count] > 1)
    {
        temp = [temp stringByAppendingString:@" "];
        temp = [temp stringByAppendingString:[[[patternList last] data] description]];
    }
    
    return temp;
}

@end

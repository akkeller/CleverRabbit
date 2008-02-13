//
//  RTKBinaryTreeNode.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//



#import "RTKBinaryTreeNode.h"
#import "RTKBinaryTreeHeader.h"

@implementation RTKBinaryTreeNode


-(id)init
{
    if(self = [super init])
    {
        left = nil;
        right = nil;
        instanceList = [[RTKLinkedListHeader alloc] init];
        order = ORDER_BY_STRING;
    }
    return self;
}


-(id)initWithOrder:(int)theOrder
{
    if(self = [super init])
    {
        left = nil;
        right = nil;
        instanceList = [[RTKLinkedListHeader alloc] init];
        order = theOrder;
    }
    return self;
}


-(void)dealloc
{
    [left release];
    [right release];
    [instanceList release];
    [super dealloc];
}


-(id)instanceList
{
    return instanceList;
}


-(id)left
{
    return left;
}


-(id)right
{
    return right;
}


-(void)setLeft:(id)theLeft
{
    [theLeft retain];
    [left release];
    
    left = theLeft;
}


-(void)setRight:(id)theRight
{
    [theRight retain];
    [right release];
    
    right = theRight;
}


-(RTKBinaryTreeNode *)findNode:(id)instance
{
    int orderOfInstance = 0;
    
    if(order == ORDER_BY_STRING)
        orderOfInstance = [[[instanceList first] data] orderByString:instance];
    else if(order == ORDER_BY_ID_NUMBER)
        orderOfInstance = [[[instanceList first] data] orderByIDNumber:instance];
    else
        orderOfInstance = [[[instanceList first] data] order:instance];
    switch(orderOfInstance)
    {
        case -1: // Before
            return [left findNode:instance];
        case 1: // After
            return [right findNode:instance];
        case 0: // Same
            return self;
    }
    return nil;
}


-(BOOL)instanceExists:(id)instance
{
    int orderOfInstance = 0;
    
    if(order == ORDER_BY_STRING)
        orderOfInstance = [[[instanceList first] data] orderByString:instance];
    else if(order == ORDER_BY_ID_NUMBER)
        orderOfInstance = [[[instanceList first] data] orderByIDNumber:instance];
    else
        orderOfInstance = [[[instanceList first] data] order:instance];
    
    switch(orderOfInstance)
    {
        case -1: // Before
            return [left instanceExists:instance];
        case 1: // After
            return [right instanceExists:instance];
        case 0: // Same
            return YES;
    }
    return NO;
}


-(BOOL)insertInstance:(id)instance  // return value says if new node added
{
    RTKLinkedListNode *node;
    int orderOfInstance = 0;
    
    if(order == ORDER_BY_STRING)
	    orderOfInstance = [[[instanceList first] data] orderByString:instance];
    else if(order == ORDER_BY_ID_NUMBER)
	    orderOfInstance = [[[instanceList first] data] orderByIDNumber:instance];
    else
	    orderOfInstance = [[[instanceList first] data] order:instance];
    
    switch(orderOfInstance)
    {
        case -1: // Before
            if(left != nil)
                return [left insertInstance:instance];
            left = [[RTKBinaryTreeNode alloc] initWithInstance:instance withOrder:order];
            return YES;
        case 1: // After
            if(right != nil)
                return [right insertInstance:instance];
            left = [[RTKBinaryTreeNode alloc] initWithInstance:instance withOrder:order];
            return YES;
        case 0: // Same
            node = [[RTKLinkedListNode alloc] initWithData:instance];
            [instanceList insertAtBack:node];
            [node release];
    }
    return NO;
}


-(BOOL)insertIfNoMatch:(id)instance
            returnNode:(id *)nodePtrAddr
                 steps:(unsigned *)stepsAddr
{
    int orderOfInstance = 0;
    (*stepsAddr)++; // This one took a while to find :o)
                    // (*stepsAddr)++ increments the value at the address, not the address...
                    // *stepsAddr++ increments the address, not the value at the address...
    
    if(order == ORDER_BY_STRING)
	    orderOfInstance = [[[instanceList first] data] orderByString:instance];	   
    else if(order == ORDER_BY_ID_NUMBER)
	    orderOfInstance = [[[instanceList first] data] orderByIDNumber:instance];
    else
	    orderOfInstance = [[[instanceList first] data] order:instance];
    
    switch(orderOfInstance)
    {
        case -1: // Before
            if(left != nil)
                return [left insertIfNoMatch:instance returnNode:nodePtrAddr steps:stepsAddr];
            left = [[RTKBinaryTreeNode alloc] initWithInstance:instance withOrder:order];
            if(nodePtrAddr != nil)
                *nodePtrAddr = left;
                return YES;
        case 1: // After
            if(right != nil)
                return [right insertIfNoMatch:instance returnNode:nodePtrAddr steps:stepsAddr];
            right = [[RTKBinaryTreeNode alloc] initWithInstance:instance withOrder:order];
            if(nodePtrAddr != nil)
                *nodePtrAddr = right;
                return YES;
        case 0: // Same
            if(nodePtrAddr != nil)
                *nodePtrAddr = self;
    }
    return NO;
}


-(id)initWithInstance:(id)instance
            withOrder:(int)theOrder
{
    if(self = [super init])
    {
        RTKLinkedListNode *node;
        
        left = nil;
        right = nil;
        instanceList = [[RTKLinkedListHeader alloc] init];
        node = [[RTKLinkedListNode alloc] initWithData:instance];
        [instanceList insertAtBack:node];
        [node release];
        order = theOrder;
    }
    return self;
}


-(void)contentsToArray:(NSMutableArray *)nodeArray
{
    [left contentsToArray:nodeArray];
    
    [nodeArray addObject:self];
    
    [right contentsToArray:nodeArray];
}


-(void)rebuildFromArray:(NSMutableArray *)nodeArray
                current:(unsigned)current
                  start:(unsigned)start
                   stop:(unsigned)stop
{
    if(start < current)
    {
        unsigned leftPosition = (start + current) / 2;
        left = [nodeArray objectAtIndex:leftPosition];
        [left rebuildFromArray:nodeArray current:leftPosition start:start stop:(current - 1)];
    }
    else
    {
        left = nil;
    }
	
    if(current < stop)
    {
        unsigned rightPosition = (current + stop + 1) / 2;
        right = [nodeArray objectAtIndex:rightPosition];
        [right rebuildFromArray:nodeArray current:rightPosition start:(current + 1) stop:stop];
    }
    else
    {
        right = nil;
    }    
}


-(void)display
{
    [left display];
    NSLog(@"RTKBinaryTreeNode -- order: %i instanceList", order);
    [instanceList display];
    [right display];
}


@end

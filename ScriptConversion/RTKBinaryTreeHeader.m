//
//  RTKBinaryTreeHeader.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//


#import "RTKBinaryTreeHeader.h"

#define MAXPOWERDIFFERENCE 10


const int
ORDER_BY_STRING = 1,
ORDER_BY_ID_NUMBER = 2,
ORDER_BY_DEFAULT = 3;

@implementation RTKBinaryTreeHeader

-(id)init
{
    if(self = [super init])
    {
        first = nil;
        nodeCount = 0;
        order = ORDER_BY_STRING;
        lock = [[NSLock alloc] init];
    }
    return self;
}

-(id)initWithOrder:(int)theOrder
{
    if(self = [super init])
    {
        first = nil;
        nodeCount = 0;
        order = theOrder;
        lock = [[NSLock alloc] init];
    }
    return self;
}

-(id)initWithList:(RTKLinkedListHeader *)list
{
    if(self = [super init])
    {
        first = nil;
        nodeCount = 0;
        order = ORDER_BY_DEFAULT;
        lock = [[NSLock alloc] init];
        {
            RTKLinkedListNode *currentNode = [list first];
            while(currentNode != nil)
            {
                id currentNodeData = [currentNode data];
                if(currentNodeData != nil)
                {
                    [self insert:currentNodeData];
                }
                currentNode = [currentNode next];
            }
        }
        if(first != nil)
        {
            [self balance];
        }
    }
    return self;
}

-(void)dealloc
{
    [first release];
    [lock release];
    [super dealloc];
}

-(void)display
{
    [lock lock];
    NSLog(@"RTKBinaryTreeHeader -- nodeCount: %i order: %i", nodeCount, order);
    [first display];
    [lock unlock];
}

-(id)first
{
    return first;
}

-(BOOL)instanceExists:(id)instance
{
    BOOL theInstance;
    [lock lock];
    theInstance = [first instanceExists:instance];
    [lock unlock];
    return theInstance;
}

-(RTKBinaryTreeNode *)findNode:(id)instance
{
    RTKBinaryTreeNode *theNode;
    [lock lock];
    theNode = [first findNode:instance];
    [lock unlock];
    return theNode;
}

-(void)insert:(id)instance
{
    int steps = 0;
    if(instance != nil)
    {
        [lock lock];
        if(first != nil)
        {
            RTKBinaryTreeNode *currentNode = first;
            while(currentNode != nil)
            {
                steps++;
                switch((int)[[[[currentNode instanceList] first] data] order:instance]) // maybe not right
                {
                    RTKBinaryTreeNode *left, *right;
                    case -1:
                        left = [currentNode left];
                        if(left != nil)
                        {
                            currentNode = left;
                        }
                            else
                            {
                                left = [[RTKBinaryTreeNode alloc] initWithOrder:order];
                                [[RTKLinkedListNode alloc] initWithData:instance
                                                           atBackOfList:[left instanceList]];
                                [currentNode setLeft:left];
                                [left release];
                                nodeCount++;
                                goto afterInsert;
                            }
                            break;
                    case 1:
                        right = [currentNode right];
                        if(right != nil)
                        {
                            currentNode = right;
                        }
                            else
                            {
                                right = [[RTKBinaryTreeNode alloc] initWithOrder:order];
                                [[RTKLinkedListNode alloc] initWithData:instance
                                                           atBackOfList:[right instanceList]];
                                [currentNode setRight:right];
                                [right release];
                                nodeCount++;
                                goto afterInsert;
                            }
                            break;
                    case 0:
                        [[RTKLinkedListNode alloc] initWithData:instance
                                                   atBackOfList:[currentNode instanceList]];
                    default:
                        goto afterInsert;
                        break;
                }
            }
afterInsert:
            {
            }
        }
        else
        {
            first = [[RTKBinaryTreeNode alloc] initWithOrder:order];
            [[RTKLinkedListNode alloc] initWithData:instance
                                       atBackOfList:[first instanceList]];
            nodeCount++;
        }
        [lock unlock];
    }
    
    if(steps > MAXPOWERDIFFERENCE)
    {
        if(1<<(steps - MAXPOWERDIFFERENCE) > nodeCount)
        {
            [self balance];
        }
    }
}


-(BOOL)insertIfNoMatch:(id)instance
            returnNode:(id *)nodeAddr
{
    BOOL insertedNewNode = NO;
    unsigned steps = 0;
    unsigned *stepsAddr = &steps;
    BOOL needsBalance = NO;
    [lock lock];
    if(first != nil)
    {
        if([first insertIfNoMatch:instance
                       returnNode:nodeAddr
                            steps:stepsAddr])
        {
            nodeCount++;
            
            if(steps > MAXPOWERDIFFERENCE)
            {
                if(1<<(steps - MAXPOWERDIFFERENCE) > nodeCount)
                {
                    needsBalance = YES;
                }
            }
            insertedNewNode = YES;
        }
    }
    else
    {
        first = [[RTKBinaryTreeNode alloc] initWithInstance:instance withOrder:order];
        if(nodeAddr != nil)
            *nodeAddr = first;
        nodeCount++;
        insertedNewNode = YES;
    }
    [lock unlock];
    
    if(needsBalance)
        [self balance];
    
    return insertedNewNode;
}

-(void)balance
{
    [lock lock];
    {
        unsigned current = nodeCount / 2;
        
        NSMutableArray *nodeArray = [[NSMutableArray alloc] initWithCapacity:nodeCount]; 
        
        [first contentsToArray:nodeArray];
        
        first = [nodeArray objectAtIndex:current];
        
        // Returns the topmost node of a (now) balanced tree including first
        [first rebuildFromArray:nodeArray current:current start:0 stop:(nodeCount-1)];

        [nodeArray release];
	}
    [lock unlock];
}

@end

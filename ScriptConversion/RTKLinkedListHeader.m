//
//  RTKLinkedListHeader.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKGlobals.h"
#import "RTKIDMarker.h"


@implementation RTKLinkedListHeader


-(id)init
{
    if(self = [super init])
    {
        first = nil;
        last = nil;
        count = 0;
    }
    return self;
}


- (id)initWithFirst:(RTKLinkedListNode *)theFirst
               last:(RTKLinkedListNode *)theLast
              count:(int)theCount
{
    
    if(self = [super init])
    {
        first = theFirst;
        last = theLast;
        count = theCount;
    }
    return self;
}


-(void)append:(RTKLinkedListHeader *)otherList
{
    if(otherList != nil)
    {
        if(first == nil)
        {
            first = otherList->first;
            last = otherList->last;
        }
        else
        {
            if(otherList->first != nil)
            {
                last->next = otherList->first;
                (otherList->first)->back = last;
                last = otherList->last;
            }
        }
        count += otherList->count;
        
        otherList->first = nil;
        otherList->last = nil;
        otherList->count = 0;
    }
}


-(void)prepend:(RTKLinkedListHeader *)otherList
{
    if(otherList != nil)
    {
        if(first == nil)
        {
            first = otherList->first;
            last = otherList->last;
        }
        else
        {
            if(otherList->first != nil)
            {
                first->back = otherList->last;
                (otherList->last)->next = first;
                
                first = otherList->first;
            }
        }
        count += otherList->count;
        
        otherList->first = nil;
        otherList->last = nil;
        otherList->count = 0;
    }
}


-(NSArray *)array
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    RTKLinkedListNode *currentNode = first;
    while(currentNode != nil)
    {
        id current = currentNode->data;
        
        if(current != nil)
        {
            [array addObject:current];
        }
        currentNode = currentNode->next;
    }
    return array;
}


-(id)initWithArray:(NSArray *)array
{
    if(self = [super init])
    {
        first = nil;
        last = nil;
        count = 0;
        
        {
            int i, c = [array count];
            for(i = 0; i < c; i++)
            {
                NSDictionary *dict = [array objectAtIndex:i];
                NSString *classString = [dict objectForKey:RTKClass];
                
				Class class = NSClassFromString(classString);
				
                if(class != nil)
                {
                    id data = [[class alloc] init];
                    
                    [(RTKIDMarker *)data loadPropertyListRepresentation:dict];
                    
                    /* could be tightend */
                    [[RTKLinkedListNode alloc] initWithData:data  
                                               atBackOfList:self];
                    [data release];
                }
                else
                {
                    NSLog(@"Unknown class %@", classString);
                }
            }
        }
    }
    return self;
}


-(NSArray *)propertyListRepresentation
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:count];
    
    RTKLinkedListNode *currentNode = first;
    while(currentNode != nil)
    {
        [array addObject:[(RTKIDMarker *)currentNode->data propertyListRepresentation]];
        currentNode = currentNode->next;
    }
    return array;
}


-(id)initWithCoder:(NSCoder *)coder
{
    NSLog(@"initWithCoder--RTKLinkedListHeader");
    if(self = [super init])
    {
        int i;
        int tempCount;
        [coder decodeValueOfObjCType:@encode(int) at:&tempCount];
        
        first = nil;
        last = nil;
        count = 0;
        
        for(i = 0; i < tempCount; i++) /* could be tightend */
        {
            [self insertAtBack:[coder decodeObject]];
        }
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)coder
{
    RTKLinkedListNode * current;
    
    [coder encodeValueOfObjCType:@encode(int) at:&count];
    
    current = first;
    while(current != nil)
    {
        [current encodeWithCoder:coder];
        
        current = current->next;
    }
}


-(RTKLinkedListNode *)first{return first;}
-(RTKLinkedListNode *)last{return last;}
-(void)setFirst:(id)theFirst{first = theFirst;}
-(void)setLast:(id)theLast{last = theLast;}
-(void)setCount:(int)theCount{count = theCount;}
-(int)count{return count;}


-(RTKLinkedListHeader*)clone  // Inefficient--but it works...
{
    RTKLinkedListHeader* newList = [[RTKLinkedListHeader alloc] init];
    RTKLinkedListNode* currentNode = first;
    
    while(currentNode != nil)
    {
        [newList insertAtBack:[currentNode clone]];
        [newList->last release];
        currentNode = currentNode->next;
    }
    return newList;
}


-(int)order:(RTKLinkedListHeader *)other
{
    if(other != nil)
    {
        RTKLinkedListNode * currentNode = first;
        RTKLinkedListNode * currentOtherNode = other->first;
        
        while(currentNode != nil && currentOtherNode != nil)
        {
            int currentOrder = (currentNode->data != 0 && currentOtherNode->data != 0)
            ? [currentNode->data order:currentOtherNode->data] : 0;
            
            if(currentOrder != 0) // if they are not the same
                return currentOrder;
            
            currentNode = currentNode->next;
            currentOtherNode = currentOtherNode->next;
        }
        
        if(currentNode == nil && currentOtherNode == nil)
            return 0; // same if both at end
        
        if(currentNode == nil )
            return 1; // after if other one is longer
        
        return -1; // before if other one is shorter
    }
    return -1;  // if other==nil this method shouldn't have been called anyway...
}


-(RTKLinkedListNode *)insert:(RTKLinkedListNode *)newNode
                      before:(RTKLinkedListNode *)oldNode
{
    if(newNode != nil && oldNode != nil)
    {
        newNode->next = oldNode;
        newNode->back = oldNode->back;
        
        if(first == oldNode)
            first = newNode;
        else
            (oldNode->back)->next = newNode;
        
        oldNode->back = newNode;
        
        
        count++;
        
        [newNode retain];
    }
    
    return newNode;
}


-(RTKLinkedListNode *)insert:(RTKLinkedListNode *)newNode
                       after:(RTKLinkedListNode *)oldNode
{
    if(newNode != nil && oldNode != nil)
    {
        newNode->back = oldNode;
        newNode->next = oldNode->next;
        
        if(last == oldNode)
            last = newNode;
        else
            (oldNode->next)->back = newNode;
        
        oldNode->next = newNode;
        
        
        count++;
        
        [newNode retain];
    }
    
    return newNode;
}


-(RTKLinkedListNode *)insertAtFront:(RTKLinkedListNode *)newNode
{
    if(newNode != nil)
    {
        if(first == nil)
        {
            last = newNode;
            newNode->next = nil;
        }
        else
        {
            first->back = newNode;
            newNode->next = first;
        }
        first = newNode;
        newNode->back = nil;
        
        count++;
        
        [newNode retain];
    }
    
    return newNode;
}


-(RTKLinkedListNode *)insertAtBack:(RTKLinkedListNode *)newNode
{
    if(newNode != nil)
    {
        if(first == nil)
        {
            first = newNode;
            newNode->back = nil;
        }
        else
        {
            last->next = newNode;
            newNode->back = last;
        }
        last = newNode;
        newNode->next = nil;
        
        count++;
        
        [newNode retain];
    }
    
    return newNode;
}


-(RTKLinkedListNode *)remove:(RTKLinkedListNode *)node
{
    if(node != nil)
    {
        if(first == last)
        {
            first = nil;
            last = nil;
        }
        else
        {
            if(first == node)
                first = node->next;
            else
                (node->back)->next = node->next;
            
            if(last == node)
                last = node->back;
            else
                (node->next)->back = node->back;
        }
        count--;
        [node release];
    }
    return node;
}


-(RTKLinkedListNode *)removeFromFront
{
    RTKLinkedListNode * node = first;
    if(node != nil)
    {
        first = first->next;
        
        if(first == nil)
            last = nil;
        else
            first->back = nil;
        
        count--;
        [node release];
    }
    
    return node;
}


-(RTKLinkedListNode *)removeFromBack
{
    RTKLinkedListNode * node = last;
    if(node != nil)
    {
        last = last->back;
        
        if(last == nil)
            first = nil;
        else
            last->next = nil;
        
        count--;
        [node release];
    }
    
    return node;
}


-(void)dealloc
{
    RTKLinkedListNode * node = first;
    while(node != nil)
    {
        RTKLinkedListNode * nextNode = node->next;
        
        [node release];
        
        node = nextNode;
    }
    
    [super dealloc];
}


-(void)empty
{
    RTKLinkedListNode * node = first;
    while(node != nil)
    {
        RTKLinkedListNode * nextNode = node->next;
        
        [node release];
        
        node = nextNode;
    }
    
    count = 0;
    first = nil;
    last = nil;
}


-(void)display
{
    RTKLinkedListNode * node;
	
    node = first;
    while(node != nil)
    {
        [node display];
        
        node = node->next;
    }
}

@end

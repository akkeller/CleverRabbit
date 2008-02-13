//
//  RTKLinkedListHeader.h
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import <Foundation/Foundation.h>
#import "RTKLinkedListNode.h"

@interface RTKLinkedListHeader : NSObject <NSCoding>
{
    RTKLinkedListNode * first;
    RTKLinkedListNode * last;
    int count;
    NSLock *lock;
}

-(void)encodeWithCoder:(NSCoder *)coder;
-(id)initWithCoder:(NSCoder *)coder;

-(NSArray *)array;

-(id)initWithArray:(NSArray *)array;
-(NSArray *)propertyListRepresentation;


-(id)init;

- (id)initWithFirst:(RTKLinkedListNode *)theFirst
	       last:(RTKLinkedListNode *)theLast
	      count:(int)theCount;
	      
-(void)append:(RTKLinkedListHeader *)otherList;
-(void)prepend:(RTKLinkedListHeader *)otherList;
- (void)empty;
	      
-(RTKLinkedListNode *)first;
-(RTKLinkedListNode *)last;
-(void)setFirst:(id)theFirst;
-(void)setLast:(id)theLast;
-(void)setCount:(int)theCount;

-(int)count;

-(RTKLinkedListHeader *)clone;

-(RTKLinkedListNode *)insertAtFront:(RTKLinkedListNode *)newNode;
-(void)display;

-(RTKLinkedListNode *)insert:(RTKLinkedListNode *)newNode
     before:(RTKLinkedListNode *)oldNode;
     
-(RTKLinkedListNode *)insert:(RTKLinkedListNode *)newNode
      after:(RTKLinkedListNode *)oldNode;

-(RTKLinkedListNode *)insertAtFront:(RTKLinkedListNode *)newNode;
-(RTKLinkedListNode *)insertAtBack:(RTKLinkedListNode *)newNode;

-(RTKLinkedListNode *)remove:(RTKLinkedListNode *)node;
-(RTKLinkedListNode *)removeFromFront;
-(RTKLinkedListNode *)removeFromBack;

-(int)order:(id)other;


@end

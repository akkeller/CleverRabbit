//
//  RTKBinaryTreeNode.h
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
#import "RTKLinkedListHeader.h"

@interface RTKBinaryTreeNode : NSObject
{
    id left;
    id right;
    RTKLinkedListHeader * instanceList;
    int order;
}


-(id)instanceList;

-(id)left;
-(id)right;
-(void)setLeft:(id)theLeft;
-(void)setRight:(id)theRight;

-(RTKBinaryTreeNode *)findNode:(id)instance;

-(BOOL)instanceExists:(id)instance;

-(BOOL)insertInstance:(id)instance;  // return value says if new node added

-(BOOL)insertIfNoMatch:(id)instance
	    returnNode:(id *)nodePtrAddr
	         steps:(unsigned *)stepsAddr;

-(id)initWithInstance:(id)instance
	    withOrder:(int)theOrder;
	    
-(void)display;

-(void)contentsToArray:(NSMutableArray *)nodeArray;

-(void)rebuildFromArray:(NSMutableArray *)nodeArray
		current:(unsigned)current
		  start:(unsigned)start
		   stop:(unsigned)stop;

@end

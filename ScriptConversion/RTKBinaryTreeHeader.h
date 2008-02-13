//
//  RTKBinaryTreeHeader.h
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
#import "RTKBinaryTreeNode.h"

extern const int ORDER_BY_STRING,
		ORDER_BY_ID_NUMBER,
		 ORDER_BY_DEFAULT;

@interface RTKBinaryTreeHeader : NSObject
{
    RTKBinaryTreeNode * first;
    int nodeCount;
    int order;
    NSLock *lock;
}



-(void)display;

-(id)initWithOrder:(int)theOrder;
-(id)initWithList:(RTKLinkedListHeader *)list;

-(id)first;

-(RTKBinaryTreeNode *)findNode:(id)instance;

-(void)insert:(id)instance;

-(BOOL)instanceExists:(id)instance;

-(BOOL)insertIfNoMatch:(id)instance
	    returnNode:(id *)nodeAddr;
	    
-(void)balance;


@end

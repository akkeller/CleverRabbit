//
//  RTKParsePattern.h
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

@interface RTKParsePattern : NSObject <NSCoding>
{
    RTKLinkedListHeader * wrapperList;
}

-(void)display;
-(void)shortDisplay;
-(void)setWrapperList:(RTKLinkedListHeader *)theWrapperList;
-(RTKLinkedListHeader *)wrapperList;

-(void)insert:(id)insertList
         into:(id)dataList
       leftOf:(id)insertionPosition;
       
-(void)insert:(id)insertList
         into:(id)dataList
      rightOf:(id)insertionPosition;
      
-(void)insertInto:(RTKLinkedListHeader *)dataList;

-(id)initWithWrapperList:(RTKLinkedListHeader *)theWrapperList;

-(void)initWithString:(NSString *)string
	         type:(int)type
	     position:(int)position
       insertAtBackOf:(RTKLinkedListHeader *)list;

-(RTKLinkedListNode *)applyTo:(RTKLinkedListNode *)startingNode
		    inList:(RTKLinkedListHeader *)list;

-(int)orderByString:(id)other;


@end

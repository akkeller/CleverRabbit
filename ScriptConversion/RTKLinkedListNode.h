//
//  RTKLinkedListNode.h
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

@class RTKLinkedListHeader;

@interface RTKLinkedListNode : NSObject <NSCoding>
{
    @public
    RTKLinkedListNode * next;
    RTKLinkedListNode * back;
    id data;
}

-(void)encodeWithCoder:(NSCoder *)coder;
-(id)initWithCoder:(NSCoder *)coder;

-(id)clone;

-(void)setNext:(id)theNext;
-(void)setBack:(id)theBack;
-(void)setData:(id)theData;

-(id)next;
-(id)back;
-(id)data;
//-(int)number;

-(void)display;
-(id)initWithData:(id)theData;

-(id)initWithData:(id)theData
     atBackOfList:(RTKLinkedListHeader *)list;
-(id)initWithData:(id)theData
     atFrontOfList:(RTKLinkedListHeader *)list;

@end

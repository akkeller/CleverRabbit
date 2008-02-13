//
//  RTKWrapper.h
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

@interface RTKWrapper : NSObject <NSCoding>
{
    id data;    // the object this RTKWrapper references

    // now some flags for contextual parsing
    BOOL deleteFlag;
    // add these later for optimization

    id insertLink;
    RTKLinkedListHeader *leftInsertList;
    RTKLinkedListHeader *rightInsertList;
    
}

-(id)initWithData:(id)theData
       deleteFlag:(BOOL)theDeleteFlag
   leftInsertList:(id)theLeftInsertList
  rightInsertList:(id)theRightInsertList;


-(void)encodeWithCoder:(NSCoder *)coder;
-(id)initWithCoder:(NSCoder *)coder;


-(void)display;

-(void)setData:(id)data;
-(id)data;
-(id)initWithData:(id)data;

-(void)setDeleteFlag:(BOOL)theDeleteFlag;
-(BOOL)deleteFlag;
-(void)setInsertLink:(id)theInsertLink;
-(id)insertLink;
-(void)setLeftInsertList:(id)theList;
-(id)leftInsertList;
-(void)setRightInsertList:(id)theList;
-(id)rightInsertList;



@end

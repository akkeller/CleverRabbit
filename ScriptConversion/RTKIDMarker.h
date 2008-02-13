//
//  RTKIDMarker.h
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
#import "RTKIDDatabase.h"


@interface RTKIDMarker : NSObject
{
    int idNumber;
    int type;
}

-(void)display;

-(int)idNumber;
-(void)setIDNumber:(int)theIDNumber;

-(int)type;
-(void)setType:(int)theType;

-(BOOL)compare:(id)other;

-(id)initWithIDCharList:(RTKLinkedListHeader *)idCharList
	   typeCharList:(RTKLinkedListHeader *)typeCharList
	  usingDatabase:(RTKIDDatabase *)idDatabase;
	  
-(id)initWithIDNumber:(int)theIDNumber
		 type:(int)theType;
                 
-(id)initWithIDNumber:(int)theIDNumber;

-(id)clone;

-(NSDictionary *)propertyListRepresentation;
-(void)loadPropertyListRepresentation:(NSDictionary *)dict;

@end

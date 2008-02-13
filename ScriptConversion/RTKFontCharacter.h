//
//  RTKFontCharacter.h
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


@interface RTKFontCharacter : NSObject <NSCoding>
{
    unichar character;
    
}


-(void)encodeWithCoder:(NSCoder *)coder;
-(id)initWithCoder:(NSCoder *)coder;

-(id)initWithCharacter:(unichar)theCharacter;

-(id)clone;

-(unichar)character;
-(void)setCharacter:(unichar)theCharacter;

-(BOOL)compare:(id)other;

-(void)display;

-(int)order:(id)other;

-(int)orderByString:(id)other;


@end



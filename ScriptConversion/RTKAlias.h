//
//   RTKAlias.h
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


@interface RTKAlias : NSObject 
{
    id original;
}
-(void)setOriginal:(id)original;
-(id)original;
-(id)initWithData:(id)data;


@end

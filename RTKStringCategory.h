//
//   RTKStringCategory.h
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import <Cocoa/Cocoa.h>


@interface NSString (RTKStringCategory) 

- (NSString *)verse;
- (NSString *)chapter;
- (NSString *)book;
- (NSData *)utf8Data;
- (BOOL)containsSubstring:(NSString *)substring;
- (BOOL)containsCaseInsensitiveSubstring:(NSString *)substring;

@end

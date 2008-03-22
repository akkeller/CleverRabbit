//
//   RTKMutableAttributedStringCategory.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2008 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//


#import "RTKMutableAttributedStringCategory.h"


@implementation NSMutableAttributedString (RTKMutableAttributedStringCategory)

- (void)superscript
{
    [self superscriptRange:NSMakeRange(0, [self length])];
}

- (void)subscript
{
    [self subscriptRange:NSMakeRange(0, [self length])];
}

- (void)smallFontSize
{
    [self addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica" size:9.0]];
}
- (void)largeFontSize
{
    [self addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica" size:14.0]];
}

- (void)addAttribute:(NSString *)name value:(id)value
{
    [self addAttribute:name value:value range:NSMakeRange(0, [self length])];
}

@end

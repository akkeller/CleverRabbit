//
//   RTKTigerTextView.h
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


@interface RTKTigerTextView : NSTextView
{
    IBOutlet NSWindow * window;
    IBOutlet NSTextView * nextTextView;
    
    NSMutableString * originalString;
    
    NSDictionary * characterSwaps;
    
    NSRange allowedEditingRange;
}


- (void)insertText:(id)aString;
- (void)setCharacterSwaps:(NSDictionary *)theCharacterSwaps;

- (void)setAllowEditing:(BOOL)allow;
- (void)setAllowedEditingRange:(NSRange)range;


@end

//
//   RTKTigerTextView.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import "RTKTigerTextView.h"

@implementation RTKTigerTextView


/*
 This NSTextView subclass allows one to define substitutions for characters.
 Subclassing like this isn't the best way to implemement it. Creating a delegate
 of the text storage container would be cleaner.
 */

- (id)init
{
    if(self = [super init]) {
        [self setOriginalString:[NSMutableString stringWithString:@""]];
    }
    return self;
}

- (void)dealloc
{
    [characterSwaps release];
    [originalString release];
    
    [super dealloc];
}

- (void)insertText:(id)aString
{
    if([aString isEqualToString:@"\t"]) {
        if(!window)
            NSLog(@"window not set");
        [window makeFirstResponder:nextTextView];
    } else {
        NSNumber * charObject;
        unichar character = [aString characterAtIndex:0];

        if(charObject = [characterSwaps objectForKey:aString])
            character = [charObject intValue];
        
        [super insertText:[NSString stringWithCharacters:&character length:1]];
    }
}

- (void)setCharacterSwaps:(NSDictionary *)theCharacterSwaps
{
    [theCharacterSwaps retain];
    [characterSwaps release];
    characterSwaps = theCharacterSwaps;
}

- (void)setOriginalString:(NSMutableString *)theOriginalString
{
    [theOriginalString retain];
    [originalString release];    
    originalString = theOriginalString;
}

- (NSMutableString *)originalString
{
    return originalString;
}

@end

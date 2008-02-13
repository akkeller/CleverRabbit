//
//  RTKGlyphAlias.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKGlyphAlias.h"


@implementation RTKGlyphAlias

-(id)initWithCharacter:(RTKFontCharacterDefinition *)theCharacter
{
    if(self = [super init])
    {

        // Nothing is retained by this object.
        // This is by design.
        // Its lifespan should be shorter than everything it references.

        character = theCharacter;

        glyphNode = [[character glyphList] first];
        glyph = [glyphNode data];
    }
    return self;
}


-(RTKFontGlyphDefinition *)glyph
{
    return glyph;
}


-(BOOL)click
{
    glyphNode = [glyphNode next];

    if(glyphNode == nil)
    {
        glyphNode = [[character glyphList] first];
        glyph = [glyphNode data];
        return NO;
    }
    glyph = [glyphNode data];
    return YES;
}



@end

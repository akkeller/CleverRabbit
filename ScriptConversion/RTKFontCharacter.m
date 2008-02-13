//
//  RTKFontCharacter.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKFontCharacter.h"
#import "RTKGlobals.h"

@implementation RTKFontCharacter

// persistence

NSString *RTKCharacter = @"RTKCharacter";


-(void)loadPropertyListRepresentation:(NSDictionary *)dict
{
    NSString *hexString = [dict objectForKey:RTKCharacter];
    
    int i, l = [hexString length];
    unichar c, u = 0;
    
    for(i = 0; i < l; i++)
    {
        u <<= 4;
        c = [hexString characterAtIndex:i];
        
        if(c >= (unichar) '0' && c <= (unichar) '9')
        {
            c -= (unichar) '0';
        }
        else if(c >= (unichar) 'a' && c <= (unichar) 'f')
        {
            c -= (unichar) 'a' - 0xa;
        }
        else if(c >= (unichar) 'A' && c <= (unichar) 'F')
        {
            c -= (unichar) 'A' - 0xa;
            
        }
        else
        {
            character = 0;
            return;
        }
        u += c;
    }
    character = u;
}


-(NSDictionary *)propertyListRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:NSStringFromClass([self class])
             forKey:RTKClass];
    [dict setObject:[[NSString alloc] initWithFormat:@"%x", character]
             forKey:RTKCharacter];
    
    return dict;
}


-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeValueOfObjCType:@encode(unichar) at:&character];
}

-(id)initWithCoder:(NSCoder *)coder
{
    if(self = [super init])
    {
        [coder decodeValueOfObjCType:@encode(unichar) at:&character];
    }
    return self;
}

-(id)initWithCharacter:(unichar)theCharacter
{
    if(self = [super init])
    {
        character = theCharacter;
    }
    return self;
}

-(id)clone
{
    return [[RTKFontCharacter alloc] initWithCharacter:character];
}


- (void)dealloc
{
    [super dealloc];
}


-(unichar)character
{
    return character;
}


-(void)setCharacter:(unichar)theCharacter
{
    character = theCharacter;
}

-(BOOL)compare:(id)other
{
    if([other class] == [self class])
    {
        if(character == [other character] || character == 0)
            return YES;
    }
    return NO;
}

-(int)orderByString:(id)other
{
    return [self order:other];
}

-(int)order:(id)other
{
    unichar otherCharacter;
    
    Class selfClass = [self class];
    Class otherClass = [other class];
    
    
    if(otherClass > selfClass)
        return 1; // after
    if(otherClass < selfClass)
        return -1; // before
    
    if(character != 0)
    {
        otherCharacter = [other character];    
        if(otherCharacter > character)
            return 1; // after
        if(otherCharacter < character)
            return -1; // before
    }
    
    return 0; // same
}

-(void)display
{
    NSLog(@"RTKFontCharacter: %@, %c, %i, %x", self, character, character, character);
}


-(NSString *)description
{
    return [[NSString alloc] initWithCharacters:&character length:1];
}

@end

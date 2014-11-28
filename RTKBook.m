//
//   RTKBook.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import "RTKBook.h"

#import "Chomp/Chomp.h"
#import "RTKArrayCategory.h"


@implementation RTKBook

-(id)init
{
    if(self = [super init]) {
        verses = [[NSMutableArray alloc] init];
        [self setDictionary:[NSDictionary dictionary]];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    if(self = [self init]) {
        [self setVerses:
            [[RTKVerse collectSelf] verseWithDictionary:
                [[dict objectForKey:@"verses"] each]]];
        
        [self setDictionary:dict];
    }
    return self;
}

- (id)initWithString:(NSMutableString *)string
{
    if(self = [self init]) {
        [string replaceOccurrencesOfString:@"\r"
                                withString:@"\n"
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0,[string length])];
        
        [string replaceOccurrencesOfString:[NSString stringWithFormat:@"%C", 0x2028] // LINE SEPARATOR
                                withString:@"\n"
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0,[string length])];
        [self setVerses:
            [[RTKVerse collectSelf] verseWithString:
                [[string componentsSeparatedByString:@"\n"] each]]];
    }
    return self;
}

- (id)initWithSFMString:(NSMutableString *)string
{
    if(self = [self init]) {
        [string replaceOccurrencesOfString:@"\r\n"
                                withString:@"\n"
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0,[string length])];
        
        [string replaceOccurrencesOfString:@"\r"
                                withString:@"\n"
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0,[string length])];
        
        [string replaceOccurrencesOfString:[NSString stringWithFormat:@"%C", 0x2028] // LINE SEPARATOR
                                withString:@"\n"
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0,[string length])];
        
        NSEnumerator * e = [[string componentsSeparatedByString:@"\n"] objectEnumerator];
        
        NSMutableDictionary * workingStateDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @"", @"chapter",
            @"1", @"book",
            @"1", @"verse",
            nil];
        
        RTKVerse * currentVerse = nil;
        while(string = [e nextObject]) {
            NSMutableString * trimmedString = [string mutableCopy];
            [trimmedString replaceOccurrencesOfString:@" "
                                    withString:@""
                                       options:NSLiteralSearch
                                         range:NSMakeRange(0,[string length])];
            
            if([trimmedString rangeOfString:@"\\"].location == 0 || currentVerse == nil) {
                currentVerse = [RTKVerse verseWithSFMString:string
                                               andStateDict:workingStateDict];
                [verses addObject:currentVerse];
            } else {
                [currentVerse appendLine:string];
            }
        }
    }
    return self;
}

- (id)initWithVerses:(NSMutableArray *)theVerses
{
    if(self = [super init]) {
        [self setVerses:theVerses];
    }
    return self;
}

- (void)dealloc
{
    [verses release];
    [dictionary release];
    
    [super dealloc];
}

+ (id)bookWithDictionary:(NSDictionary *)dict
{
    return [[[RTKBook alloc] initWithDictionary:dict] autorelease];
}

+ (id)bookWithVerses:(NSMutableArray *)theVerses
{
    return [[[RTKBook alloc] initWithVerses:theVerses] autorelease];
}

- (NSMutableDictionary *)dictionaryRepresentation
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    NSArray * versesArray = (NSArray *) [[verses collect] dictionaryRepresentation];
    
    [dict setObject:versesArray
             forKey:@"verses"];
    
    return dict;
}

-(NSString *)string
{
    NSMutableArray * strings = [[[verses collect] string] mutableCopy];
    [strings removeLastObject];
    return [strings componentsJoinedByString:@"\n"];
}

-(NSString *)sfmString
{
    NSMutableArray * strings = [[[verses collect] sfmString] mutableCopy];
    [strings removeLastObject];
    return [strings componentsJoinedByString:@"\n"];
}

- (NSMutableAttributedString *)mutableAttributedString:(BOOL)romanString
{
    NSMutableArray * strings = [[[verses collect] mutableAttributedString:romanString] mutableCopy];
    [strings removeLastObject];
    return [strings mutableAttributedStringFromComponents];
}

- (void)setDictionary:(NSDictionary *)theDictionary
{
    [theDictionary retain];
    [dictionary release];
    dictionary = theDictionary;
}

- (NSDictionary *)dictionary
{
    return dictionary;
}

- (NSMutableArray *)verses
{
    return verses;
}

- (void)setVerses:(NSMutableArray *)theVerses
{
    [theVerses retain];
    [verses release];
    verses = theVerses;
}

@end

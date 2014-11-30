//
//   RTKRevision.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//



#import "RTKRevision.h"
#import "RTKStringCategory.h"
#import "RTKMutableAttributedStringCategory.h"
#import "Chomp/Chomp.h"


@implementation RTKRevision

- (id)init
{
    if(self = [super init]) {
        roman = @"";
        script = @"";
        backTranslation = @"";
        notes = @"";
        checking = @"";
		locked = NO;
        
        [self setDictionary:[NSDictionary dictionary]];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    if(self = [self init]) {
        [self setRoman:[dict objectForKey:@"roman"]];
        [self setScript:[dict objectForKey:@"script"]];
        [self setBackTranslation:[dict objectForKey:@"backTranslation"]];
        [self setNotes:[dict objectForKey:@"notes"]];
        [self setChecking:[dict objectForKey:@"checking"]];
		[self setLocked:[[dict objectForKey:@"locked"] intValue]];
        
        [self setDictionary:dict];
    }
    return self;
}


+ (RTKRevision *)revisionWithDictionary:(NSDictionary *)dict
{
    return [[[RTKRevision alloc] initWithDictionary:dict] autorelease];
}


- (id)initWithString:(NSString *)string
{
    if(self = [self init]) {
        NSEnumerator * e = [[string componentsSeparatedByString:[[NSUserDefaults standardUserDefaults] objectForKey:@"RTKPlainTextDelimiter"]] objectEnumerator];
        
        [self setScript:[self stringFromTextSafeString:[e nextObject]]];
        [self setRoman:[self stringFromTextSafeString:[e nextObject]]];
        [self setBackTranslation:[self stringFromTextSafeString:[e nextObject]]];
        [self setNotes:[self stringFromTextSafeString:[e nextObject]]];
        [self setChecking:[self stringFromTextSafeString:[e nextObject]]];
    }
    return self;
}

+ (RTKRevision *)revisionWithString:string
{
    return [[[RTKRevision alloc] initWithString:string] autorelease];
}


- (id)initWithSFMString:(NSString *)string
{
    if(self = [self init]) {
        [self setRoman:string];
    }
    return self;
}

+ (RTKRevision *)revisionWithSFMString:string
{
    return [[[RTKRevision alloc] initWithSFMString:string] autorelease];
}

- (void)appendLine:(NSString *)line
{
    [self setRoman:[NSString stringWithFormat:@"%@\n%@", roman, line]];
}

- (void)dealloc
{
    [script release];
    [roman release];
    [backTranslation release];
    [notes release];
    [checking release];
        
    [dictionary release];
    
    [super dealloc];
}


- (id)deepCopy
{
    RTKRevision * copy = [[[RTKRevision alloc] init] autorelease];
    
    // Should be safe, since NSString is immutable.
    [copy setScript:script];
    [copy setRoman:roman];
    [copy setBackTranslation:backTranslation];
    [copy setNotes:notes];
    [copy setChecking:checking];
	[copy setLocked:locked];
    
    [copy setDictionary:dictionary];
    
    return copy;
}


- (NSMutableDictionary *)dictionaryRepresentation
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    [dict setObject:roman forKey:@"roman"];
    [dict setObject:script forKey:@"script"];
    [dict setObject:backTranslation forKey:@"backTranslation"];
    [dict setObject:notes forKey:@"notes"];
    [dict setObject:checking forKey:@"checking"];
	[dict setObject:[NSNumber numberWithInt:locked] forKey:@"locked"];
    
    return dict;
}


- (NSMutableString *)textSafeStringForString:(NSString *)string;
{
    NSMutableString * textSafeString = [string mutableCopy];
    
    [textSafeString replaceOccurrencesOfString:[NSString stringWithFormat:@"%C", 0x2028] // LINE SEPARATOR
                                    withString:[[NSUserDefaults standardUserDefaults] objectForKey:@"RTKPlainTextReturnCharacter"]
                                       options:NSLiteralSearch
                                         range:NSMakeRange(0,[string length])];
    
    [textSafeString replaceOccurrencesOfString:@"\n" // newline
                                    withString:[[NSUserDefaults standardUserDefaults] objectForKey:@"RTKPlainTextReturnCharacter"]
                                       options:NSLiteralSearch
                                         range:NSMakeRange(0,[string length])];
    
    [textSafeString replaceOccurrencesOfString:@"\r" // return
                                    withString:[[NSUserDefaults standardUserDefaults] objectForKey:@"RTKPlainTextReturnCharacter"]
                                       options:NSLiteralSearch
                                         range:NSMakeRange(0,[string length])];
    
    return textSafeString;
}


- (NSMutableString *)stringFromTextSafeString:(NSString *)textSafeString;
{
    NSMutableString * string = [textSafeString mutableCopy];
    
    [string replaceOccurrencesOfString:[[NSUserDefaults standardUserDefaults] objectForKey:@"RTKPlainTextReturnCharacter"]
                            withString:@"\n" // newline -- just go with standard unix way
                               options:NSLiteralSearch
                                 range:NSMakeRange(0,[string length])];
    if(!string)
        string = [NSMutableString stringWithString:@""];  // AKK 2012
    
    return string;
}

- (NSString *)stringWithVerseNumber:(NSString *)verseNumber
{
    NSMutableString * string = [NSMutableString new];
    NSString * delimiter = [[NSUserDefaults standardUserDefaults] objectForKey:@"RTKPlainTextDelimiter"];
    if(!verseNumber)
        verseNumber = @"";
    
    [string appendString:[self textSafeStringForString:[verseNumber stringByAppendingString:script]]];
    [string appendString:delimiter];
    [string appendString:[self textSafeStringForString:[verseNumber stringByAppendingString:roman]]];
    [string appendString:delimiter];
    [string appendString:[self textSafeStringForString:backTranslation]];
    [string appendString:delimiter];
    [string appendString:[self textSafeStringForString:notes]];
    [string appendString:delimiter];
    [string appendString:[self textSafeStringForString:checking]];

    return string;
}

- (NSMutableAttributedString *)mutableAttributedString:(BOOL)romanString
{
    // TODO: Add support for transliteration.
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:(romanString ? roman : script)];
    // Provide a link back from the string to this object.
    [string addAttribute:@"RTKRevision" value:self];
    return string;
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


- (RTKRevision *)copy
{
    return [self deepCopy];
}


- (NSString *)roman
{
    return roman;
}


- (NSString *)script
{
    return script;
}


- (NSString *)backTranslation
{
    return backTranslation;
}


- (NSString *)notes
{
    return notes;
}


- (NSString *)checking
{
    return checking;
}


- (BOOL)locked
{
	return locked;
}


- (void)setRoman:(NSString *)string
{
    [string retain];
    [roman release];
    roman = string;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTKRevisionSetRoman" object:self userInfo:nil];
}

- (void)setScript:(NSString *)string
{
    [string retain];
    [script release];
    script = string;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTKRevisionSetScript" object:self userInfo:nil];
}

- (void)setBackTranslation:(NSString *)string
{
    [string retain];
    [backTranslation release];
    backTranslation = string;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTKRevisionSetBackTranslation" object:self userInfo:nil];
}

- (void)setNotes:(NSString *)string
{
    [string retain];
    [notes release];
    notes = string;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTKRevisionSetNotes" object:self userInfo:nil];
}

- (void)setChecking:(NSString *)string
{
    [string retain];
    [checking release];
    checking = string;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTKRevisionSetChecking" object:self userInfo:nil];
}

- (void)setLocked:(bool)state
{
	locked = state;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RTKRevisionSetLocked" object:self userInfo:nil];
}


// Returns YES if all fields are still set to default values.
- (BOOL)blank
{
    //if(![script isEqualToString:@""])
    //    return NO;
    if(![roman isEqualToString:@""])
        return NO;
    if(![backTranslation isEqualToString:@""])
        return NO;
    if(![notes isEqualToString:@""])
        return NO;
    if(![checking isEqualToString:@""])
        return NO;
    if(locked)
        return NO;
    
    return YES;
}

- (BOOL)matchesString:(NSString *)string
{
    if([script containsCaseInsensitiveSubstring:string])
        return YES;
    if([roman containsCaseInsensitiveSubstring:string])
        return YES;
    if([backTranslation containsCaseInsensitiveSubstring:string])
        return YES;
    if([notes containsCaseInsensitiveSubstring:string])
        return YES;
    if([checking containsCaseInsensitiveSubstring:string])
        return YES;
    return NO;
}


@end

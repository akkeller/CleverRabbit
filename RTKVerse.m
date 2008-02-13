//
//   RTKVerse.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import "RTKVerse.h"
#import "RTKRevision.h"
#import "RTKMutableArrayCategory.h"
#import "RTKStringCategory.h"

#import "Chomp/Chomp.h"

@implementation RTKVerse

- (id)init
{
    if(self = [super init]) {
        revisions = [[NSMutableArray alloc] init];
        [self setReference:@""];
        [self setPreUSFMType:@""];
		[self setType:@"\\v"];
		locked = NO;
        [revisions addObject:[[RTKRevision alloc] init]];
		
        [self setDictionary:[NSDictionary dictionary]];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    if(self = [self init]) {
        [self setRevisions:
            [[RTKRevision collectSelf] revisionWithDictionary:
                [[dict objectForKey:@"revisions"] each]]];
        [self setReference:[dict objectForKey:@"reference"]];
		
        [self setType:[dict objectForKey:@"usfmType"]];
        if(!type) {
			[self setType:[dict objectForKey:@"type"]];
		}
		[self setPreUSFMType:[dict objectForKey:@"type"]];
        if(!type)
            [self setType:@"\\v"];
		
        [self setCurrentRevisionIndex:[[dict objectForKey:@"currentRevisionIndex"] intValue]];
        [self setLocked:[[dict objectForKey:@"locked"] intValue]];
        
        [self setDictionary:dict];
    }
    return self;
}

+ (RTKVerse *)verseWithDictionary:dict
{
    return [[[RTKVerse alloc] initWithDictionary:dict] autorelease];
}

- (void)dealloc
{
    [reference release];
    [type release];
    [revisions release];
    [dictionary release];
    
    [super dealloc];
}

- (id)deepCopy
{
    RTKVerse * copy = [[[RTKVerse alloc] init] autorelease];
    
    // Should be safe, since NSString is immutable.
    [copy setReference:reference];
    [copy setCurrentRevisionIndex:currentRevisionIndex];
    [copy setRevisions:[revisions deepCopy]];
    [copy setLocked:locked];
	[copy setType:type];
    
    [copy setDictionary:dictionary];
	
    
    return copy;
}

- (NSMutableDictionary *)dictionaryRepresentation
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    NSArray * revisionsArray = [[revisions collect] dictionaryRepresentation];
    
    [dict setObject:revisionsArray
             forKey:@"revisions"];
    
    [dict setObject:reference
             forKey:@"reference"];
	
    [dict setObject:preUSFMType
             forKey:@"type"];
	
    [dict setObject:type
             forKey:@"usfmType"];
    
    [dict setObject:[NSNumber numberWithInt:currentRevisionIndex]
             forKey:@"currentRevisionIndex"];
	
	[dict setObject:[NSNumber numberWithInt:locked] forKey:@"locked"];
    
    return dict;
}

- (id)initWithString:(NSString *)string
{
    if(self = [self init]) {
        [revisions removeAllObjects];
        [revisions addObject:[RTKRevision revisionWithString:string]];
        [self setCurrentRevisionIndex:0];
    }
    return self;
}

+ (RTKVerse *)verseWithString:string
{
    return [[[RTKVerse alloc] initWithString:string] autorelease];
}

- (id)initWithSFMString:(NSString *)string
           andStateDict:(NSMutableDictionary *)dict
{
    if(self = [self init]) {
        NSMutableArray * strings = [[string componentsSeparatedByString:@" "] mutableCopy];
        int stringCount = [strings count];
        
        // Discard leading 0x20 space characters.
        while(stringCount > 0 && [[strings objectAtIndex:0] length] == 0) {
            [strings removeObjectAtIndex:0];
            stringCount --;
        }
        
        NSString * formatMarker = (stringCount > 0 ? [strings objectAtIndex:0] : @"");
        NSString * formatMarkerData = (stringCount > 1 ? [strings objectAtIndex:1] : @"");        
        
        if([formatMarker isEqualToString:@"\\id"]) {
            [dict setObject:formatMarkerData forKey:@"book"];
            [dict setObject:@"1" forKey:@"chapter"];
            [strings removeObjectsInRange:NSMakeRange(0,2)];
        } else if([formatMarker isEqualToString:@"\\c"]) {
            [dict setObject:formatMarkerData forKey:@"chapter"];
            [dict setObject:@"1" forKey:@"verse"];
            [strings removeObjectsInRange:NSMakeRange(0,2)];
        } else if([formatMarker isEqualToString:@"\\v"]) {
            [dict setObject:formatMarkerData forKey:@"verse"];
            [strings removeObjectsInRange:NSMakeRange(0,2)];
        } else if([formatMarker isEqualToString:@"\\mt"]) {
            if([[dict objectForKey:@"preceding format marker"] isEqualToString:@"\\v"])
                [dict setObject:[NSString stringWithFormat:@"%i", 
                    [[[[dict objectForKey:@"verse"] componentsSeparatedByString:@"-"] lastObject] intValue] + 1] forKey:@"verse"];
            if([formatMarkerData intValue] > 0) { // A numbered major title size.
                formatMarker = [NSString stringWithFormat:@"%@ %@", formatMarker, formatMarkerData];
                [strings removeObjectAtIndex:0];
            }
            [strings removeObjectAtIndex:0];
        } else {
            if([[dict objectForKey:@"preceding format marker"] isEqualToString:@"\\v"])
                [dict setObject:[NSString stringWithFormat:@"%i", 
                    [[[[dict objectForKey:@"verse"] componentsSeparatedByString:@"-"] lastObject] intValue] + 1] forKey:@"verse"];
            [strings removeObjectAtIndex:0];   
        }
        
        [self setType:formatMarker];
        [self setReference:[NSString stringWithFormat:@"%@ %@:%@", 
            [dict objectForKey:@"book"],
            [dict objectForKey:@"chapter"],
            [dict objectForKey:@"verse"]]];
        string = [strings componentsJoinedByString:@" "];
        
        [revisions removeAllObjects];
        [revisions addObject:[RTKRevision revisionWithSFMString:string]];
        [self setCurrentRevisionIndex:0];
        
        [dict setObject:formatMarker forKey:@"preceding format marker"];
    }
    return self;
}

+ (RTKVerse *)verseWithSFMString:string
                    andStateDict:dict
{
    return [[[RTKVerse alloc] initWithSFMString:string
                                   andStateDict:dict] autorelease];
}

- (void)updateTypeFieldToUSFM
{
	[self setPreUSFMType:type];
	
	if([type isEqualToString:@"Text"]) {
		type = @"\\v";
	} else if([type isEqualToString:@"Paragraph Break"]) {
		type = @"\\p";
	} else if([type isEqualToString:@"Section Title"]) {
		type = @"\\s1";
	} else if([type isEqualToString:@"Major Title"]) {
		type = @"\\mt1";
	} else if([type isEqualToString:@"Chapter Number"]) {
		type = @"\\c";
	}
}

- (void)appendLine:(NSString *)line
{
    [(RTKRevision *)[revisions objectAtIndex:0] appendLine:line];
}

- (NSString *)string
{
    NSMutableString * string = [NSMutableString new];
    
    RTKRevision * revision = [self currentRevision];

    NSString * outputReference = nil;
    if([type isEqualToString:@"\\v"]) {
        outputReference = [NSString stringWithFormat:@"(%@) ", [reference verse]];
    } else if([type isEqualToString:@"\\c"]) {
        outputReference = [NSString stringWithFormat:@"(%@) ", reference];;
    }
    
    [string appendString:
        [revision stringWithVerseNumber:outputReference]];
    
    return string;
}

- (NSString *)sfmString
{
    RTKRevision * revision = [self currentRevision];
    
    NSString * marker = [[type componentsSeparatedByString:@" "] objectAtIndex:0];
    
    if ([marker isEqualToString:@"\\v"]) {
        return [NSString stringWithFormat:@"%@ %@ %@", type, [reference verse], [revision roman]];
    } else if ([marker isEqualToString:@"\\c"]) {
       return [NSString stringWithFormat:@"%@ %@", type, [reference chapter]];
    } else if ([marker isEqualToString:@"\\mt"]) {
        return [NSString stringWithFormat:@"%@ %@", type, [revision roman]];
    } else if ([marker isEqualToString:@"\\id"]) {
        return [NSString stringWithFormat:@"%@ %@ %@", type, [reference book], [revision roman]];
    }
    return [NSString stringWithFormat:@"%@ %@", type, [revision roman]];
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

- (void)setReference:(NSString *)theReference
{
    [theReference retain];
    [reference release];
    reference = theReference;
}

- (NSString *)reference
{
    return reference;
}

- (void)setPreUSFMType:(NSString *)theType
{
    [theType retain];
    [preUSFMType release];
    preUSFMType = theType;
}

- (NSString *)preUSFMType
{
    return preUSFMType;
}

- (void)setType:(NSString *)theType
{
    [theType retain];
    [type release];
    type = theType;
}

- (NSString *)type
{
    return type;
}

- (void)setLocked:(bool)state
{
	locked = state;
}

- (BOOL)locked
{
	return locked;
}

#pragma mark - revision management

- (void)setRevisions:(NSMutableArray *)theRevisions
{
    [theRevisions retain];
    [revisions release];
    revisions = theRevisions;
}

- (NSMutableArray *)revisions
{
    return revisions;
}

- (int)revisionCount
{
    return [revisions count];
}

- (void)setCurrentRevisionIndex:(int)index
{
    currentRevisionIndex = index;
}

- (int)currentRevisionIndex
{
    return currentRevisionIndex;
}

// Just a convenience method.
- (RTKRevision *)currentRevision
{
    if([revisions count])
        return [revisions objectAtIndex:currentRevisionIndex];
    else
        return nil;
}

// Another convenience method
- (BOOL)blank
{
    NSEnumerator * e = [revisions objectEnumerator];
    RTKRevision * revision;
    while(revision = [e nextObject]) {
        if(![revision blank])
            return NO;
    }
    if(![type isEqualToString:@"\\v"])
		return NO;
	if(locked)
        return NO;
    return YES;
}

- (BOOL)matchesString:(NSString *)string
{
    if([reference containsCaseInsensitiveSubstring:string])
        return YES;
    if([type containsCaseInsensitiveSubstring:string])
        return YES;
    
    NSEnumerator * e = [revisions objectEnumerator];
    RTKRevision * revision;
    while(revision = [e nextObject]) {
        if([revision matchesString:string])
            return YES;
    }
    return NO;
}

@end

//
//   RTKStringCategory.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import "RTKStringCategory.h"


@implementation NSString (RTKStringCategory)

- (NSString *)verse
{
    NSMutableString * string = [self mutableCopy];
    [string replaceOccurrencesOfString:@":"
                            withString:@"."
                               options:NSLiteralSearch
                                 range:NSMakeRange(0,[string length])];
    return [string pathExtension];
}

- (NSString *)chapter
{
    NSMutableString * string = [self mutableCopy];
    [string replaceOccurrencesOfString:@":"
                            withString:@"."
                               options:NSLiteralSearch
                                 range:NSMakeRange(0,[string length])];
    string = [string stringByDeletingPathExtension];
    return [[string componentsSeparatedByString:@" "] lastObject];
}

- (NSString *)book
{
    NSMutableArray * stringArray = [[self componentsSeparatedByString:@" "] mutableCopy];
    [stringArray removeLastObject];
    return [stringArray componentsJoinedByString:@" "];
}

- (NSData *)utf8Data
{
    // These three bytes go at the front of every utf8 text file.
    char utf8Marker[3];
    utf8Marker[0] = 0xef;
    utf8Marker[1] = 0xbb;
    utf8Marker[2] = 0xbf;
    
    NSData * data = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    if(!data)
        NSLog(@"nil data from string in utf8Data of RTKStringCategory");
    
    // Get extra room for the utf8 marker.
    void * outputData = malloc([data length] + 3);
    void * rawData = (void *) [data bytes];
    
    // Copy marker and text together.
    memcpy(outputData, &utf8Marker, 3);
    memcpy(outputData + 3, rawData, [data length]);
    
    // And we are done exporting plain text!
    data = [NSData dataWithBytesNoCopy:outputData
                                length:[data length] + 3
                          freeWhenDone:YES];
    return data;
}

- (BOOL)containsSubstring:(NSString *)substring
{
    return ([self rangeOfString:substring].location != NSNotFound);
}

- (BOOL)containsCaseInsensitiveSubstring:(NSString *)substring
{
    return [[self lowercaseString] containsSubstring:[substring lowercaseString]];
}

@end

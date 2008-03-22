//
//   RTKArrayCategory.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//


#import "RTKArrayCategory.h"

@implementation NSArray (RTKArrayCategory)

NSArray * indexSetToArray(NSIndexSet * indexSet)
{
    NSMutableArray * indexes;
    int indexCount = [(NSIndexSet *)indexSet count];
    indexes = [NSMutableArray arrayWithCapacity:indexCount];
    
    int index = -1;
    while((index = [indexSet indexGreaterThanOrEqualToIndex:index + 1]) != NSNotFound) {
        [indexes addObject:[NSNumber numberWithInt:index]];
    }
    return indexes;
}

- (NSArray *)arrayWithObjectsAtIndexes:(id)indexes
{
    NSMutableArray * array = [NSMutableArray new];
    
    if([indexes class] == [NSIndexSet class])
        indexes = indexSetToArray(indexes);
    
    NSEnumerator * e = [indexes objectEnumerator];
    NSNumber * n;
    while(n = [e nextObject]) {
        [array addObject:[self objectAtIndex:[n intValue]]];
    }
    return [array copy];
}

/*
 This isn't the most efficient implementation, but it could be worse. :)
 Should check out the following method as an alternative.
 - (void)removeObjectsFromIndexes:(unsigned *)indexes numIndexes:(unsigned)count
*/
- (NSArray *)arrayByRemovingObjectsAtIndexes:(id)indexes
{
    NSMutableArray * array = [NSMutableArray arrayWithArray:self];

    if([indexes class] == [NSIndexSet class])
        indexes = indexSetToArray(indexes);
    
    NSEnumerator * e = [(NSArray *)indexes reverseObjectEnumerator];
    NSNumber * n;
    while(n = [e nextObject]) {
        [array removeObjectAtIndex:[n intValue]];
    }
    return [array copy];    
}

// Returns an autoreleased NSMutableAttributedString composed of the NSString and NSAttributedString objects in the array.
- (NSMutableAttributedString *)mutableAttributedStringFromComponents
{
    NSMutableAttributedString * outputString = [[NSMutableAttributedString new] autorelease];
    NSEnumerator * e = [self objectEnumerator];
    id string = nil;
    while (string = [e nextObject]) {
        if([string isKindOfClass:[NSString class]]) { // Also includes NSMutableString
            [outputString appendAttributedString:[[[NSAttributedString alloc] initWithString:string] autorelease]];
        } else if([string isKindOfClass:[NSAttributedString class]]) { // Also includes NSMutableAttributedString
            [outputString appendAttributedString:string];
        }
    }
    return outputString;
}

- (NSArray *)deepCopy
{
    return [[self collect] deepCopy];
}

@end

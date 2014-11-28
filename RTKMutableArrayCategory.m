//
//   RTKMutableArrayCategory.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import "RTKMutableArrayCategory.h"
#import "RTKArrayCategory.h"

@implementation NSMutableArray (RTKMutableArrayCategory)

- (NSMutableArray *)arrayWithObjectsAtIndexes:(id)indexes
{
    return [[super arrayWithObjectsAtIndexes:indexes] mutableCopy];
}

- (NSMutableArray *)arrayByRemovingObjectsAtIndexes:(id)indexes;
{
    return [[super arrayByRemovingObjectsAtIndexes:indexes] mutableCopy];   
}

- (NSMutableArray *)deepCopy
{
    return [[super deepCopy] mutableCopy];
}

@end

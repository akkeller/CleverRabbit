//
//   RTKVerse.h
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

#define RTK_CHANGED_REVISION        @"RTKChangedRevision"

@class RTKRevision;

@interface RTKVerse : NSObject
{
    NSString * reference;
	NSString * preUSFMType; // maintained for previous versions
    NSString * type;
	BOOL locked;
	
    NSMutableArray *revisions;
    int currentRevisionIndex;
    
    // Lossless forwards/backwards compatibility
    NSDictionary * dictionary;
}

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)addDictionaryRepresentationToMutableArray:(NSMutableArray *)array;
- (id)initWithString:(NSString *)string;
- (id)initWithSFMString:(NSString *)string
           andStateDict:(NSMutableDictionary *)dict;
- (id)deepCopy;
- (void)updateTypeFieldToUSFM;
- (NSString *)string;
- (NSString *)sfmString;

- (void)setLocked:(BOOL)state;
- (BOOL)locked;

- (void)setReference:(NSString *)theReference;
- (NSString *)reference;

- (void)setPreUSFMType:(NSString *)theType;
- (NSString *)preUSFMType;
- (void)setType:(NSString *)theType;
- (NSString *)type;

- (BOOL)blank;
- (BOOL)matchesString:(NSString *)string;
- (void)setDictionary:(NSDictionary *)theDictionary;
- (NSDictionary *)dictionary;

- (BOOL)updateWithAttributedString:(NSAttributedString *)string 
                           atIndex:(NSUInteger)index;

#pragma mark - revision management

- (void)setRevisions:(NSMutableArray *)theRevisions;
- (NSMutableArray *)revisions;
- (int)revisionCount;
- (void)setCurrentRevisionIndex:(int)index;
- (int)currentRevisionIndex;
- (RTKRevision *)currentRevision;



@end

//
//   RTKBook.h
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
#import "RTKVerse.h"

@interface RTKBook : NSObject
{
    NSMutableArray *verses;
    RTKVerse *currentVerse;
    
    // Lossless forwards/backwards compatibility
    NSDictionary * dictionary;
}


- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithString:(NSMutableString *)string;
- (id)initWithSFMString:(NSMutableString *)string;
- (NSMutableDictionary *)dictionaryRepresentation;
- (NSString *)string;
- (NSString *)sfmString;
- (NSMutableAttributedString *)mutableAttributedString:(BOOL)romanString;
- (NSMutableArray *)verses;

- (void)setDictionary:(NSDictionary *)theDictionary;
- (NSDictionary *)dictionary;

- (void)setVerses:(NSMutableArray *)theVerses;
- (void)setCurrentVerse:(RTKVerse *)verse;
- (RTKVerse *)currentVerse;

+ (id)bookWithVerses:(NSMutableArray *)verses;



@end

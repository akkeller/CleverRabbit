//
//   RTKRevision.h
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


@interface RTKRevision : NSObject
{
    NSString * script;
    NSString * roman;
    NSString * backTranslation;
    NSString * notes;
    NSString * checking;
	
	bool locked;
    
    // Lossless forwards/backwards compatibility
    NSDictionary * dictionary;
}

- (id)initWithDictionary:(NSDictionary *)dict;
+ (RTKRevision *)revisionWithDictionary:(NSDictionary *)dict;
- (id)initWithString:(NSString *)string;
+ (RTKRevision *)revisionWithString:string;
- (id)initWithSFMString:(NSString *)string;
+ (RTKRevision *)revisionWithSFMString:(NSString*)string;
- (void)appendLine:(NSString *)line;
- (id)deepCopy;

- (NSString *)roman;
- (NSString *)script;
- (NSString *)backTranslation;
- (NSString *)notes;
- (NSString *)checking;
- (BOOL)locked;


- (void)setRoman:(NSString *)string;
- (void)setScript:(NSString *)string;
- (void)setBackTranslation:(NSString *)string;
- (void)setNotes:(NSString *)string;
- (void)setChecking:(NSString *)string;
- (void)setLocked:(bool)state;

- (void)setDictionary:(NSDictionary *)theDictionary;
- (NSDictionary *)dictionary;

- (NSMutableString *)textSafeStringForString:(NSString *)string;
- (NSMutableString *)stringFromTextSafeString:(NSString *)textSafeString;

- (BOOL)blank;
- (BOOL)matchesString:(NSString *)string;

- (NSMutableAttributedString *)mutableAttributedString:(BOOL)romanString;
- (NSString *)stringWithVerseNumber:(NSString *)verseNumber;


@end

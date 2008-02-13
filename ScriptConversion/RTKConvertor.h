//
//  RTKConvertor.h
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import <Foundation/Foundation.h>
#import "RTKIDDatabase.h"
#import "RTKLinkedListHeader.h"
#import "RTKFilter.h"
#import "RTKScriptDefinition.h"
#import "RTKFontEncodingDefinition.h"
#import "RTKInputFilterSetDefinition.h"

@interface RTKConvertor : NSObject 
{
    NSLock *transcriptionLock;
    

    
    // Transcription instructions 
    NSMutableDictionary *inputFilterSetDefinitionDict;
    NSLock *inputFilterSetDefinitionLock;
    NSMutableDictionary *inputFilterSetDefinitionLockDict;

    NSMutableDictionary *scriptDefinitionDict;
    NSLock *scriptDefinitionLock;
    NSMutableDictionary *scriptDefinitionLockDict;

    NSMutableDictionary *fontEncodingDefinitionDict;
    NSLock *fontEncodingDefinitionLock;
    NSMutableDictionary *fontEncodingDefinitionLockDict;
    
    // Other data
    RTKIDDatabase *generalDatabase;
    
}

-(NSMutableDictionary *)inputFilterSetDefinitionDict;

-(NSMutableDictionary *)scriptDefinitionDict;

-(NSMutableDictionary *)fontEncodingDefinitionDict;


-(void)loadInputFilterSetDefinition:(NSString *)filePath;
-(void)loadScriptDefinition:(NSString *)filePath;
-(void)loadFontEncodingDefinition:(NSString *)filePath;

-(void)checkInputFilterSetDefinition:(NSString *)filePath;
-(void)checkScriptDefinition:(NSString *)filePath;
-(void)checkFontEncodingDefinition:(NSString *)filePath;

- (void)resetDefinitions;

-(RTKInputFilterSetDefinition *)inputFilterSetDefinition;
-(RTKScriptDefinition *)scriptDefinition;
-(RTKIDDatabase *)generalDatabase;



-(NSMutableDictionary *)convertString:(NSString *)input
                          inputSystem:(NSString *)theInputSystem
                         scriptSystem:(NSString *)theScriptSystem
                           fontSystem:(NSString *)theFontSystem
                      withMetaStrings:(BOOL)metaStrings
                  checkForPunctuation:(BOOL)punctuation;


-(void)setInputString:(NSString *)theInputString;

-(void)updatePhonemicList;
-(void)updatePhonemicString;
-(void)updateSpeechTreeList;
-(void)updateScriptList;
-(void)updateScriptString;
-(void)updateFontList;
-(void)updateFontString;

-(NSString *)inputString;
-(NSString *)phonemicString;
-(NSString *)scriptString;
-(NSString *)codepointString;
-(NSString *)fontString;

-(NSString *)buildDefinition:(NSString *)filePath;
-(int)lookupNumberForString:(NSString *)theString;
-(int)lookupNumberForList:(RTKLinkedListHeader *)theList;
-(NSString *)stringForID:(int)theIDNumber;


// Class methods





+ (RTKLinkedListHeader *)characterListFromString:(NSString *)theString;

+ (NSString *)getStringFromList:(id)theList
		usingIDDatabase:(RTKIDDatabase *)idDatabase;
				
+(void)phonemeList:(RTKLinkedListHeader *)phonemeList
	toWordList:(RTKLinkedListHeader *)wordList
   usingIDDatabase:(RTKIDDatabase *)idDatabase;
   
+(RTKLinkedListHeader *)listOfByteBlock:(const char *)bytes
			    ofLength:(unsigned)length;

+(RTKFilter *)makeXMLParsingFilter;

+(void)insertTagPair:(NSString *)theString
	      ofType:(int)theType
	        into:(RTKLinkedListHeader *)theList;
		
		
/*
 +(id)findXMLTagOfType:(int)theType
		    position:(int)thePosition
		      inList:(id)theList
		  startingAt:(id)startingLocation
			  to:(id)endingLocation;
 */
+(RTKLinkedListHeader *)loadTagListFromFilePath:(NSString *)filePath;

//+(RTKLinkedListHeader *)rootXMLTreeNodeListFromTagList:(RTKLinkedListHeader *)tagList;

-(NSString *)codepointStringForString:(NSString *)string;
+(RTKLinkedListHeader *)speechTreeFromPhonemeList:(RTKLinkedListHeader *)phonemeList
                                  usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(RTKLinkedListHeader *)phonemicListFromString:(NSString *)inputString
                              usingInputFilter:(RTKInputFilterSetDefinition*)inputFilter;
-(RTKLinkedListHeader *)phonemicListFromString:(NSString *)inputString
                              usingInputFilter:(RTKInputFilterSetDefinition*)inputFilter;


@end


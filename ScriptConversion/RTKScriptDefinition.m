//
//  RTKScriptDefinition.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//



#import "RTKScriptDefinition.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKConvertor.h"
#import "RTKConsonantDefinition.h"
#import "RTKVowelDefinition.h"
#import "RTKPunctuationGroupUnit.h"
#import "RTKScriptPunctuationGroup.h"
#import "RTKScriptWord.h"
#import "RTKWordUnit.h"

#import <AppKit/AppKit.h>
#import "RTKGlobals.h"

@implementation RTKScriptDefinition


// persistence

NSString *RTKScriptDefinitionPListType = @"RTKScriptDefinitionPListType";
NSString *RTKConsonantList = @"RTKConsonantList";
NSString *RTKVowelList = @"RTKVowelList";
NSString *RTKPresyllableVowelList = @"RTKPresyllableVowelList";
NSString *RTKFilterList = @"RTKFilterList";



-(id)initWithFilePath:(NSString *)filePath
      usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    if(self = [super init])
    {
		consonantList = nil;
		vowelList = nil;
		presyllableVowelList = nil;
		filterList = nil;
        
        [self readXMLpListFromFile:filePath];
        
        consonantTree = [[RTKBinaryTreeHeader alloc] initWithList:consonantList];
		vowelTree = [[RTKBinaryTreeHeader alloc] initWithList:vowelList];
		presyllableVowelTree = [[RTKBinaryTreeHeader alloc] initWithList:presyllableVowelList];        
    }
    return self;
}

- (void)dealloc
{
    [consonantList release];
    [vowelList release];
    [presyllableVowelList release];
    [filterList release];
    [consonantTree release];
    [vowelTree release];
    [presyllableVowelTree release];

    [super dealloc];
}

-(void)readXMLpListFromFile:(NSString *)filePath
{
    id theFile = [[NSFileWrapper alloc] initWithPath:filePath];
    NSData *theFileData = [theFile regularFileContents];
	
    NSDictionary *dict = [self dictionaryFromData:theFileData];
	
    NSArray *array = [dict objectForKey:RTKConsonantList];
    consonantList = [[RTKLinkedListHeader alloc] initWithArray:array];
	
    array = [dict objectForKey:RTKVowelList];
    vowelList = [[RTKLinkedListHeader alloc] initWithArray:array];
	
    array = [dict objectForKey:RTKPresyllableVowelList];
    presyllableVowelList = [[RTKLinkedListHeader alloc] initWithArray:array];
	
    array = [dict objectForKey:RTKFilterList];
    filterList = [[RTKLinkedListHeader alloc] initWithArray:array];
	
}


- (NSDictionary *)dictionaryFromData:(NSData *)data 
{
    NSString *string = [[NSString allocWithZone:[self zone]] initWithData:data encoding:NSASCIIStringEncoding];
    NSDictionary *doc = [string propertyList];
    [string release];
    return doc;
}



-(BOOL)writeXMLpListToFile:(NSString *)filePath
{
    NSData *fileData = [self dataRepresentationOfType:RTKScriptDefinitionPListType];
	
    id theFile = [[NSFileWrapper alloc] initRegularFileWithContents:fileData];
	
    [theFile writeToFile:filePath
              atomically:NO
         updateFilenames:YES];
	
    return YES;
}



-(NSData *)dataRepresentationOfType:(NSString *)type
{
    if([type isEqualToString:RTKScriptDefinitionPListType])
    {
        return [self pListDocumentData];
    }
    else
    {
        return nil;
    }
}


-(NSData *)pListDocumentData
{
    NSDictionary *doc = [self dictionary];
    NSString *string = [doc description];
    return [string dataUsingEncoding:NSASCIIStringEncoding];
}


-(NSDictionary *)dictionary
{
    NSMutableDictionary *doc = [NSMutableDictionary dictionary];
	
    NSArray *array = (NSArray *)[consonantList propertyListRepresentation];
    if(array != nil)
        [doc setObject:array forKey:RTKConsonantList];
    array = (NSArray *)[vowelList propertyListRepresentation];
    if(array != nil)
        [doc setObject:array forKey:RTKVowelList];
    array = (NSArray *)[presyllableVowelList propertyListRepresentation];
    if(array != nil)
        [doc setObject:array forKey:RTKPresyllableVowelList];
    array = (NSArray *)[filterList propertyListRepresentation];
    if(array != nil)
        [doc setObject:array forKey:RTKFilterList];    
	
    [doc setObject:NSStringFromClass([self class])
            forKey:RTKClass];
    
    return doc;
}


-(RTKLinkedListHeader *)scriptListFromWordList:(RTKLinkedListHeader *)wordList
							   usingIDDatabase:(RTKIDDatabase *)idDatabase
								 defaultSeries:(const int)DEFAULTSERIES
								   firstSeries:(const int)FIRSTSERIES
								  secondSeries:(const int)SECONDSERIES
								   presyllable:(const int)PRESYLLABLE
						   beginningOfSyllable:(const int)BEGINNINGOFSYLLABLE
								 endOfSyllable:(const int)ENDOFSYLLABLE
							   beginningOfWord:(const int)BEGINNINGOFWORD
									 endOfWord:(const int)ENDOFWORD
{
    RTKLinkedListHeader *scriptList = [[RTKLinkedListHeader alloc] init];
    RTKLinkedListNode *currentWordNode = [wordList first];
     
    while(currentWordNode != nil)
    {
		id currentWord = [currentWordNode data];
		if([currentWord isMemberOfClass:[RTKWordUnit class]])
		{
			RTKScriptWord *word = [[RTKScriptWord alloc] initFromSyllableList:[currentWord syllableList]
														usingScriptDefinition:self
															  usingIDDatabase:idDatabase
																defaultSeries:DEFAULTSERIES
																  firstSeries:FIRSTSERIES
																 secondSeries:SECONDSERIES
																  presyllable:PRESYLLABLE
														  beginningOfSyllable:BEGINNINGOFSYLLABLE
																endOfSyllable:ENDOFSYLLABLE
															  beginningOfWord:BEGINNINGOFWORD
																	endOfWord:ENDOFWORD];
			[[RTKLinkedListNode alloc] initWithData:word
									   atBackOfList:scriptList];
			[word release];
		}
		else if([currentWord isMemberOfClass:[RTKPunctuationGroupUnit class]])
		{
			RTKScriptPunctuationGroup *puncGroup = [[RTKScriptPunctuationGroup alloc] initFromPunctuationList:[currentWord punctuationList]];
			
			[[RTKLinkedListNode alloc] initWithData:puncGroup
									   atBackOfList:scriptList];
			[puncGroup release];
		}
		currentWordNode = [currentWordNode next];
    }
    return scriptList;
}


-(RTKBinaryTreeHeader *)consonantTree
{
    return consonantTree;
}


-(RTKBinaryTreeHeader *)vowelTree
{
    return vowelTree;
}


-(RTKBinaryTreeHeader *)presyllableVowelTree
{
    return presyllableVowelTree;
}

-(RTKLinkedListHeader *)filterList
{
    return filterList;
}



@end

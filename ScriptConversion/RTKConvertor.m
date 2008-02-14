//
//  RTKConvertor.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//





#import "RTKConvertor.h"
#import "RTKIDDatabase.h"
#import "RTKLinkedListHeader.h"
#import "RTKContextualParsing.h"
#import "RTKFontCharacter.h"
#import "RTKIDMarker.h"

#import "RTKWordUnit.h"
#import "RTKSyllableUnit.h"
#import "RTKPunctuationGroupUnit.h"
#import "RTKPunctuationUnit.h"

#import "RTKScriptPunctuationGroup.h"
#import "RTKScriptWord.h"
#import "RTKScriptCluster.h"

#import "RTKScriptDefinition.h"

#import "RTKFontEncodingDefinition.h"

#import "RTKGlobals.h"

@implementation RTKConvertor

// Instance Methods

-(id)init
{
    if(self = [super init])
    {
        transcriptionLock = [[NSLock alloc] init];
        
        inputFilterSetDefinitionLock = [[NSLock alloc] init];
        inputFilterSetDefinitionDict = [[NSMutableDictionary alloc] init];
        inputFilterSetDefinitionLockDict = [[NSMutableDictionary alloc] init];
        
        scriptDefinitionLock = [[NSLock alloc] init];
        scriptDefinitionDict = [[NSMutableDictionary alloc] init];
        scriptDefinitionLockDict = [[NSMutableDictionary alloc] init];
        
        fontEncodingDefinitionLock = [[NSLock alloc] init];
        fontEncodingDefinitionDict = [[NSMutableDictionary alloc] init];
        fontEncodingDefinitionLockDict = [[NSMutableDictionary alloc] init];
        
        generalDatabase = [[RTKIDDatabase alloc] init];
    }
    return self;
}


-(void)dealloc
{
    [inputFilterSetDefinitionDict release];
    [inputFilterSetDefinitionLock release];
    [inputFilterSetDefinitionLockDict release];
    
    [scriptDefinitionDict release];
    [scriptDefinitionLock release];
    [scriptDefinitionLockDict release];
    
    [fontEncodingDefinitionDict release];
    [fontEncodingDefinitionLock release];
    [fontEncodingDefinitionLockDict release];
    
    [generalDatabase release];
    [super dealloc];
}

#pragma mark -
// read access functions

// locks


-(NSLock *)inputFilterSetDefinitionLock
{
    return inputFilterSetDefinitionLock;
}

-(NSLock *)scriptDefinitionLock
{
    return scriptDefinitionLock;
}

-(NSLock *)fontEncodingDefinitionLock
{
    return fontEncodingDefinitionLock;
}

#pragma mark -
// Definitions


-(NSMutableDictionary *)inputFilterSetDefinitionDict
{
    return inputFilterSetDefinitionDict;
}

-(NSMutableDictionary *)scriptDefinitionDict
{
    return scriptDefinitionDict;
}

-(NSMutableDictionary *)fontEncodingDefinitionDict
{
    return fontEncodingDefinitionDict;
}

-(RTKIDDatabase *)generalDatabase
{    
    return generalDatabase;
}

#pragma mark -
// set definition from file methods


-(void)loadInputFilterSetDefinition:(NSString *)filePath
{
    NSLock *lock;
    if(filePath == nil)
        return;
    if([filePath length] == 0)
        return;
    
    if(!(lock = [inputFilterSetDefinitionLockDict objectForKey:filePath]))
    {
        lock = [[NSLock alloc] init];
        [inputFilterSetDefinitionLockDict setObject:lock
                                             forKey:filePath];
    }
    
    if([lock tryLock])
    {
        //NSLog(@"-- loadInputFilterSetDefinition");
        [inputFilterSetDefinitionDict setObject:[[RTKInputFilterSetDefinition alloc] initWithFilePath:filePath
                                                                                      usingIDDatabase:generalDatabase]
                                         forKey:filePath];
        //NSLog(@"**** loadInputFilterSetDefinition");
        [lock unlock];
    }
}


-(void)loadScriptDefinition:(NSString *)filePath
{
    NSLock *lock;
    if(filePath == nil)
        return;
    if([filePath length] == 0)
        return;
    if(!(lock = [scriptDefinitionLockDict objectForKey:filePath]))
    {
        lock = [[NSLock alloc] init];
        [scriptDefinitionLockDict setObject:lock
                                     forKey:filePath];
    }
    
    if([lock tryLock])
    {
        //NSLog(@"-- loadScriptDefinition");
        {
            [scriptDefinitionDict setObject:[[RTKScriptDefinition alloc] initWithFilePath:filePath
                                                                          usingIDDatabase:generalDatabase]
                                     forKey:filePath];
        }
        //NSLog(@"**** loadScriptDefinition");
        [lock unlock];
    }
}


-(void)loadFontEncodingDefinition:(NSString *)filePath
{
    NSLock *lock;
    if(filePath == nil)
        return;
    if([filePath length] == 0)
        return;
    
    if(!(lock = [fontEncodingDefinitionLockDict objectForKey:filePath]))
    {
        lock = [[NSLock alloc] init];
        [fontEncodingDefinitionLockDict setObject:lock
                                           forKey:filePath];
    }
    
    if([lock tryLock])
    {
        //NSLog(@"-- loadFontEncodingDefinition");
        
        [fontEncodingDefinitionDict setObject:[[RTKFontEncodingDefinition alloc] initWithFilePath:filePath
                                                                                  usingIDDatabase:generalDatabase]
                                       forKey:filePath];
        
        //NSLog(@"**** loadFontEncodingDefinition");
        [lock unlock];
    }
}

#pragma mark -
// methods to load definitions if needed


-(void)checkInputFilterSetDefinition:(NSString *)filePath
{
    if([inputFilterSetDefinitionDict objectForKey:filePath] == nil)
    {
        [self loadInputFilterSetDefinition:filePath];
    }
}


-(void)checkScriptDefinition:(NSString *)filePath
{
    if([scriptDefinitionDict objectForKey:filePath] == nil)
    {
        [self loadScriptDefinition:filePath];
    }
}


-(void)checkFontEncodingDefinition:(NSString *)filePath
{
    if([fontEncodingDefinitionDict objectForKey:filePath] == nil)
    {
        [self loadFontEncodingDefinition:filePath];
    }
}

// Make it reload the definition files.
- (void)resetDefinitions
{
    [inputFilterSetDefinitionDict removeAllObjects];
    [scriptDefinitionDict removeAllObjects];
    [fontEncodingDefinitionDict removeAllObjects];
}

#pragma mark -
// transcription methods


-(NSMutableDictionary *)convertString:(NSString *)input
                          inputSystem:(NSString *)theInputSystem
                         scriptSystem:(NSString *)theScriptSystem
                           fontSystem:(NSString *)theFontSystem
                      withMetaStrings:(BOOL)metaStrings
                  checkForPunctuation:(BOOL)punctuation
{    
    NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
    NSAutoreleasePool * autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    RTKLinkedListHeader *phonemicList;
    RTKLinkedListHeader *speechTreeList;
    RTKLinkedListHeader *scriptList;
    RTKLinkedListHeader *fontList;
    
    RTKInputFilterSetDefinition *inputFilterSetDefinition;
    RTKScriptDefinition *scriptDefinition;
    RTKFontEncodingDefinition *fontEncodingDefinition;
    
    [transcriptionLock lock];
    
    [self checkInputFilterSetDefinition:theInputSystem];
    [self checkScriptDefinition:theScriptSystem];
    [self checkFontEncodingDefinition:theFontSystem];
    
    inputFilterSetDefinition = [[inputFilterSetDefinitionDict objectForKey:theInputSystem] retain];
    scriptDefinition = [[scriptDefinitionDict objectForKey:theScriptSystem] retain];
    fontEncodingDefinition = [[fontEncodingDefinitionDict objectForKey:theFontSystem] retain];
    
    phonemicList = [[self phonemicListFromString:input 
                               usingInputFilter:inputFilterSetDefinition] retain];
    
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    
    speechTreeList = [RTKConvertor speechTreeFromPhonemeList:phonemicList
                                             usingIDDatabase:generalDatabase];    
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    scriptList = [scriptDefinition scriptListFromWordList:speechTreeList
                                          usingIDDatabase:generalDatabase
                                            defaultSeries:[generalDatabase idForString:@"defaultSeries"]
                                              firstSeries:[generalDatabase idForString:@"firstSeries"]
                                             secondSeries:[generalDatabase idForString:@"secondSeries"]
                                              presyllable:[generalDatabase idForString:@"presyllable"]
                                      beginningOfSyllable:[generalDatabase idForString:@"beginningOfSyllable"]
                                            endOfSyllable:[generalDatabase idForString:@"endOfSyllable"]
                                          beginningOfWord:[generalDatabase idForString:@"beginningOfWord"]
                                                endOfWord:[generalDatabase idForString:@"endOfWord"]];

    
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    
    fontList = [fontEncodingDefinition fontCharacterListFromScriptList:scriptList
                                                       usingIDDatabase:generalDatabase];

    
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    [dataDict setObject:[RTKConvertor getStringFromList:fontList
                                        usingIDDatabase:generalDatabase]
                 forKey:@"RTKFont"];
    
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    if(metaStrings == YES)
    {
        [dataDict setObject:[RTKConvertor getStringFromList:phonemicList
                                            usingIDDatabase:generalDatabase]
                     forKey:@"RTKPhonemic"];
        
        [dataDict setObject:[RTKConvertor getStringFromList:scriptList
                                            usingIDDatabase:generalDatabase]
                     forKey:@"RTKScript"];
        
        [dataDict setObject:[self codepointStringForString:[dataDict objectForKey:@"RTKFont"]]
                                                    forKey:@"RTKCodepoint"];
    }
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    
    if(punctuation == YES)
    {
        [dataDict setObject:([RTKConvertor findXMLTagOfType:[generalDatabase idForString:@"punctuation"]
                                                   position:0
                                                     inList:phonemicList
                                                 startingAt:[phonemicList first]
                                                         to:nil] != nil) ? @"YES" : @"NO"
                     forKey:@"RTKContainsPunctuation"];
    }
    
    [autoreleasePool release];
    autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    [phonemicList release];
    [speechTreeList release];
    [scriptList release];
    [fontList release];    
    
    [inputFilterSetDefinition release];
    [scriptDefinition release];
    [fontEncodingDefinition release];
    
    [autoreleasePool release];
   // autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    [transcriptionLock unlock];
    return dataDict;
}


-(RTKLinkedListHeader *)phonemicListFromString:(NSString *)inputString
                              usingInputFilter:(RTKInputFilterSetDefinition*)inputFilter
{
    RTKLinkedListHeader *phonemicList;
    RTKLinkedListNode *currentMarkerNode;
    RTKIDMarker *currentMarker;
    
    const int BREAK	    = [generalDatabase idForString:@"break"];
    const int WORDBREAK	    = [generalDatabase idForString:@"wordBreak"];
    
    phonemicList = [RTKConvertor characterListFromString:inputString];
    
    currentMarker = [[RTKIDMarker alloc] initWithIDNumber:WORDBREAK
                                                     type:BREAK];
    currentMarkerNode = [[RTKLinkedListNode alloc] initWithData:(id)currentMarker];
    [currentMarker release];
    [phonemicList insertAtFront:currentMarkerNode];
    [currentMarkerNode release];
    
    currentMarker = [[RTKIDMarker alloc] initWithIDNumber:WORDBREAK
                                                     type:BREAK];
    currentMarkerNode = [[RTKLinkedListNode alloc] initWithData:(id)currentMarker];
    [currentMarker release];
    [phonemicList insertAtBack:currentMarkerNode];
    [currentMarkerNode release];
    
    [inputFilter parse:phonemicList];
    
    { // Cut any remaining chars out
        Class idMarkerClass = [RTKIDMarker class];
        RTKLinkedListNode *currentNode = [phonemicList first];
        while(currentNode != nil)
        {
            RTKLinkedListNode *nextNode = [currentNode next];
            RTKIDMarker *currentPhoneme = [currentNode data];
            
            if([currentPhoneme class] != idMarkerClass)
            {
                [phonemicList remove:currentNode];
            }
            currentNode = nextNode;
        }
    }
    return phonemicList;
}



-(NSString *)codepointStringForString:(NSString *)string
{
    int length = [string length];
    NSString * codepointString = @"";
    {
        int i;
        for(i=0; i<length; i++)
        {
            codepointString = [codepointString stringByAppendingString:[NSString stringWithFormat:@"\\u%x ",[string characterAtIndex:i]]];
        }
    }
    return codepointString;
}




#pragma mark -
// database access methods


-(int)lookupNumberForString:(NSString *)theString
{
    int idNumber;
    RTKLinkedListHeader *theList = [RTKConvertor characterListFromString:theString];
    idNumber = [generalDatabase lookupIDNumber:theList];
    [theList release];
    return idNumber;
}


-(NSString *)stringForID:(int)theIDNumber
{
    return [generalDatabase stringForID:theIDNumber];
}

-(int)lookupNumberForList:(RTKLinkedListHeader *)theList
{
    return [generalDatabase lookupIDNumber:theList];
}


#pragma mark -

// Class methods

+ (RTKLinkedListHeader *)characterListFromString:(NSString *)theString
{
    RTKLinkedListHeader * list = [[RTKLinkedListHeader alloc] init];
    unsigned int count = 0;
    unsigned int length = [theString length];
    
    for(count = 0; count < length; count++)
    {
		id character = [(RTKFontCharacter *)[RTKFontCharacter alloc] initWithCharacter:
            [theString characterAtIndex:count]];
        RTKLinkedListNode *node = [[RTKLinkedListNode alloc] initWithData:character];
		[character release];
        [list insertAtBack:node];
        [node release];
    }
	[list autorelease];
    return list;
}


+ (NSString *)getStringFromList:(id)theList
                usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    NSMutableString * theString = [[NSMutableString alloc] init];
    
    id currentCharacter = [theList first];
    while(currentCharacter != nil)
    {
        id data = [currentCharacter data];
        
        if([data class] == [RTKFontCharacter class])
        {
            unichar theChar = [(RTKFontCharacter *)data character];
            unichar * charPtr = &theChar;
            
            NSString *tempStringFromChars = [[NSString alloc] initWithCharacters:charPtr
                                                                          length:(unsigned) 1];
            
            [theString appendString:tempStringFromChars];
            
            [tempStringFromChars release];
        }
        else if([data class] == [RTKIDMarker class])
        {
            [theString appendString:@"{"];
            
            [theString appendString:[idDatabase stringForID:[(RTKIDMarker *)data idNumber]]];
            [theString appendString:@"--"];
            [theString appendString:[idDatabase stringForID:[(RTKIDMarker *)data type]]];
            
            [theString appendString:@"} "];
        }
        else if([data class] == [RTKScriptWord class])
        {
            [theString appendString:@"<sw>"];
            [theString appendString:[RTKConvertor getStringFromList:[(RTKScriptWord *)data clusterList]
                                                    usingIDDatabase:idDatabase]];
            [theString appendString:@"</sw> "];
        }
        else if([data class] == [RTKScriptPunctuationGroup class])
        {
            [theString appendString:@"<spg>"];
            [theString appendString:[RTKConvertor getStringFromList:[(RTKScriptPunctuationGroup *)data punctuationList]
                                                    usingIDDatabase:idDatabase]];
            [theString appendString:@"</spg> "];
        }
        else if([data class] == [RTKScriptCluster class])
        {
            [theString appendString:@"<scl>"];
            [theString appendString:[RTKConvertor getStringFromList:[(RTKScriptCluster *)data characterList]
                                                    usingIDDatabase:idDatabase]];
            [theString appendString:@"</scl>"];
        }
        currentCharacter = [currentCharacter next];
    }
    
    //[theString autorelease];
    return theString;
}


+(RTKLinkedListHeader *)speechTreeFromPhonemeList:(RTKLinkedListHeader *)phonemeList
                                  usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    RTKLinkedListHeader *wordList = [[RTKLinkedListHeader alloc ] init];
    
    const int BREAK	        = [idDatabase idForString:@"break"];
    const int PUNCTUATION   = [idDatabase idForString:@"punctuation"];
    const int WORDBREAK	    = [idDatabase idForString:@"wordBreak"];
    const int SYLLABLEBREAK = [idDatabase idForString:@"syllableBreak"];
    const int CONSONANT     = [idDatabase idForString:@"consonant"];
    const int VOWEL         = [idDatabase idForString:@"vowel"];
    const int PRESYLLABLE   = [idDatabase idForString:@"presyllable"];
    
    RTKSyllableUnit *currentSyllable = [[RTKSyllableUnit alloc] init];
    RTKWordUnit *currentWord = [[RTKWordUnit alloc] init];
    RTKPunctuationGroupUnit *currentPuncGroup = [[RTKPunctuationGroupUnit alloc] init];
    RTKLinkedListHeader *currentPhonemeList = [currentSyllable phonemeList];
    RTKLinkedListHeader *currentSyllableList = [currentWord syllableList];
    RTKLinkedListHeader *currentPuncList = [currentPuncGroup punctuationList];
    
    RTKLinkedListNode *currentPhonemeNode = [phonemeList first];
    while(currentPhonemeNode != nil)
    {
        id currentPhoneme = [currentPhonemeNode data];
        
        int type = (int)[(RTKIDMarker *)currentPhoneme type];
        int idNumber = (int)[(RTKIDMarker *)currentPhoneme idNumber];
        
        if(type == BREAK)
        {
            if(idNumber == SYLLABLEBREAK)
            {
                if([currentPhonemeList count] > 0)
                {
                    [[RTKLinkedListNode alloc] initWithData:currentSyllable
                                               atBackOfList:currentSyllableList];
                    [currentSyllable release];
                    currentSyllable = [[RTKSyllableUnit alloc] init];
                    currentPhonemeList = [currentSyllable phonemeList];
                }
            }
            else if(idNumber == WORDBREAK)
            {
                if([currentPhonemeList count] > 0)
                {
                    [[RTKLinkedListNode alloc] initWithData:currentSyllable
                                               atBackOfList:currentSyllableList];
                    [currentSyllable release];
                    currentSyllable = [[RTKSyllableUnit alloc] init];
                    currentPhonemeList = [currentSyllable phonemeList];
                }
                
                if([currentSyllableList count] > 0)
                {
                    [[RTKLinkedListNode alloc] initWithData:currentWord
                                               atBackOfList:wordList];
                    [currentWord release];
                    currentWord = [[RTKWordUnit alloc] init];
                    currentSyllableList = [currentWord syllableList];
                }
                if([currentPuncList count] > 0)
                {
                    [[RTKLinkedListNode alloc] initWithData:currentPuncGroup
                                               atBackOfList:wordList];
                    [currentPuncGroup release];
                    currentPuncGroup = [[RTKPunctuationGroupUnit alloc] init];
                    currentPuncList = [currentPuncGroup punctuationList];
                }
            }
        }
        else if(type == PUNCTUATION)
        {
            RTKPunctuationUnit *punc = [[RTKPunctuationUnit alloc] initWithIDNumber:[currentPhoneme idNumber]];
            [[RTKLinkedListNode alloc] initWithData:punc
                                       atBackOfList:currentPuncList];
            [punc release];
        }
        else if(type == CONSONANT || type == VOWEL)
        {
            [[RTKLinkedListNode alloc] initWithData:currentPhoneme
                                       atBackOfList:currentPhonemeList];
            
            
            if(type == CONSONANT)
            {
                if([currentSyllable firstConsonant] == 0)
                {
                    [currentSyllable setFirstConsonant:idNumber];
                }
                else if([currentSyllable vowel] == 0)
                {
                    if([currentSyllable secondConsonant] == 0)
                    {
                        [currentSyllable setSecondConsonant:idNumber];
                    }
                }
                else if([currentSyllable finalConsonant] == 0)
                {
                    [currentSyllable setFinalConsonant:idNumber];
                }
            }
            else if(type == VOWEL)
            {
                if([currentSyllable firstConsonant] != 0)
                    if([currentSyllable vowel] == 0)
                        [currentSyllable setVowel:idNumber];
            }
        }
        else if(type == PRESYLLABLE) // a marker tag that is inserted
        {
            [currentSyllable setType:PRESYLLABLE];
        }
        currentPhonemeNode = [currentPhonemeNode next];
    }
    
    return wordList;
}


+(RTKLinkedListHeader *)loadTagListFromFilePath:(NSString *)filePath
{
    RTKLinkedListHeader * listFromFile;
    RTKFilter * xmlParsingFilter;
    id theFile = [[NSFileWrapper alloc] initWithPath:filePath];
    NSData * theFileData = [theFile regularFileContents];
    NSLog(@"--> listOfByteBlock:");
    listFromFile = [self listOfByteBlock:[theFileData bytes]
                                ofLength:[theFileData length]];
    NSLog(@"<-- listOfByteBlock:");
    xmlParsingFilter = [self makeXMLParsingFilter];
    NSLog(@"--> parse:listFromFile:");
    [xmlParsingFilter parse:listFromFile testing:NO];
    NSLog(@"<-- parse:listFromFile:");
    [xmlParsingFilter release];
    
    return listFromFile;
}


+(RTKLinkedListHeader *)listOfByteBlock:(const char *)bytes
                               ofLength:(unsigned)length
{
    if(length > 0)
    {
        unsigned i;
        RTKFontCharacter *currentChar = [(RTKFontCharacter *)[RTKFontCharacter alloc] initWithCharacter:bytes[0]];
        RTKLinkedListNode *currentNode = [[RTKLinkedListNode alloc] initWithData:(id)currentChar];
        RTKLinkedListNode *first = currentNode;
        RTKLinkedListNode *formerNode = currentNode;
        [currentChar release];
        if(length > 1)
        {
            for(i = 1; i < length; i++)
            {
                currentChar = [(RTKFontCharacter *)[RTKFontCharacter alloc] initWithCharacter:bytes[i]];
                currentNode = [[RTKLinkedListNode alloc] initWithData:(id)currentChar];
                [currentChar release];
                [formerNode setNext:currentNode];
                [currentNode setBack:formerNode];
                formerNode = currentNode;
            }
        }
        return [[RTKLinkedListHeader alloc] initWithFirst:first last:currentNode count:length];
    }
    return [[RTKLinkedListHeader alloc] init];
}


@end


//
//  RTKFontEncodingDefinition.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKFontEncodingDefinition.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKIDDatabase.h"

#import "RTKScriptWord.h"
#import "RTKScriptCluster.h"
#import "RTKGlyphAlias.h"
#import "RTKFontGlyphDefinition.h"
#import "RTKScriptPunctuationGroup.h"

#import "RTKFontCharacterDefinition.h"
#import "RTKGlyphAlias.h"

#import "RTKIDMarker.h"
#import "RTKGlobals.h"
#import <AppKit/AppKit.h>


@implementation RTKFontEncodingDefinition

// persistence

NSString *RTKFontEncodingDefinitionPListType = @"RTKFontEncodingDefinitionPListType";
NSString *RTKFontCharacterDefinitionList = @"RTKFontCharacterDefinitionList";


-(id)initWithFilePath:(NSString *)filePath
      usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    if(self = [super init])
    {
        fontCharacterDefinitionList = nil;

        [self readXMLpListFromFile:filePath];

        fontCharacterDefinitionTree = [[RTKBinaryTreeHeader alloc] initWithList:fontCharacterDefinitionList];
    }
    return self;
}


- (void)dealloc
{
    [fontCharacterDefinitionList release];
    [fontCharacterDefinitionTree release];
    [super dealloc];
}


-(void)readXMLpListFromFile:(NSString *)filePath
{
    id theFile = [[NSFileWrapper alloc] initWithPath:filePath];
    NSData *theFileData = [theFile regularFileContents];

    NSDictionary *dict = [self dictionaryFromData:theFileData];

    NSArray *array = [dict objectForKey:RTKFontCharacterDefinitionList];
    fontCharacterDefinitionList = [[RTKLinkedListHeader alloc] initWithArray:array];
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
    NSData *fileData = [self dataRepresentationOfType:RTKFontEncodingDefinitionPListType];

    id theFile = [[NSFileWrapper alloc] initRegularFileWithContents:fileData];

    [theFile writeToFile:filePath
              atomically:NO
         updateFilenames:YES];

    return YES;
}



-(NSData *)dataRepresentationOfType:(NSString *)type
{
    if([type isEqualToString:RTKFontEncodingDefinitionPListType])
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

    NSArray *array = (NSArray *)[fontCharacterDefinitionList propertyListRepresentation];
    if(array != nil)
        [doc setObject:array forKey:RTKFontCharacterDefinitionList];

    [doc setObject:NSStringFromClass([self class])
            forKey:RTKClass];

    return doc;
}



-(RTKLinkedListHeader *)fontCharacterListFromScriptList:(RTKLinkedListHeader *)scriptList
                                        usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    RTKLinkedListHeader *fontCharacterList = [[RTKLinkedListHeader alloc] init];

    RTKLinkedListNode *currentWordNode = [scriptList first];
    while(currentWordNode != nil)
    {
        id currentWord = [currentWordNode data];
        Class currentWordClass = [currentWord class];

        if(currentWordClass == [RTKScriptWord class])
            [self scriptWord:currentWord appendTo:fontCharacterList usingIDDatabase:idDatabase];
        else if(currentWordClass == [RTKScriptPunctuationGroup class])
            [self punctuationGroup:currentWord appendTo:fontCharacterList usingIDDatabase:idDatabase];


        currentWordNode = [currentWordNode next];
    }

    return fontCharacterList;
}


-(void)scriptWord:(RTKScriptWord *)scriptWord
         appendTo:(RTKLinkedListHeader *)fontCharacterList
  usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    RTKLinkedListNode *currentClusterNode = [[scriptWord clusterList] first];
    while(currentClusterNode != nil)
    {
        RTKScriptCluster *currentCluster = [currentClusterNode data];

        [self scriptCluster:currentCluster appendTo:fontCharacterList usingIDDatabase:idDatabase];

        currentClusterNode = [currentClusterNode next];
    }
}


-(void)punctuationGroup:(RTKScriptPunctuationGroup *)puncGroup
               appendTo:(RTKLinkedListHeader *)fontCharacterList
        usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    RTKLinkedListHeader *glyphAliasList = [self setupGlyphAliasListFromCharacterList:[puncGroup punctuationList]];
    [self glyphAliasList:glyphAliasList toFontCharacterList:fontCharacterList];
}


-(void)scriptCluster:(RTKScriptCluster *)scriptCluster
            appendTo:(RTKLinkedListHeader *)fontCharacterList
     usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    RTKLinkedListHeader *glyphAliasList = [self glyphAliasListFromCluster:scriptCluster];

    [self glyphAliasList:glyphAliasList
     toFontCharacterList:fontCharacterList];
}


-(RTKLinkedListHeader *)glyphAliasListFromCluster:(RTKScriptCluster *)cluster
{
    RTKLinkedListHeader *glyphAliasList = [self setupGlyphAliasList:cluster];

    [self meshGlyphs:glyphAliasList forCharacters:[cluster characterList]];

    return glyphAliasList;
}


-(BOOL)clickGlyphNode:(RTKLinkedListNode *)glyphNode
{
    if(![(RTKGlyphAlias *)[glyphNode data] click])
    {
        RTKLinkedListNode *nextGlyphNode = [glyphNode next];
        if(nextGlyphNode == nil)
            return NO;
        else
            return [self clickGlyphNode:nextGlyphNode];
    }
    return YES;
}


-(void)meshGlyphs:(RTKLinkedListHeader *)glyphAliasList
    forCharacters:(RTKLinkedListHeader *)characterList
{
    while([self glyphsMeshed:glyphAliasList forCharacters:characterList] == NO)
    {
        if(![self clickGlyphNode:[glyphAliasList first]])
            break;
    }
}


-(BOOL)noOverlappingRegions:(RTKLinkedListHeader *)glyphAliasList
{
    RTKBinaryTreeHeader *regionTree = [[RTKBinaryTreeHeader alloc] initWithOrder:ORDER_BY_DEFAULT];

    RTKLinkedListNode *currentGlyphAliasNode = [glyphAliasList first];
    while(currentGlyphAliasNode != nil)
    {
        RTKGlyphAlias *currentGlyphAlias = [currentGlyphAliasNode data];

        RTKLinkedListNode *currentRegionNode = [[[currentGlyphAlias glyph] regionList] first];
        while(currentRegionNode != nil)
        {
            RTKIDMarker *currentRegion = [currentRegionNode data];
            if(![regionTree insertIfNoMatch:currentRegion returnNode:nil])
            {
                [regionTree release];
                return NO;
            }
            currentRegionNode = [currentRegionNode next];
        }
        currentGlyphAliasNode = [currentGlyphAliasNode next];
    }
    [regionTree release];
    return YES;
}


-(BOOL)charList:(RTKLinkedListHeader *)characterList
hasNoIncompatibleCharsFor:(RTKLinkedListHeader *)glyphAliasList
{
    RTKBinaryTreeHeader *charTree = [[RTKBinaryTreeHeader alloc] initWithOrder:ORDER_BY_DEFAULT];
    {
        // make tree of incompatible chars
        RTKLinkedListNode *currentGlyphAliasNode = [glyphAliasList first];
        while(currentGlyphAliasNode != nil)
        {
            RTKLinkedListHeader *charList = [[[currentGlyphAliasNode data] glyph] incompatibleCharList];
            RTKLinkedListNode *currentCharNode = [charList first];
            while(currentCharNode != nil)
            {
                RTKIDMarker *scriptChar = [[RTKIDMarker alloc] initWithIDNumber:[[currentCharNode data] idNumber]];
                [charTree insert:scriptChar];
                [scriptChar release];
                currentCharNode = [currentCharNode next];
            }
            currentGlyphAliasNode = [currentGlyphAliasNode next];
        }
    }

    {
        // walk through characterList and check instanceExists
        // if yes, then return NO;
        RTKLinkedListNode *currentCharNode = [characterList first];
        while(currentCharNode != nil)
        {
            if([charTree instanceExists:[currentCharNode data]])
            {
                [charTree release];
                return NO;
            }
            currentCharNode = [currentCharNode next];
        }
    }
    [charTree release];
    return YES;
}


-(BOOL)charList:(RTKLinkedListHeader *)characterList
hasNeededCharsFor:(RTKLinkedListHeader *)glyphAliasList
{
    // make tree of characterList
    RTKBinaryTreeHeader *characterTree = [[RTKBinaryTreeHeader alloc] init];
    {
        RTKLinkedListNode *currentCharNode = [characterList first];
        while(currentCharNode != nil)
        {
            [characterTree insert:[currentCharNode data]];
            currentCharNode = [currentCharNode next];
        }
    }

    {
        RTKLinkedListNode *currentGlyphNode = [glyphAliasList first];
        while(currentGlyphNode != nil)
        {
            RTKLinkedListNode *currentCharNode = [[[[currentGlyphNode data] glyph] neededCharList] first];
            while(currentCharNode != nil)
            {
                if(![characterTree instanceExists:[currentCharNode data]])
				{
					[characterTree release];
                    return NO;
				}
                currentCharNode = [currentCharNode next];
            }
            currentGlyphNode = [currentGlyphNode next];
        }
    }
	[characterTree release];
    return YES;
}


-(BOOL)glyphsMeshed:(RTKLinkedListHeader *)glyphAliasList
      forCharacters:(RTKLinkedListHeader *)characterList
{
    if(![self noOverlappingRegions:glyphAliasList])
        return NO;

    if(![self charList:characterList hasNoIncompatibleCharsFor:glyphAliasList])
        return NO;

    if(![self charList:characterList hasNeededCharsFor:glyphAliasList])
        return NO;

    return YES;
}


-(RTKLinkedListHeader *)setupGlyphAliasListFromCharacterList:(RTKLinkedListHeader *)characterList
{
    RTKLinkedListHeader *glyphAliasList = [[RTKLinkedListHeader alloc] init];

    RTKLinkedListNode *currentCharacterNode = [characterList first];
    while(currentCharacterNode != nil)
    {
        RTKGlyphAlias *currentGlyphAlias;
		RTKIDMarker *currentCharacter = [currentCharacterNode data];

        RTKFontCharacterDefinition *tempCharacterDefinition = [(RTKFontCharacterDefinition *)[RTKFontCharacterDefinition alloc] initWithCharacter:[currentCharacter idNumber]];

        RTKFontCharacterDefinition *characterDefinition = [[[[fontCharacterDefinitionTree findNode:tempCharacterDefinition] instanceList] first] data];
		
		[tempCharacterDefinition release];
		
        currentGlyphAlias = [(RTKGlyphAlias *)[RTKGlyphAlias alloc] initWithCharacter:characterDefinition] ;
        [[RTKLinkedListNode alloc] initWithData:currentGlyphAlias
                                   atBackOfList:glyphAliasList];
        [currentGlyphAlias release];

        currentCharacterNode = [currentCharacterNode next];
    }
	[glyphAliasList autorelease];
    return glyphAliasList;
}


-(RTKLinkedListHeader  *)setupGlyphAliasList:(RTKScriptCluster *)cluster
{
    return [self setupGlyphAliasListFromCharacterList:[cluster characterList]];
}


-(void)glyphAliasList:(RTKLinkedListHeader *)glyphAliasList
  toFontCharacterList:(RTKLinkedListHeader *)fontCharacterList
{
    RTKLinkedListHeader *beforeList = [[RTKLinkedListHeader alloc] init];
    RTKLinkedListHeader *positionList = [[RTKLinkedListHeader alloc] init];
    RTKLinkedListHeader *afterList = [[RTKLinkedListHeader alloc] init];

    RTKLinkedListNode *currentGlyphAliasNode = [glyphAliasList first];
    while(currentGlyphAliasNode != nil)
    {
        RTKGlyphAlias *currentGlyphAlias = [currentGlyphAliasNode data];
        RTKFontGlyphDefinition *currentGlyph = [currentGlyphAlias glyph];

        RTKLinkedListHeader *tempClonedList = [[currentGlyph beforePartialGlyphList] clone];
        [beforeList prepend:tempClonedList];
        [tempClonedList release];

        tempClonedList = [[currentGlyph positionPartialGlyphList] clone];
        [positionList append:tempClonedList];
        [tempClonedList release];

        tempClonedList = [[currentGlyph afterPartialGlyphList] clone];
        [afterList append:tempClonedList];
        [tempClonedList release];

        currentGlyphAliasNode = [currentGlyphAliasNode next];
    }
    [fontCharacterList append:beforeList];
    [fontCharacterList append:positionList];
    [fontCharacterList append:afterList];

    [beforeList release];
    [positionList release];
    [afterList release];
}

@end

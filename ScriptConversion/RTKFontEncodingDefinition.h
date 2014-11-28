//
//  RTKFontEncodingDefinition.h
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




//#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "RTKLinkedListHeader.h"
#import "RTKBinaryTreeHeader.h"
#import "RTKIDDatabase.h"
#import "RTKScriptWord.h"
#import "RTKScriptPunctuationGroup.h"
#import "RTKScriptCluster.h"
#import "RTKScriptPunctuationGroup.h"



@interface RTKFontEncodingDefinition : NSObject
{
    RTKLinkedListHeader *fontCharacterDefinitionList;
    RTKBinaryTreeHeader *fontCharacterDefinitionTree;
}

-(id)initWithFilePath:(NSString *)filePath
      usingIDDatabase:(RTKIDDatabase *)idDatabase;

-(RTKLinkedListHeader *)fontCharacterListFromScriptList:(RTKLinkedListHeader *)scriptList
                                                                    usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(RTKLinkedListHeader *)fontCharacterDefinitionListFromChildList:(RTKLinkedListHeader *)childList
                                                                                    usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(void)scriptWord:(RTKScriptWord *)scriptWord
                appendTo:(RTKLinkedListHeader *)fontCharacterList
  usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(void)punctuationGroup:(RTKScriptPunctuationGroup *)puncGroup
                      appendTo:(RTKLinkedListHeader *)fontCharacterList
               usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(void)scriptCluster:(RTKScriptCluster *)scriptCluster
                   appendTo:(RTKLinkedListHeader *)fontCharacterList
     usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(void)punctuationGroup:(RTKScriptPunctuationGroup *)puncGroup
                      appendTo:(RTKLinkedListHeader *)fontCharacterList
               usingIDDatabase:(RTKIDDatabase *)idDatabase;
-(RTKLinkedListHeader *)glyphAliasListFromCluster:(RTKScriptCluster *)cluster;
-(void)glyphAliasList:(RTKLinkedListHeader *)glyphAliasList
  toFontCharacterList:(RTKLinkedListHeader *)fontCharacterList;
-(RTKLinkedListHeader  *)setupGlyphAliasList:(RTKScriptCluster *)cluster;
-(void)meshGlyphs:(RTKLinkedListHeader *)glyphAliasList
    forCharacters:(RTKLinkedListHeader *)characterList;
-(RTKLinkedListHeader *)setupGlyphAliasListFromCharacterList:(RTKLinkedListHeader *)characterList;
-(BOOL)glyphsMeshed:(RTKLinkedListHeader *)glyphAliasList
      forCharacters:(RTKLinkedListHeader *)characterList;

-(BOOL)writeXMLpListToFile:(NSString *)filePath;
-(void)readXMLpListFromFile:(NSString *)filePath;
- (NSDictionary *)dictionaryFromData:(NSData *)data;
-(NSData *)dataRepresentationOfType:(NSString *)type;
-(NSData *)pListDocumentData;
-(NSDictionary *)dictionary;


@end

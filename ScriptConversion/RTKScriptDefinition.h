//
//  RTKScriptDefinition.h
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
#import "RTKLinkedListHeader.h"
#import "RTKBinaryTreeHeader.h"
#import "RTKIDDatabase.h"


enum // for cluster positions
{
    kOnlyCluster,
    kFirstCluster,
    kInternalCluster,
    kLastCluster
};


@interface RTKScriptDefinition : NSObject 
{
    RTKLinkedListHeader *consonantList;
    RTKLinkedListHeader *vowelList;
    RTKLinkedListHeader *presyllableVowelList;
    RTKLinkedListHeader *filterList;
    
    RTKBinaryTreeHeader *consonantTree;
    RTKBinaryTreeHeader *vowelTree;
    RTKBinaryTreeHeader *presyllableVowelTree;
}

-(id)initWithFilePath:(NSString *)filePath
      usingIDDatabase:(RTKIDDatabase *)idDatabase;
			     
-(RTKLinkedListHeader *)scriptListFromWordList:(RTKLinkedListHeader *)wordList
			    usingIDDatabase:(RTKIDDatabase *)idDatabase
			      defaultSeries:(const int)DEFAULTSERIES
			        firstSeries:(const int)FIRSTSERIES
			       secondSeries:(const int)SECONDSERIES
			        presyllable:(const int)PRESYLLABLE
                        beginningOfSyllable:(const int)BEGINNINGOFSYLLABLE
                              endOfSyllable:(const int)ENDOFSYLLABLE
                            beginningOfWord:(const int)BEGINNINGOFWORD
                                  endOfWord:(const int)ENDOFWORD;
			    
-(RTKBinaryTreeHeader *)consonantTree;

-(RTKBinaryTreeHeader *)vowelTree;

-(RTKBinaryTreeHeader *)presyllableVowelTree;

-(RTKLinkedListHeader *)filterList;

-(BOOL)writeXMLpListToFile:(NSString *)filePath;
-(void)readXMLpListFromFile:(NSString *)filePath;
- (NSDictionary *)dictionaryFromData:(NSData *)data;
-(NSData *)dataRepresentationOfType:(NSString *)type;
-(NSData *)pListDocumentData;
-(NSDictionary *)dictionary;




@end

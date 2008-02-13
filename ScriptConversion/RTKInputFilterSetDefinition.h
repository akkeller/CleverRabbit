//
//  RTKInputFilterSetDefinition.h
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
#import "RTKIDDatabase.h"
#import <AppKit/AppKit.h>


@interface RTKInputFilterSetDefinition : NSDocument
{
    RTKLinkedListHeader *filterList;
}

-(id)initWithXMLpListFilePath:(NSString *)filePath;
-(id)initWithFilePath:(NSString *)filePath
      usingIDDatabase:(RTKIDDatabase *)idDatabase;

-(void)parse:(RTKLinkedListHeader *)list;
-(void)readXMLpListFromFile:(NSString *)filePath;
-(void)readXMLpListFromFile:(NSString *)filePath;
-(NSData *)dataRepresentationOfType:(NSString *)type;
-(NSData *)pListDocumentDataForFilterList:(RTKLinkedListHeader *)list;
-(NSDictionary *)filterSetDictionaryForList:(RTKLinkedListHeader *)list;
- (NSDictionary *)dictionaryFromData:(NSData *)data;

- (RTKLinkedListHeader *)filterList;

@end

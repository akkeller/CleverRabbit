//
//  RTKInputFilterSetDefinition.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKInputFilterSetDefinition.h"
#import "RTKIDDatabase.h"
#import "RTKContextualParsing.h"

#import "RTKGlobals.h"


NSString *RTKFilterSetPListType = @"RTKFilterSetPListType";
NSString *RTKFilterSetKey = @"RTKFilterSetKey";

@implementation RTKInputFilterSetDefinition


-(NSData *)dataRepresentationOfType:(NSString *)type
{
    if([type isEqualToString:RTKFilterSetPListType])
    {
        return [self pListDocumentDataForFilterList:filterList];
    }
    else
    {
        return nil;
    }
}


- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    NSLog(@"Thinking of loading ");
    // Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
    if([aType isEqualToString:RTKFilterSetPListType])
    {
        NSDictionary *dict = [self dictionaryFromData:data];
        NSArray *array = [dict objectForKey:RTKFilterSetKey];
        
        filterList = [[RTKLinkedListHeader alloc] initWithArray:array];
        NSLog(@"filterList: %@ self: %@", filterList, self);
        NSLog(@"Loading");
        return YES;
    }
    return NO;
}


-(id)initWithXMLpListFilePath:(NSString *)filePath
{
    if(self = [super init])
    {
        [self readXMLpListFromFile:filePath];
    }
    return self;
}

- (void)dealloc
{
    [filterList release];
    [super dealloc];
}


-(void)readXMLpListFromFile:(NSString *)filePath
{
    id theFile = [[NSFileWrapper alloc] initWithPath:filePath];
    NSData *theFileData = [theFile regularFileContents];
    NSDictionary *dict = [self dictionaryFromData:theFileData];
    NSArray *array = [dict objectForKey:RTKFilterSetKey];
    
    filterList = [[RTKLinkedListHeader alloc] initWithArray:array];
}


- (NSDictionary *)dictionaryFromData:(NSData *)data 
{
    NSString *string = [[NSString allocWithZone:[self zone]] initWithData:data 
                                                                 encoding:NSASCIIStringEncoding];
    NSDictionary *doc = [string propertyList];
    [string release];
    return doc;
}


-(BOOL)writeXMLpListToFile:(NSString *)filePath
{
    NSData *fileData = [self dataRepresentationOfType:RTKFilterSetPListType];
    id theFile = [[NSFileWrapper alloc] initRegularFileWithContents:fileData];

    [theFile writeToFile:filePath
              atomically:NO
         updateFilenames:YES];
        
    return YES;
}


-(NSData *)pListDocumentDataForFilterList:(RTKLinkedListHeader *)list
{
    NSDictionary *doc = [self filterSetDictionaryForList:list];
    NSString *string = [doc description];
    return [string dataUsingEncoding:NSASCIIStringEncoding];
}


-(NSDictionary *)filterSetDictionaryForList:(RTKLinkedListHeader *)list
{
    NSMutableDictionary *doc = [NSMutableDictionary dictionary];
    NSMutableArray *filterDicts = [list propertyListRepresentation];

    if(filterDicts != nil)
        [doc setObject:filterDicts forKey:RTKFilterSetKey];

    [doc setObject:NSStringFromClass([self class])
            forKey:RTKClass];
    
    return doc;    
}


-(id)initWithFilePath:(NSString *)filePath
      usingIDDatabase:(RTKIDDatabase *)idDatabase
{
    if(self = [super init])
    {
        filterList = nil;
        [self readXMLpListFromFile:filePath];
    }
    return self;
}


-(void)parse:(RTKLinkedListHeader *)list
{
    [RTKContextualParsing parse:list
                           with:filterList
                        testing:NO];
}

-(RTKLinkedListHeader *)filterList
{
    NSLog(@"filterList: %@ self: %@", filterList, self);
    return filterList;
}


@end

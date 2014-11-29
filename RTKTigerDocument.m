    //
//   RTKTigerDocument.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import "RTKTigerDocument.h"
#import "RTKCleverRabbitController.h"
#import "RTKArrayCategory.h"
#import "RTKMutableArrayCategory.h"
#import "RTKStringCategory.h"
#import "RTKMutableAttributedStringCategory.h"
#import "RTKTigerTextView.h"

#import "Chomp.h"

#define RTKNOROWSELECTED -1

// This is likely temporary, a nasty relic of the project
// that the transcription code was borrowed from
id RTKSharedConvertor = nil;
id RTKSharedDatabase = nil;
id RTKClass = @"RTKClass";

// Test flag
//BOOL generateMetaStrings = YES;
BOOL generateMetaStrings = NO;

@implementation RTKTigerDocument

- (id)init
{
    if(self = [super init]) {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        
        [nc addObserver:self
               selector:@selector(substituteZVXChanged:)
                   name:@"RTKZVXSubstitutionChanged"
                 object:nil];
        
        [nc addObserver:self
               selector:@selector(plainTextDelimiterChanged:)
                   name:@"RTKPlainTextDelimiterChanged"
                 object:nil];
        
        [nc addObserver:self
               selector:@selector(definitionsChanged:)
                   name:@"RTKDefinitionsChanged"
                 object:nil];
        
        [nc addObserver:self
               selector:@selector(fontsChanged:)
                   name:@"RTKFontsChanged"
                 object:nil];
        
        [nc addObserver:self
               selector:@selector(transcriptionTypeChanged:)
                   name:@"RTKTranscriptionTypeChanged"
                 object:nil];
		
		[nc addObserver:self
               selector:@selector(transliterationOnChanged:)
                   name:@"RTKTransliterationOnChanged"
                 object:nil];

		
        book = [[RTKBook alloc] init];
        
        revisionsToConvert = [[NSMutableArray alloc] init];
        
        convertingLock = [[NSLock alloc] init];
        [convertingLock lock];
        
        // RTKSharedDatabase and RTKSharedConvertor are global for now.
        // They may not always be global, so don't depend on them.
        if(!RTKSharedConvertor)
            RTKSharedConvertor = [[RTKConvertor alloc] init];
        if(!RTKSharedDatabase)
            RTKSharedDatabase = [RTKSharedConvertor generalDatabase];
        
        [self setCreationDate:[NSDate dateWithTimeIntervalSinceNow:0.0]];
        
        [self setBindingsFromDictionary:nil];
        
        [self setVerseTypes:[NSMutableArray arrayWithObjects:
                             @"\\v", @"\\p", @"\\c", @"\\s1", @"\\s2", @"\\r", @"\\mt1", @"\\mt2", @"\\mt3", @"\\is", @"\\ip", @"\\h", nil]];
        [self setDictionary:[NSDictionary dictionary]];
		
        // Keep a transcription thread running at all times.
        [NSThread detachNewThreadSelector:@selector(doConversionThread:)
                                 toTarget:self
                               withObject:nil];
		
		alreadyAwokeFromNib = NO;
    }
    return self;
}

- (void)dealloc
{
    [book release];
    [draggedVerseIndexArray release];
    [visibleVerseIndexes release];
    [revisionsToConvert release];
    [verseTypes release];
    [inputDefinitionPath release];
    [scriptDefinitionPath release];
    [encodingDefinitionPath release];
    [convertingLock release];
    [revisionsToConvertLock release];
    [creationDate release];
    [dictionary release];
    
    [super dealloc];
}

- (void)awakeFromNib
{    
	if(!alreadyAwokeFromNib) {
		// Keep tabs on window state so as to avoid using UI objects after window has closed.
		windowIsOpen = YES;
		
		// Register for dragging.
		[versesTableView registerForDraggedTypes: [NSArray arrayWithObjects: @"RTKVersesInternalToBook", nil]];
		
		[versesTableView setTarget:self];
		//[versesTableView setDoubleAction:@selector(tableViewDoubleClicked)];
		
		[versesTableView setVerticalMotionCanBeginDrag:NO];
		
		[scriptTableColumn retain]; // Prevent dealloc of tablecolumn when hiding column. 
		[scriptView retain];
		if(![[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"]) {
			[versesTableView removeTableColumn:scriptTableColumn];
			[scriptView removeFromSuperview];
		}
		
		NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
		
		[self readSplitViewRectsFromDefaults];
		
		
		[self ensureOneBlankVerse];
		
		[self search:searchField];
		[documentWindow makeFirstResponder:romanTextView];
		
		[self setDictionary:[NSDictionary dictionary]];
        
		[self updateUI];
        
        [self updateRomanPublishedTextView];
		
        [self selectVerse:[[book verses] objectAtIndex:0]];
		
        [scriptTextView setAllowEditing:NO];
        
		alreadyAwokeFromNib = YES;
	}
    [super awakeFromNib];
}

#pragma mark -

- (BOOL)keepBackupFile
{
    return NO;
}


#pragma mark -
#pragma mark search

/*
 http://developer.apple.com/documentation/Cocoa/Conceptual/SearchFields/index.html
 */

- (IBAction)search:(id)sender
{
    NSString * searchString = [sender stringValue];
    NSMutableArray * indexes = [NSMutableArray array];
    [self setVisibleVerseIndexes:indexes];
    
    int i = 0;
    if([searchString length]) {
        NSEnumerator * e = [[book verses] objectEnumerator];
        RTKVerse * verse;
        while(verse = (RTKVerse *)[e nextObject]) {
            if([verse matchesString:searchString])
                [indexes addObject:[NSNumber numberWithInt: i]];
            i++;
        }
    } else {
        int count = [[book verses] count];
        for(i = 0; i < count; i++)
            [indexes addObject:[NSNumber numberWithInt: i]];
    }
    [self updateUI];
    [versesTableView noteNumberOfRowsChanged];
}

- (NSArray *)visibleVerseIndexes
{
    return visibleVerseIndexes;
}

- (void)setVisibleVerseIndexes:(NSArray *)indexes
{
    [indexes retain];
    [visibleVerseIndexes release];
    visibleVerseIndexes = indexes;
}

#pragma mark -
#pragma mark copy and paste
/*
 http://homepage.mac.com/svc/cocoa-objc-mac-os-x/
 http://www.knuddel.org/Projects/KoKit/Documentation/Gui/Reference/NSPasteboard.html
 http://developer.apple.com/documentation/Cocoa/Conceptual/CopyandPaste/index.html
 */

- (void)cut:(id)sender
{
    NSIndexSet * selectedIndexes = [versesTableView selectedRowIndexes];
    [self copy:sender];
    [book setVerses:(NSMutableArray *) [[book verses] arrayByRemovingObjectsAtIndexes:selectedIndexes]];
    [self ensureOneBlankVerse];
    
    [self search:searchField];
    [versesTableView noteNumberOfRowsChanged];
    int firstIndex = [selectedIndexes firstIndex];
    [versesTableView selectRow:(firstIndex > 0 ? firstIndex - 1 : 0) byExtendingSelection:NO];
    [self updateUI];
}

- (void)copy:(id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	
    NSIndexSet * selectedRowIndexes = [versesTableView selectedRowIndexes];
    NSMutableArray * verses = [book verses];
    NSMutableArray * selectedVerses = [verses arrayWithObjectsAtIndexes:selectedRowIndexes];
    
    RTKBook * newBook = [RTKBook bookWithVerses:selectedVerses];
    NSString * contents = [newBook string];
    [pasteboard setString:contents forType:NSStringPboardType];
	
	
    RTKCleverRabbitController * appController = [NSApp delegate];
    [appController setCopiedVersesArray:[selectedVerses deepCopy]];
    
    [pasteboard setData:nil forType:@"RTKBook"];
}

- (void)paste:(id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObject:@"RTKBook"]];
    if (type != nil) {
        NSUInteger lastIndex = [[versesTableView selectedRowIndexes] lastIndex];
        if(lastIndex == NSNotFound)
            lastIndex = [[book verses] count];
        else
            lastIndex++;
        
        RTKCleverRabbitController * appController = [NSApp delegate];
        NSArray * pastedVerses = [[appController copiedVersesArray] deepCopy];
        
        [[book verses] replaceObjectsInRange:NSMakeRange(lastIndex,0)
                        withObjectsFromArray:pastedVerses];
		
        [self ensureOneBlankVerse];
        [self search:searchField];
        [versesTableView noteNumberOfRowsChanged];
        [self updateUI];
        
        [versesTableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lastIndex, [pastedVerses count])] byExtendingSelection:NO];
    }
}

#pragma mark -
#pragma mark drag and drop
/* Some very handy links.
 http://www.nongnu.org/gstutorial/en/ch13s04.html
 http://borkware.com/quickies/one?topic=NSTableView
 http://borkware.com/quickies/everything-by-date
 */

- (void)setDraggedVerseIndexArray:(NSArray *)indexArray
{
    [indexArray retain];
    [draggedVerseIndexArray release];
    draggedVerseIndexArray = indexArray;
}

- (NSArray *)draggedVerseIndexArray
{
    return draggedVerseIndexArray;
}

- (BOOL)tableView: (NSTableView *)aTableView
        writeRows: (NSArray *)rows
     toPasteboard: (NSPasteboard *)pboard
{
    [pboard declareTypes: [NSArray arrayWithObjects: @"RTKVersesInternalToBook", nil] owner: self];
    
    // Ok, so we aren't putting an NSData object on the pasteboard.
    
    // That's ok because this is easier to write and doesn't involve a lot of messing about
    // with converting the data into different types when we just want to reorder a few verses
    // or copy verses between documents. 
    
    // Interapplication drag and drop will have to be handled in
    // a more standard data-copying fashion.
    
    // NSLog(@"dragging");
    // For same document...
    [self setDraggedVerseIndexArray:rows];
    
    // For between documents...
    RTKCleverRabbitController * appController = [NSApp delegate];
    [appController setDraggedVersesArray:[[book verses] arrayWithObjectsAtIndexes:rows]];
    [appController setDraggedVersesOwner:self];
    
    return YES;
}

- (NSDragOperation)tableView: (NSTableView *)aTableView
                validateDrop: (id <NSDraggingInfo>)item
                 proposedRow: (int)row
       proposedDropOperation: (NSTableViewDropOperation)op
{	/* Example found at http://www.nongnu.org/gstutorial/en/ch13s04.html */
    
    //NSLog(@"checking drop zone");
    
	if(row > [[book verses] count])
        return NSDragOperationNone;
    
	if([item draggingSource] == nil) {	// dragging from other application
		return NSDragOperationNone;
	} else if([item draggingSource] == versesTableView) {	// dragging within document
		[versesTableView setDropRow:row dropOperation:NSTableViewDropAbove];
		return NSDragOperationGeneric;
	} else {	// dragging between documents
		[versesTableView setDropRow:row dropOperation:NSTableViewDropAbove];
		return NSDragOperationCopy;
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)aTableView
       acceptDrop: (id <NSDraggingInfo>)item
              row: (int)row
    dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard *pboard = [item draggingPasteboard];
	RTKCleverRabbitController * appController = [NSApp delegate];
    
    if ([pboard availableTypeFromArray:[NSArray arrayWithObject: @"RTKVersesInternalToBook"]]) {
        if([appController draggedVersesOwner] == self) {
            NSMutableArray * verses = [book verses];
            NSMutableArray * draggedVerses = [verses arrayWithObjectsAtIndexes:draggedVerseIndexArray];
            
            int verseIndex = 0;
            if(row > 0)
                verseIndex = [[visibleVerseIndexes objectAtIndex:row - 1] intValue] + 1;
            
            [[verses doSelf] insertObject:[draggedVerses reverseObjectEnumerator]
                                  atIndex:verseIndex];
            
            int verseCount = [draggedVerseIndexArray count];
            
            NSEnumerator * e = [draggedVerseIndexArray reverseObjectEnumerator];
            NSNumber * n;
            int selectionPointCorrection = 0;
            while(n = [e nextObject]) {
                int i = [n intValue];
                [verses removeObjectAtIndex:(i < row ? i : i + verseCount)];
                
                if(i < row)
                    selectionPointCorrection++;
            }
			// TODO: check if not needed
            [versesTableView reloadData];
            
            [versesTableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:
                                               NSMakeRange((row - selectionPointCorrection), verseCount)]
                         byExtendingSelection:NO];
        } else {
            NSMutableArray * verses = [book verses];
            NSArray * draggedVerses = [appController draggedVersesArray];
            
            int verseIndex = 0;
            if(row > 0)
                verseIndex = [[visibleVerseIndexes objectAtIndex:row - 1] intValue] + 1;
			
            [[verses doSelf] insertObject:[draggedVerses reverseObjectEnumerator]
                                  atIndex:verseIndex];
            
            int verseCount = [draggedVerses count];
            
            // TODO: check if not needed
            [versesTableView reloadData];
            
            [versesTableView selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:
                                               NSMakeRange(row, verseCount)]
                         byExtendingSelection:NO];            
        }
        // TODO: Change this when undo/redo is supported
        [self updateChangeCount:NSChangeDone];
    }
    [self ensureOneBlankVerse];
    [searchField setStringValue:@""];
    [self search:searchField];
    [versesTableView noteNumberOfRowsChanged];
    return YES;
}

#pragma mark -

// Notification Handlers
- (void)substituteZVXChanged:(NSNotification *)notification
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKZVXSubstitution"]) {
        NSMutableDictionary * characterSwapDictionary = [NSMutableDictionary dictionary];
        [characterSwapDictionary setObject:[NSNumber numberWithInt:0xe0] forKey:@"z"];
        [characterSwapDictionary setObject:[NSNumber numberWithInt:0xf9] forKey:@"v"];
        [characterSwapDictionary setObject:[NSNumber numberWithInt:0xe8] forKey:@"x"];
        [romanTextView setCharacterSwaps:characterSwapDictionary];
        [romanPublishedTextView setCharacterSwaps:characterSwapDictionary];
    } else {
        [romanTextView setCharacterSwaps:nil];
        [romanPublishedTextView setCharacterSwaps:nil];

    }
}

- (void)definitionsChanged:(id)dummy
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"])
		[self regenerateAllScript];
}

- (void)fontsChanged:(id)dummy
{
    [self updateUI];
}

- (NSString *)windowNibName
{
    return @"RTKTiger";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    [aController setShouldCloseDocument:YES];
    [self setFieldEditor:NO];
    [self updateUI];
    [self substituteZVXChanged:nil];
}

- (void)setFieldEditor:(BOOL)editor
{
    [romanTextView setFieldEditor:editor];
    [scriptTextView setFieldEditor:editor];
    [backTranslationTextView setFieldEditor:editor];
    [notesTextView setFieldEditor:editor];
    [checkingTextView setFieldEditor:editor];
}

#pragma mark -
#pragma mark save and open

- (NSData *)dataOfType:(NSString *)typeName
                 error:(NSError **)outError
{
    NSData * data = nil;
	
    [self writeSplitViewRectsToDefaults];
	
    if([typeName isEqualToString:@"rtktiger"])
	 {
         NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:dictionary];
         
         [dict setObject:[book dictionaryRepresentation] forKey:@"book"];
         
         [dict setObject:@"Keys prefixed with RTK are specific to the document in CleverRabbit.app. \n Those not prefixed store actual data."
                  forKey:@"ANoteForPosterity"];
         
         [dict setObject:[[NSDate date] description] forKey:@"RTKSaveDate"];
         [dict setObject:[creationDate description] forKey:@"RTKCreationDate"];
         
         // TODO: Should probably be using a better version format.
         [dict setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
                  forKey:@"RTKBuildVersion"];
         
         [dict setObject:[NSNumber numberWithInt:RTKDocumentWidth] forKey:@"RTKDocumentWidth"];
         [dict setObject:[NSNumber numberWithInt:RTKDocumentHeight] forKey:@"RTKDocumentHeight"];
         
         [dict setObject:[NSNumber numberWithInt:RTKReferenceColumnWidth] forKey:@"RTKReferenceColumnWidth"];
         [dict setObject:[NSNumber numberWithInt:RTKRevisionColumnWidth] forKey:@"RTKRevisionColumnWidth"];
         [dict setObject:[NSNumber numberWithInt:RTKScriptColumnWidth] forKey:@"RTKScriptColumnWidth"];
         [dict setObject:[NSNumber numberWithInt:RTKRomanColumnWidth] forKey:@"RTKRomanColumnWidth"];
         [dict setObject:[NSNumber numberWithInt:RTKBackTranslationColumnWidth] forKey:@"RTKBackTranslationColumnWidth"];
         [dict setObject:[NSNumber numberWithInt:RTKNotesColumnWidth] forKey:@"RTKNotesColumnWidth"];
         [dict setObject:[NSNumber numberWithInt:RTKCheckingColumnWidth] forKey:@"RTKCheckingColumnWidth"];
         
         NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
         
         [d setObject:[NSNumber numberWithInt:RTKDocumentWidth] forKey:@"RTKDocumentWidth"];
         [d setObject:[NSNumber numberWithInt:RTKDocumentHeight] forKey:@"RTKDocumentHeight"];
         
         [d setObject:[NSNumber numberWithInt:RTKReferenceColumnWidth] forKey:@"RTKReferenceColumnWidth"];
         [d setObject:[NSNumber numberWithInt:RTKRevisionColumnWidth] forKey:@"RTKRevisionColumnWidth"];
         [d setObject:[NSNumber numberWithInt:RTKScriptColumnWidth] forKey:@"RTKScriptColumnWidth"];
         [d setObject:[NSNumber numberWithInt:RTKRomanColumnWidth] forKey:@"RTKRomanColumnWidth"];
         [d setObject:[NSNumber numberWithInt:RTKBackTranslationColumnWidth] forKey:@"RTKBackTranslationColumnWidth"];
         [d setObject:[NSNumber numberWithInt:RTKNotesColumnWidth] forKey:@"RTKNotesColumnWidth"];
         [d setObject:[NSNumber numberWithInt:RTKCheckingColumnWidth] forKey:@"RTKCheckingColumnWidth"];
         
         
         
         data = [[dict description] dataUsingEncoding:NSUTF8StringEncoding];
	 } else if([typeName isEqualToString:@"txt"]) {
		 
		 NSString * string = [book string];
		 
		 if(!book)
			 NSLog(@"nil book");
		 if(!string)
			 NSLog(@"nil string");
		 
		 data = [string utf8Data];
		 
		 if(!data)
			 NSLog(@"nil data from outputData");
	 } else if([typeName isEqualToString:@"ptx"]) {
		 
		 NSString * string = [book sfmString];
		 
		 if(!book)
			 NSLog(@"nil sfm book");
		 if(!string)
			 NSLog(@"nil sfm string");
		 
		 data = [string utf8Data];
		 
		 if(!data)
			 NSLog(@"nil data from [string utf8Data]");
	 }
    
    if(data) {
        // TODO: Change this when undo/redo is supported
        [self updateChangeCount:NSChangeCleared];
    }
    return data;
}

- (NSRect) frame {
	NSRect frame;
	frame.size.width = frame.size.height = frame.origin.x = frame.origin.y = 0;
	
	NSLog(@"Don't call -frame on RTKTigerDocument!");
	return frame;
}

// Used below in setting default or document specific values for bindings.
// Sets the binding value from dict if possible. 
// If not defined in dict, sets from standardUserDefaults.
- (void)setValueForKey:(id)key
        fromDictionary:(id)dict
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    
    id object = [dict objectForKey:key];
    
    if(object)
        // Read the setting from the document if possible.
        [self setValue:object forKey:key];
    else
        // If setting not present in the document, set it from the application defaults.
        [self setValue:[d valueForKey:key] forKey:key];
}

- (void)setBindingsFromDictionary:(NSDictionary *)dict
{
    [self setValueForKey:@"RTKDocumentWidth" fromDictionary:dict];
    [self setValueForKey:@"RTKDocumentHeight" fromDictionary:dict];

    [self setValueForKey:@"RTKReferenceColumnWidth" fromDictionary:dict];
    [self setValueForKey:@"RTKRevisionColumnWidth" fromDictionary:dict];
    [self setValueForKey:@"RTKScriptColumnWidth" fromDictionary:dict];
    [self setValueForKey:@"RTKRomanColumnWidth" fromDictionary:dict];
    [self setValueForKey:@"RTKBackTranslationColumnWidth" fromDictionary:dict];
    [self setValueForKey:@"RTKNotesColumnWidth" fromDictionary:dict];
    [self setValueForKey:@"RTKCheckingColumnWidth" fromDictionary:dict];
}


/*
 loadDataRepresentation:ofType: is called when a file is opened, but not when a new document is created. 
 Given data and a type string, it creates the necessary model objects to represent the document. 
 If called at all, it is called before awakeFromNib.
 */
- (BOOL)loadDataRepresentation:(NSData *)data 
                        ofType:(NSString *)aType
{
    BOOL loaded = NO;
    
    if([aType isEqualToString:@"rtktiger"]) {
        NSDictionary * dict = [[[NSString allocWithZone:[self zone]] initWithData:data 
                                                                         encoding:NSUTF8StringEncoding] propertyList];
        [self setDictionary:dict];
        
        NSDictionary * bookDict = [dict objectForKey:@"book"];
        
        [self setBook:[[[RTKBook alloc] initWithDictionary:bookDict] autorelease]];
        [self setCreationDate:[NSDate dateWithString:[dict objectForKey:@"RTKCreationDate"]]];
        
		// Check for old version of Type field text and update if necessary to USFM format.
		NSString *fileBuildVersion = [dict objectForKey:@"RTKBuildVersion"];
		NSString *minimumRequiredBuildVersion = @"0.2006.02.23";
		if([fileBuildVersion compare:minimumRequiredBuildVersion] == NSOrderedAscending) {
			NSLog(@"UPDATING: Old build version %@ less than minimum %@",
				  fileBuildVersion, minimumRequiredBuildVersion);
			[[[book verses] do] updateTypeFieldToUSFM];
		}
		
		// TODO: check that width and height are within screen size
        [self setBindingsFromDictionary:dict];
        
        loaded = YES;
    } else if([aType isEqualToString:@"txt"]) {
        [self setBook:[[[RTKBook alloc] initWithString:
                        [[NSMutableString allocWithZone:[self zone]] initWithData:data 
                                                                         encoding:NSUTF8StringEncoding]] autorelease]];
        loaded = YES;
    } else if([aType isEqualToString:@"ptx"]) {
        [self setBook:[[[RTKBook alloc] initWithSFMString:
                        [[NSMutableString allocWithZone:[self zone]] initWithData:data 
                                                                         encoding:NSUTF8StringEncoding]] autorelease]];
        loaded = YES;
    }
    
    // TODO: check if not needed
    [versesTableView reloadData];
    if([versesTableView numberOfRows] > 0)
        [versesTableView selectRow:0 byExtendingSelection:NO];
	
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"])
		[self regenerateAllScript];
    
    return loaded;
}

#pragma mark -
#pragma mark accessors

- (void)setDictionary:(NSDictionary *)theDictionary
{
    [theDictionary retain];
    [dictionary release];
    dictionary = theDictionary;
}

- (NSDictionary *)dictionary
{
    return dictionary;
}

- (RTKBook *)book
{
    return book;
}

- (void)setBook:(RTKBook *)theBook
{
    [theBook retain];
    [book release];
    book = theBook;
}

- (RTKVerse *)currentVerse
{
    return currentVerse;
}

- (void)setCurrentVerse:(RTKVerse *)verse
{
    [verse retain];
    [currentVerse release];
    currentVerse = verse;
}

- (RTKRevision *)currentRevision
{
    return currentRevision;
}

- (void)setCurrentRevision:(RTKRevision *)revision
{
    [revision retain];
    [currentRevision release];
    currentRevision = revision;
}

- (NSMutableArray *)verseTypes
{
    return verseTypes;
}

- (void)setVerseTypes:(NSMutableArray *)theVerseTypes
{
    [theVerseTypes retain];
    [verseTypes release];
    verseTypes = theVerseTypes;
}

- (NSDate *)creationDate
{
    return creationDate;
}

- (void)setCreationDate:(NSDate *)newCreationDate
{
    // Don't want to lose the current creation date if none passed in.
    if(! newCreationDate) 
        return;
    
    [newCreationDate retain];
    [creationDate release];
    creationDate = newCreationDate;
}

#pragma mark - UI

- (void)updateRomanPublishedTextView
{
    // update roman view
    [[romanPublishedTextView textStorage] setAttributedString:[book mutableAttributedString:YES]];  // YES = roman, NO = script
    
    // update script view
    [[scriptPublishedTextView textStorage] setAttributedString:[book mutableAttributedString:NO]];  // YES = roman, NO = script
}

- (void)updateUI
{
    [self updateFonts];
    [self updateMenusAndButtons];
}

- (void)updateFonts
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    NSFont * font;
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKScriptFontName"]
                           size:[(NSString *) [d valueForKey:@"RTKScriptFontSize"] floatValue]];
    if(font) [scriptTextView setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKRomanFontName"]
                           size:[(NSString *) [d valueForKey:@"RTKRomanFontSize"] floatValue]];
    if(font) [romanTextView setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKBackTranslationFontName"]
                           size:[(NSString *) [d valueForKey:@"RTKBackTranslationFontSize"] floatValue]];
    if(font) [backTranslationTextView setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKNotesFontName"]
                           size:[(NSString *) [d valueForKey:@"RTKNotesFontSize"] floatValue]];
    if(font) [notesTextView setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKCheckingFontName"]
                           size:[(NSString *) [d valueForKey:@"RTKCheckingFontSize"] floatValue]];
    if(font) [checkingTextView setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKScriptFontName"]
                           size:12];
    if(font) [[scriptTableColumn dataCell] setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKRomanFontName"]
                           size:12];
    if(font) [[romanTableColumn dataCell] setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKBackTranslationFontName"]
                           size:12];
    if(font) [[backTranslationTableColumn dataCell] setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKNotesFontName"]
                           size:12];
    if(font) [[notesTableColumn dataCell] setFont:font];
    
    font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKCheckingFontName"]
                           size:12];
    if(font) [[checkingTableColumn dataCell] setFont:font];
}

- (void) updateMenusAndButtons
{
    NSUInteger selectedRow;
    NSIndexSet * selectedRows = [versesTableView selectedRowIndexes];
    RTKCleverRabbitController * appController = [NSApp delegate];
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    
    if([selectedRows count] > 1) {
        selectedRow = -1;
    } else {
        selectedRow = [selectedRows firstIndex];
    }
    
    if(selectedRow == NSNotFound) {
        [[appController newVerseMenuItem] setEnabled:YES];
        [[appController deleteVerseMenuItem] setEnabled:NO];
        [deleteVerseButton setEnabled:NO];
    } else {
        [[appController newVerseMenuItem] setEnabled:YES];
        [[appController deleteVerseMenuItem] setEnabled:YES];
        [deleteVerseButton setEnabled:YES];
    }
    
    if(selectedRow == -1 || selectedRow == NSNotFound) {

        
        [romanTextView setEditable:NO];
        [backTranslationTextView setEditable:NO];
        [notesTextView setEditable:NO];
        [checkingTextView setEditable:NO];
		
        [deleteRevisionButton setEnabled:NO];
        [newRevisionButton setEnabled:NO];
        
        [[appController nextVerseMenuItem] setEnabled:NO];
        [[appController previousVerseMenuItem] setEnabled:NO];
        
        [[appController newRevisionMenuItem] setEnabled:NO];
        [[appController deleteRevisionMenuItem] setEnabled:NO];
        [[appController nextRevisionMenuItem] setEnabled:NO];
        [[appController previousRevisionMenuItem] setEnabled:NO];
        
        [[appController lockRevisionMenuItem] setEnabled:NO];
        
    } else {
        
        BOOL verseLocked = [currentVerse locked];
        BOOL revisionLocked = [[currentVerse currentRevision] locked];
        int revisionIndex = [currentVerse currentRevisionIndex];
        
        [[appController newVerseMenuItem] setEnabled:YES];
        [[appController deleteVerseMenuItem] setEnabled:!verseLocked];
        [[appController lockVerseMenuItem] setState:(verseLocked ? NSOnState : NSOffState)];
        
        [deleteVerseButton setEnabled:(!verseLocked ? NSOnState : NSOffState)];
        
        [referenceTableColumn setEditable:!(verseLocked || revisionLocked)];
        [typeTableColumn setEditable:!(verseLocked || revisionLocked)];
        [revisionTableColumn setEditable:!(verseLocked || revisionLocked)];
        
        [[appController lockRevisionMenuItem] setEnabled:!verseLocked];
        [[appController lockRevisionMenuItem] setState:(revisionLocked ? NSOnState : NSOffState)];
        [[appController deleteRevisionMenuItem] setEnabled:!(verseLocked || revisionLocked)];
        [[appController newRevisionMenuItem] setEnabled:!verseLocked];
        
        [newRevisionButton setEnabled:!verseLocked];
        [deleteRevisionButton setEnabled:!(verseLocked || revisionLocked)];
        
        [[appController nextRevisionMenuItem] setEnabled:
         ((revisionIndex < [currentVerse revisionCount] - 1) && !verseLocked)];
        [[appController previousRevisionMenuItem] setEnabled:
         ((revisionIndex > 0) && !verseLocked)];
        
        [[appController nextVerseMenuItem] setEnabled:(selectedRow < [[book verses] count] - 1)];
        [[appController previousVerseMenuItem] setEnabled:(selectedRow > 0)];
        
        [romanTextView setEditable:!(verseLocked || revisionLocked)];
        [backTranslationTextView setEditable:!(verseLocked || revisionLocked)];
        [notesTextView setEditable:!(verseLocked || revisionLocked)];
        [checkingTextView setEditable:!(verseLocked || revisionLocked)];
        
        [referenceTableColumn setEditable:!verseLocked];
        [typeTableColumn setEditable:!verseLocked];
        [revisionTableColumn setEditable:!verseLocked];
	}
}


- (void)readSplitViewRectsFromDefaults
{
	NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
	
	if([d boolForKey:@"RTKHorizonatalSplitViewRectSaved"]) {
		[rowView setFrame:NSRectFromString([d objectForKey:@"RTKRowViewRect"])];
		[editView setFrame:NSRectFromString([d objectForKey:@"RTKEditViewRect"])];
	}
	
	if([d boolForKey:@"RTKTransliterationOn"]) {
		if([d boolForKey:@"RTKSplitViewRectsWithTransliterationSaved"]) {
			[scriptView setFrame:NSRectFromString([d objectForKey:@"RTKScriptViewRectWithTransliteration"])];
			[romanView setFrame:NSRectFromString([d objectForKey:@"RTKRomanViewRectWithTransliteration"])];
			[backTranslationView setFrame:NSRectFromString([d objectForKey:@"RTKBackTranslationViewRectWithTransliteration"])];
			[notesView setFrame:NSRectFromString([d objectForKey:@"RTKNotesViewRectWithTransliteration"])];
			[checkingView setFrame:NSRectFromString([d objectForKey:@"RTKCheckingViewRectWithTransliteration"])];
		}
	} else {
		if([d boolForKey:@"RTKSplitViewRectsWithoutTransliterationSaved"]) {
			[romanView setFrame:NSRectFromString([d objectForKey:@"RTKRomanViewRect"])];
			[backTranslationView setFrame:NSRectFromString([d objectForKey:@"RTKBackTranslationViewRect"])];
			[notesView setFrame:NSRectFromString([d objectForKey:@"RTKNotesViewRect"])];
			[checkingView setFrame:NSRectFromString([d objectForKey:@"RTKCheckingViewRect"])];
		}
	}
}

- (void)writeSplitViewRectsToDefaults
{
	NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
	[d setObject:[NSNumber numberWithBool:YES] forKey:@"RTKHorizonatalSplitViewRectSaved"];
	[d setObject:NSStringFromRect([rowView frame]) forKey:@"RTKRowViewRect"];
	[d setObject:NSStringFromRect([editView frame]) forKey:@"RTKEditViewRect"];
	
	if([d boolForKey:@"RTKTransliterationOn"]) {
		[d setObject:[NSNumber numberWithBool:YES] forKey:@"RTKSplitViewRectsWithTransliterationSaved"];
		[d setObject:NSStringFromRect([scriptView frame]) forKey:@"RTKScriptViewRectWithTransliteration"];
		[d setObject:NSStringFromRect([romanView frame]) forKey:@"RTKRomanViewRectWithTransliteration"];
		[d setObject:NSStringFromRect([backTranslationView frame]) forKey:@"RTKBackTranslationViewRectWithTransliteration"];
		[d setObject:NSStringFromRect([notesView frame]) forKey:@"RTKNotesViewRectWithTransliteration"];
		[d setObject:NSStringFromRect([checkingView frame]) forKey:@"RTKCheckingViewRectWithTransliteration"];	
	} else {
		[d setObject:[NSNumber numberWithBool:YES] forKey:@"RTKSplitViewRectsWithoutTransliterationSaved"];
		[d setObject:NSStringFromRect([romanView frame]) forKey:@"RTKRomanViewRect"];
		[d setObject:NSStringFromRect([backTranslationView frame]) forKey:@"RTKBackTranslationViewRect"];
		[d setObject:NSStringFromRect([notesView frame]) forKey:@"RTKNotesViewRect"];
		[d setObject:NSStringFromRect([checkingView frame]) forKey:@"RTKCheckingViewRect"];	
	}
}

- (void)presetVerse:(RTKVerse *)verse
 fromPrecedingVerse:(RTKVerse *)precedingVerse
{
    NSString * precedingReference = [precedingVerse reference];
    NSString * precedingType = [precedingVerse type];
    NSString * verseNumber = [precedingReference verse];
    NSString * reference =  [NSString stringWithFormat:@"%@ %@", 
                             [precedingReference book],
                             [precedingReference chapter]];
    
    if([verseNumber length] > 0) {
        verseNumber = [NSString stringWithFormat:@"%i", 
                       [verseNumber intValue] + ([precedingType isEqualToString:@"\\v"] ? 1 : 0)];
        reference = [NSString stringWithFormat:@"%@:%@", reference, verseNumber];
    }
    [verse setReference:reference];
}

// Ensure that there is always at least one blank row at end of document.
- (void)ensureOneBlankVerse
{
    NSMutableArray * verses = [book verses];
    if(![verses count]) {
        [verses addObject:[[[RTKVerse alloc] init] autorelease]];
        [versesTableView noteNumberOfRowsChanged];
        [versesTableView reloadData];
    } else if(![(RTKVerse *) [verses objectAtIndex:[verses count] -1] blank]) {
        RTKVerse * verse = [[[RTKVerse alloc] init] autorelease];
        [verses addObject:verse];
        
        // Prefill the reference field with a verse reference derived
        // from the preceding verse's reference.
        RTKVerse * precedingVerse = (RTKVerse *) [verses objectAtIndex:[verses count] - 2];
        
        [self presetVerse:verse fromPrecedingVerse:precedingVerse];
        
        [versesTableView noteNumberOfRowsChanged];
        [versesTableView reloadData];
        [self search:searchField];
    }
}

#pragma mark -
#pragma mark menu and button handlers

- (IBAction)newVerse:(id)sender
{
    NSMutableArray * verses = [book verses];
    int i = [versesTableView selectedRow];
    int newIndex = 0;
    RTKVerse * verse = [[[RTKVerse alloc] init] autorelease];
    
    if(i == RTKNOROWSELECTED) {
        [verses addObject:verse];
        newIndex = [verses count] - 1;
    } else {
        [verses insertObject:verse
                     atIndex:i + 1];
        newIndex = i + 1;
    }
    
    if(newIndex > 0)
        [self presetVerse:verse fromPrecedingVerse:(RTKVerse *) [verses objectAtIndex:newIndex - 1]];
	
    [searchField setStringValue:@""];
    [self search:searchField];
    
    [versesTableView noteNumberOfRowsChanged];
    [versesTableView selectRowIndexes:[[[NSIndexSet alloc] initWithIndex:newIndex] autorelease]
                 byExtendingSelection:NO];
    
    [self ensureOneBlankVerse];
    [self updateUI];
    
    // TODO: Change this when undo/redo is supported
    [self updateChangeCount:NSChangeDone];
}

- (IBAction)deleteVerse:(id)sender
{
    //NSMutableArray * verses = [book verses];
    int currentVerseIndex = [[book verses] indexOfObject:currentVerse];
    
    NSEnumerator * e = [versesTableView selectedRowEnumerator];
    NSMutableArray * selectedVerseArray = [NSMutableArray new];
    NSNumber * rowIndexNumber;
    int rowIndex = 0;
    
    while(rowIndexNumber = [e nextObject]) {
        rowIndex = [rowIndexNumber intValue];
        int verseIndex = [[visibleVerseIndexes objectAtIndex:rowIndex] intValue];
        [selectedVerseArray addObject:[NSNumber numberWithInt:verseIndex]];
    }
    
    [book setVerses:(NSMutableArray *) [[book verses] arrayByRemovingObjectsAtIndexes:selectedVerseArray]];
    
    [searchField setStringValue:@""];
    [self search:searchField];
    
    [versesTableView noteNumberOfRowsChanged];
    [self ensureOneBlankVerse];
    
    [self selectVerse:[[book verses] objectAtIndex:MIN(currentVerseIndex, [[book verses] count] -1)]];    
    
    // TODO: Change this when undo/redo is supported
    [self updateChangeCount:NSChangeDone];
}

- (void)nextVerse:(id)sender
{
    NSMutableArray * verses = [book verses];
    int currentVerseIndex = [verses indexOfObject:currentVerse];
    if(currentVerseIndex < [verses count] -1)
        [self selectVerse:[verses objectAtIndex:currentVerseIndex + 1]];
}

- (void)previousVerse:(id)sender
{
    NSMutableArray * verses = [book verses];
    int currentVerseIndex = [verses indexOfObject:currentVerse];
    if(currentVerseIndex > 0)
        [self selectVerse:[verses objectAtIndex:currentVerseIndex - 1]];
}


// Updates the UI to reflect the newly selected revision.
// Returns YES on success, NO on failure.
- (BOOL)selectRevision:(RTKRevision *)revision
{
    if(revision == currentRevision) return YES;
    
    currentRevision = revision;
    
    [romanTextView setString:[revision roman]];
    [scriptTextView setString:[revision script]];
    [backTranslationTextView setString:[revision backTranslation]];
    [notesTextView setString:[revision notes]];
    [checkingTextView setString:[revision checking]];

    return YES;
}


- (int)indexOfVerse:(RTKVerse *)verse inTextView:(NSTextView *)textView
{
    NSEnumerator * e = [[book verses] objectEnumerator];
    RTKVerse * v;
    int i = 0;
    while(v = [e nextObject]){
        
        
        i += [[v mutableAttributedString:(textView == romanPublishedTextView)] length];
        
        if(v == verse)
            return i-1;
        
        /*
        if(v == verse)
            return i;
        
        i += [[v mutableAttributedString:(textView == romanPublishedTextView)] length];
        */
        
    }
    return 0;
}


- (void)updateVerse:(RTKVerse *)verse
       withOldIndex:(int)index
inPublishedTextView:(NSTextView *)textView
{
    NSTextStorage *textStorage = [textView textStorage];
    
    NSRange range;
    
    if([textStorage length] < index) {
        [textStorage insertAttributedString:[verse mutableAttributedString:(textView == romanPublishedTextView)] atIndex:[textStorage length]];
        
    } else {
    
        [textStorage attribute:@"RTKVerse"
                  atIndex:index 
    longestEffectiveRange:&range
                       inRange:NSMakeRange(0, [textStorage length])];
        
        [textStorage replaceCharactersInRange:range withAttributedString:[verse mutableAttributedString:(textView == romanPublishedTextView)]];
    }
}




- (void)highlightVerse:(RTKVerse *)verse inTextView:(NSTextView *)textView
{
    int verseIndex = [self indexOfVerse:verse inTextView:textView];
    NSTextStorage *textStorage = [textView textStorage];
    
    
    
    if(verseIndex >= [textStorage length])
        return;
    
    NSRange firstComponentRange;
    NSString *firstComponent = [textStorage attribute:@"RTKVerse" 
                                              atIndex:verseIndex
                                longestEffectiveRange:&firstComponentRange
                                              inRange:NSMakeRange(0, [textStorage length])];
    if(firstComponentRange.length == 0)
        return;
    
    [textStorage removeAttribute:NSBackgroundColorAttributeName];
    [textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:firstComponentRange];
}


- (void)scrollVerseToVisible:(RTKVerse *)verse inTextView:(NSTextView *)textView
{
    int verseIndex = [self indexOfVerse:verse inTextView:textView];
    NSTextStorage *textStorage = [textView textStorage];
    
    if(verseIndex >= [textStorage length]) {
        NSLog(@"verseIndex >= [textStorage length] in scrollVerseToVisible");
        return;
    }
    
    NSRange firstComponentRange;
    NSString *firstComponent = [textStorage attribute:@"RTKVerse"
                                              atIndex:verseIndex
                                longestEffectiveRange:&firstComponentRange
                                              inRange:NSMakeRange(0, [textStorage length])];
    [textView scrollRangeToVisible:firstComponentRange];
}


// Updates the UI to reflect the newly selected verse.
// Returns YES on success, NO on failure.
- (BOOL)selectVerse:(RTKVerse *)verse
{
    // Same verse, so nothing to do.
    if(verse == currentVerse) return YES;

    // Index of verse, not of row in table, which can be different if using a filtering search.
    NSUInteger verseIndex = [[book verses] indexOfObject:verse];
    
    // Can't find the verse, so nothing to do.
    if (verseIndex == NSNotFound) return NO;
    
    // Save for next time.
    currentVerse = verse;
    
    // Select verse in table.
    [versesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:verseIndex] byExtendingSelection:NO]; // 10.3 and later.
    [versesTableView scrollRowToVisible:verseIndex];
    
    // Load revision into single-verse text fields.
    [self selectRevision:[verse currentRevision]];
    
    // There is an interaction between scrollVerseToVisible and addAttribute that causes unpredictable scrolling of the published NSTextViews when using arrow keys to navigate up and down the verse NSTableView.
    // Separating them by a time delay helps.
    
    
    if([documentWindow firstResponder] != romanPublishedTextView)
        [[self performAfterDelay:0.3] scrollVerseToVisible:verse inTextView:romanPublishedTextView];
    
    if([documentWindow firstResponder] != scriptPublishedTextView)
        [[self performAfterDelay:0.3] scrollVerseToVisible:verse inTextView:scriptPublishedTextView];
     
    // Highlight verse in published views and scroll to visible.
    [self highlightVerse:verse inTextView:romanPublishedTextView];
    [self highlightVerse:verse inTextView:scriptPublishedTextView];
    
    // Update Menus, Buttons, and Fonts
    [self updateUI];
    
    // Successfully selected a different verse.
    return YES;
}


- (IBAction)lockVerse:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    if(selectedRow >= 0) {
        RTKVerse * verse = [[book verses] objectAtIndex:selectedRow];
        
        [verse setLocked:![verse locked]];
        
        // TODO:Change this when undo/redo is supported
        [self updateChangeCount:NSChangeDone];
    }
    [versesTableView reloadData];
    [self updateUI];
}

#pragma mark -

- (IBAction)newRevision:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    if(selectedRow >= 0) {
        RTKVerse * verse = [[book verses] objectAtIndex:selectedRow];
        NSMutableArray * revisions = [verse revisions];
        RTKRevision * newRevision = [[revisions objectAtIndex:[verse currentRevisionIndex]] copy];
        
        [newRevision setLocked:NO];
        [revisions addObject:newRevision];
        [verse setCurrentRevisionIndex:[revisions count] -1];
        
        [versesTableView reloadData];
        [self updateUI];
        
        // TODO: Change this when undo/redo is supported
        [self updateChangeCount:NSChangeDone];
    }
}

- (IBAction)deleteRevision:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    if(selectedRow >= 0) {
        RTKVerse * verse = [[book verses] objectAtIndex:selectedRow];
        NSMutableArray * revisions = [verse revisions];
        int currentRevisionIndex = [verse currentRevisionIndex];
        RTKRevision * revision = [[verse revisions] objectAtIndex:currentRevisionIndex];
        
        if([revisions count] > 1 && ![revision locked]) {
            [revisions removeObjectAtIndex:currentRevisionIndex];
            
            if(currentRevisionIndex == [revisions count])
                [verse setCurrentRevisionIndex:currentRevisionIndex -1];
        } else {
            NSLog(@"%@ trying to delete locked revision", sender);
        }
        
        [versesTableView reloadData];
        [self updateUI];
        
        // TODO: Change this when undo/redo is supported
        [self updateChangeCount:NSChangeDone];
    }
}

// TODO: Clean up this revision switching code.
- (void)nextRevision:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    if(selectedRow >= 0) {
        RTKVerse * verse = [[book verses] objectAtIndex:selectedRow];
        int revisionCount = [[verse revisions] count];
        int currentRevisionIndex = [verse currentRevisionIndex];
        
        if(currentRevisionIndex < revisionCount -1) {
            // TODO: check if not needed
            [versesTableView reloadData];
            [verse setCurrentRevisionIndex:currentRevisionIndex + 1];
            [self updateUI];
            
            // TODO: Change this when undo/redo is supported
            [self updateChangeCount:NSChangeDone];
        }
    }
}

- (void)previousRevision:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    if(selectedRow >= 0) {
        RTKVerse * verse = [[book verses] objectAtIndex:selectedRow];
        int revisionCount = [[verse revisions] count];
        int currentRevisionIndex = [verse currentRevisionIndex];
        
        if(currentRevisionIndex > 0) {
            // TODO: check if not needed
            [versesTableView reloadData];
            [verse setCurrentRevisionIndex:currentRevisionIndex - 1];
            [self updateUI];
            
            // TODO: Change this when undo/redo is supported
            [self updateChangeCount:NSChangeDone];
        }
    }
}

-(IBAction)switchRevision:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    if(selectedRow >= 0) {
        RTKVerse * verse = [[book verses] objectAtIndex:selectedRow];
        int revisionCount = [[verse revisions] count];
        int revisionIndex = 0;
		
        if(revisionIndex != [verse currentRevisionIndex]) {
            // TODO: check if not needed
            [versesTableView reloadData];
            [verse setCurrentRevisionIndex:revisionIndex];
            [self updateUI];
            
            // TODO: Change this when undo/redo is supported
            [self updateChangeCount:NSChangeDone];
        }
    }
}

- (IBAction)lockRevision:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    if(selectedRow >= 0) {
        RTKVerse * verse = [[book verses] objectAtIndex:selectedRow];
        RTKRevision * revision = [verse currentRevision];
		
        [revision setLocked:![revision locked]];
        
        // TODO:Change this when undo/redo is supported
        [self updateChangeCount:NSChangeDone];
    }
    [versesTableView reloadData];
    [self updateUI];
}

#pragma mark -
#pragma mark window delegate methods

- (void)windowWillClose:(NSNotification *)aNotification
{
    windowIsOpen = NO;
    [convertingLock unlock];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[self readSplitViewRectsFromDefaults];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[self writeSplitViewRectsToDefaults];
}

#pragma mark -
#pragma mark split view delegate methods

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
	[self writeSplitViewRectsToDefaults];
}

- (void)splitView:(NSSplitView *)sender 
constrainMinCoordinate:(float *)min 
	maxCoordinate:(float *)max 
	  ofSubviewAt:(int)offset
{
	(*min) = 0.0;
	(*max) = INFINITY;
	
	if(sender == horizontalSplitView) {
		(*min) = 100.0;
		(*max) = [[documentWindow contentView] frame].size.height -  150.0;
	}
}

#pragma mark -
#pragma mark text view delegate methods

/*
 textDidChange is a delegate method that is called when the user modifies an NSTextView.
 We update the appropriate RTKVerse or RTKRevision object from the changed text field.
 */
- (void)textDidChange:(NSNotification *)notification
{
    NSLog(@"textDidChange");
    NSTextView * changedTextView = [notification object];
    
    NSMutableArray * verses = [book verses];
    RTKVerse * verse = [verses objectAtIndex:[[visibleVerseIndexes objectAtIndex:[versesTableView selectedRow]] intValue]];
    
    RTKRevision * revision = [verse currentRevision];
    
    if(changedTextView == romanTextView) {
        
        int oldVerseIndexInPublishedTextView = [self indexOfVerse:verse inTextView:romanPublishedTextView];
        
        [revision setRoman:[[changedTextView string] copy]];
        
        [self updateVerse:verse withOldIndex:oldVerseIndexInPublishedTextView inPublishedTextView:romanPublishedTextView];
        [self highlightVerse:verse inTextView:romanPublishedTextView];
        
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"])
			[self convertRevision:revision
				 withHighPriority:YES];

    } else if(changedTextView == scriptTextView) {
        [revision setScript:[[changedTextView string] copy]];
        //[self updateRomanPublishedTextView];
    } else if(changedTextView == backTranslationTextView) {
        [revision setBackTranslation:[[changedTextView string] copy]];
        //[self updateRomanPublishedTextView];
    } else if(changedTextView == notesTextView) {
        [revision setNotes:[[changedTextView string] copy]];
        //[self updateRomanPublishedTextView];
    } else if(changedTextView == checkingTextView) {
        [revision setChecking:[[changedTextView string] copy]];
        //[self updateRomanPublishedTextView];
    } else if(changedTextView == romanPublishedTextView) {
        [self romanPublishedTextViewDidChange:notification];
    } else {
        NSLog(@"unhandled textview %@ sent to textDidChange", changedTextView);
        NSLog(@"romanPublishedTextView: %@", romanPublishedTextView);
    }
    // TODO: Change this when undo/redo is supported
    [self updateChangeCount:NSChangeDone];
    
    NSRect rowRect = [versesTableView rectOfRow:[versesTableView selectedRow]];    
    [versesTableView setNeedsDisplayInRect:rowRect];
	[self updateUI];
    [self ensureOneBlankVerse];
    
    //[self selectVerse:verse];
}

// Informs the appropriate RTKVerse object of its changes.
- (void)romanPublishedTextViewDidChange:(NSNotification *)notification
{
    NSLog(@"romanPublishedTextViewDidChange");
    NSTextStorage *textStorage = [romanPublishedTextView textStorage];
    NSRange selectedRange = [romanPublishedTextView selectedRange];
    
    NSRange verseRange;    
    RTKVerse *verse = [textStorage attribute:@"RTKVerse" 
                                     atIndex:selectedRange.location
                       longestEffectiveRange:&verseRange
                                     inRange:NSMakeRange(0, [textStorage length])];
    NSAttributedString *verseString = [textStorage attributedSubstringFromRange:verseRange];
    
    //BOOL changeAccepted = [verse updateWithAttributedString:verseString atIndex:(selectedRange.location - verseRange.location)];
    
    BOOL changeAccepted = [verse updateWithAttributedString:[textStorage attributedSubstringFromRange:NSMakeRange(0, [textStorage length])] 
                                                    atIndex:selectedRange.location];

    if(!changeAccepted) {
        NSLog(@"RTKVerse rejected change.");
        [self updateRomanPublishedTextView];
        [romanPublishedTextView setSelectedRange:selectedRange];
    } else {
        [romanTextView setString:[[verse currentRevision] roman]];
        
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"])
			[self convertRevision:[currentVerse currentRevision]
				 withHighPriority:YES];
    }
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{   
    NSTextView * changedTextView = [notification object];
    
    if([documentWindow firstResponder] != changedTextView)
        return;
    
    // Updated to == from = AKK 2012
    if(changedTextView == romanPublishedTextView || changedTextView == scriptPublishedTextView) {
        NSLog(@"textViewDidChangeSelection %@", (changedTextView == romanPublishedTextView ? @"roman" : @"script"));
        NSTextStorage *textStorage = [changedTextView textStorage];
        NSRange selectedRange = [changedTextView selectedRange];
                
        // Don't allow editing end of text field.
        if(selectedRange.location == [textStorage length]) {
            [(RTKTigerTextView *) changedTextView setAllowEditing:NO];
            return;
        }
        
        // Temporary logging for testing.
        NSLog(@"%@", [[textStorage attributesAtIndex:selectedRange.location effectiveRange:NULL] description]);
        
        RTKVerse *firstVerse = [textStorage attribute:@"RTKVerse"
                                              atIndex:selectedRange.location
                                longestEffectiveRange:NULL
                                              inRange:NSMakeRange(0, [textStorage length])];
        
        RTKVerse *lastVerse = [textStorage attribute:@"RTKVerse" 
                                             atIndex:(selectedRange.location + selectedRange.length)
                               longestEffectiveRange:NULL
                                             inRange:NSMakeRange(0, [textStorage length])];
        
        NSRange firstComponentRange;
        NSString *firstComponent = [textStorage attribute:@"RTKVerseComponent" 
                                                  atIndex:selectedRange.location
                                    longestEffectiveRange:&firstComponentRange
                                                  inRange:NSMakeRange(0, [textStorage length])];
        
        NSString *lastComponent = [textStorage attribute:@"RTKVerseComponent" 
                                                 atIndex:(selectedRange.location + selectedRange.length)
                                   longestEffectiveRange:NULL
                                                 inRange:NSMakeRange(0, [textStorage length])];
        
        NSString *nextToLastComponent = nil;
        NSRange nextToLastComponentRange;
        if( (selectedRange.location + selectedRange.length - 1) > 0 && !((selectedRange.location == 0) && (selectedRange.length == 0)) ) {
            nextToLastComponent = [textStorage attribute:@"RTKVerseComponent" 
                                                 atIndex:selectedRange.location + selectedRange.length - 1
                                   longestEffectiveRange:&nextToLastComponentRange
                                                 inRange:NSMakeRange(0, [textStorage length])];
        }
        
        // Don't allow editing if selection spans multiple verses or components.
        if((firstVerse != lastVerse) || ((firstComponent != lastComponent) && (firstComponent != nextToLastComponent)) ) {
            [(RTKTigerTextView *) changedTextView setAllowEditing:NO];
            return;
        }
        
        if(firstVerse != currentVerse)
            [self selectVerse:firstVerse];
         
        // Allow editing if selection is within the text of a verse.
        if([firstComponent isEqualToString:@"Verse Text"]) {
            [(RTKTigerTextView *) changedTextView setAllowedEditingRange:firstComponentRange];
            //[textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:firstComponentRange];
            NSRange dummyRange;
            [changedTextView setTypingAttributes:[textStorage attributesAtIndex:firstComponentRange.location effectiveRange:&dummyRange]];
        } else {
            if((selectedRange.location + selectedRange.length - 1) > 0) {
                // Allow editing if at the end of a "Verse Text" section.
                if([nextToLastComponent isEqualToString:@"Verse Text"]) {
                    [changedTextView setTypingAttributes:[textStorage attributesAtIndex:selectedRange.location + selectedRange.length - 1
                                                                           effectiveRange:NULL]];
                    //[textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:nextToLastComponentRange];
                    [(RTKTigerTextView *) changedTextView setAllowedEditingRange:nextToLastComponentRange];
                } else {
                    [(RTKTigerTextView *) changedTextView setAllowEditing:NO];
                }
            }
        }
    }
    [scriptPublishedTextView setAllowEditing:NO];
}

/*
- (void)reloadTableData:(id)dummy
{
    NSLog(@"- (void)reloadTableData:(id)dummy");
    [versesTableView reloadData];
}
*/

#pragma mark -
#pragma mark table delegate methods

- (void)tableView:(NSTableView *)tableView 
didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSLog(@"click in column header %@, row %li", tableColumn, (long)[versesTableView selectedRow]);
}

- (BOOL)tableView:(NSTableView *)aTableView 
shouldEditTableColumn:(NSTableColumn *)aTableColumn 
              row:(int)rowIndex
{
    if(aTableColumn == romanTableColumn) {
        [documentWindow makeFirstResponder:romanTextView];
    } else if(aTableColumn == scriptTableColumn) {
        [documentWindow makeFirstResponder:romanTextView];
    } else if(aTableColumn == backTranslationTableColumn) {
        [documentWindow makeFirstResponder:backTranslationTextView];
    } else if(aTableColumn == notesTableColumn) {
        [documentWindow makeFirstResponder:notesTextView];
    } else if(aTableColumn == checkingTableColumn) {
        [documentWindow makeFirstResponder:checkingTextView];
    } else if(aTableColumn == referenceTableColumn) {
        return YES;
    } else if(aTableColumn == typeTableColumn) {
        return YES;
    }
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    //[self updateUI];
    
    // Attempting to learn why arrow key row selection in the tableview causes unpredictable scrolling in the published view textfields.
    // NSLog(@"%lu",[[NSApp currentEvent] type]);
    
    NSMutableArray * verses = [book verses];
    int selectedRowIndex = [(NSTableView *) [aNotification object] selectedRow];
    if (selectedRowIndex < [verses count]) {
        [self selectVerse:[verses objectAtIndex:selectedRowIndex]];
    }
}

/*
- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    //[self ensureOneBlankVerse];
    //[self updateUI];
}
 */


#pragma mark -
#pragma mark tableSource methods

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    int rowCount = 0;
    if(aTableView == versesTableView) {
        rowCount = [visibleVerseIndexes count];
    } else {
        NSLog(@"object %@ calling numberOfRowsInTableView", aTableView);
    }
    return rowCount;
}

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn 
            row:(int)rowIndex
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    
    NSParameterAssert(rowIndex >= 0 && rowIndex < [visibleVerseIndexes count]);
    rowIndex = [(NSNumber *)[visibleVerseIndexes objectAtIndex:rowIndex] intValue];
	
    NSString * value = @"default value";
    
    NSMutableArray * verses = [book verses];
    
    RTKVerse * verse = [verses objectAtIndex:rowIndex];
    int revisionIndex = [verse currentRevisionIndex];
    NSMutableArray * revisions = [verse revisions];
    RTKRevision * revision = [revisions objectAtIndex:revisionIndex];
    
    if(aTableView == versesTableView) {
        if(aTableColumn == referenceTableColumn) {
            value = [verse reference];
        } else if(aTableColumn == typeTableColumn) {
            value = @""; // has popup menu
			[[aTableColumn dataCellForRow:rowIndex] setEnabled:![verse locked]];
        } else if(aTableColumn == revisionTableColumn) {
            value = @""; // has popup menu
			[[aTableColumn dataCellForRow:rowIndex] setEnabled:![verse locked]];
		} else if(aTableColumn == lockedTableColumn) {
            value = @""; // has check box
        } else if(aTableColumn == scriptTableColumn) {
            value = [revision script];
		} else if(aTableColumn == romanTableColumn) {
            value = [revision roman];
        } else if(aTableColumn == backTranslationTableColumn) {
            value = [revision backTranslation];
        } else if(aTableColumn == notesTableColumn) {
            value = [revision notes];
        } else if(aTableColumn == checkingTableColumn) {
            value = [revision checking];
        } else {
            NSLog(@"unhandled column %@ for tableView:objectValueForTableColumn:row:", aTableColumn);
        }
    } else {
        NSLog(@"unhandled object %@ calling tableView:objectValueForTableColumn:row:", aTableView);
    }
    return value;
}

// Called by dataCellForRowColumn: in RTKTigerTableColumn
- (id)dataCellForRow:(int)row
			  column:(NSTableColumn *)column
{
	// TODO: fix possible leak
	NSPopUpButtonCell *cell = [NSPopUpButtonCell new];
	[cell setEnabled:[[[book verses] objectAtIndex:row] locked]];
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex
{
    //NSParameterAssert(rowIndex >= 0 && rowIndex < [visibleVerseIndexes count]);
    // Don't set values for deleted rows.  This is needed when a row is deleted during editing of one of its NSCells.l
    if(!(rowIndex >= 0 && rowIndex < [visibleVerseIndexes count]))
        return;
    
    rowIndex = [(NSNumber *)[visibleVerseIndexes objectAtIndex:rowIndex] intValue];
    
    NSMutableArray * verses = [book verses];
    RTKVerse * verse = [verses objectAtIndex:rowIndex];
    int revisionIndex = [verse currentRevisionIndex];
    NSMutableArray * revisions = [verse revisions];
    RTKRevision * revision = [revisions objectAtIndex:revisionIndex];
    
    if(aTableView == versesTableView) {
        if(aTableColumn == referenceTableColumn) {
            [verse setReference:anObject];
            [self updateRomanPublishedTextView];
            [self selectVerse:verse];
        } else if(aTableColumn == typeTableColumn) {
            [verse setType:anObject];
            [self updateRomanPublishedTextView];
            [self selectVerse:verse];
        } else if(aTableColumn == revisionTableColumn) {
            [verse setCurrentRevisionIndex:[(NSNumber *)anObject intValue]];
            [self selectRevision:[currentVerse currentRevision]];
            [self updateRomanPublishedTextView];
            [self selectVerse:verse];
        } else if(aTableColumn == lockedTableColumn) {
            [verse setLocked:[(NSNumber *)anObject boolValue]];
        } else if(aTableColumn == scriptTableColumn) {
            [revision setScript:anObject];
        } else if(aTableColumn == romanTableColumn) {
            [revision setRoman:anObject];
        } else if(aTableColumn == scriptTableColumn) {
            [revision setScript:anObject];
        } else if(aTableColumn == backTranslationTableColumn) {
            [revision setBackTranslation:anObject];
        } else if(aTableColumn == notesTableColumn) {
            [revision setNotes:anObject];
        } else if(aTableColumn == checkingTableColumn) {
            [revision setChecking:anObject];
        } else {
            NSLog(@"unhandled column %@ for setObjectValue:ForTableColumn:Row", aTableColumn);
        }
    } else {
        NSLog(@"unhandled object %@ calling setObjectValue:ForTableColumn:Row", aTableView);
    }
    
    // TODO: Change this when undo/redo is supported
    [self updateChangeCount:NSChangeDone];
	
    [self ensureOneBlankVerse];
    [self updateUI];
}

/*
 Provide popup menus in the type and revision columns.
 http://members.shaw.ca/akochoi/2003/10-05/index.html#1
 */
- (void)tableView:(NSTableView *)aTableView 
  willDisplayCell:(id)aCell
   forTableColumn:(NSTableColumn *)aTableColumn 
              row:(int)rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [visibleVerseIndexes count]);
    rowIndex = [(NSNumber *)[visibleVerseIndexes objectAtIndex:rowIndex] intValue];
    RTKVerse * verse = [[book verses] objectAtIndex:rowIndex];
    
    if(aTableColumn == revisionTableColumn) {
        NSMutableArray * revisions = [verse revisions];
        int revisionCount = [revisions count];
        int revisionIndex = [verse currentRevisionIndex];
        
        [(NSPopUpButtonCell *)aCell removeAllItems];
        int i;
        for(i = 0; i < revisionCount; i++) {
            NSString * title = [NSString stringWithFormat:@"%i of %i", i + 1, revisionCount];
            if([(RTKRevision *)[revisions objectAtIndex:i] locked])
                title = [title stringByAppendingString:@" (Locked)"];
            [(NSPopUpButtonCell *)aCell addItemWithTitle:title];
        }
        [(NSPopUpButtonCell *)aCell selectItemAtIndex:revisionIndex];
    } else if(aTableColumn == typeTableColumn) {
        NSString * type = [verse type];
        
        [(NSComboBoxCell *)aCell removeAllItems];
        [(NSComboBoxCell *)aCell addItemsWithObjectValues:verseTypes];
        [(NSComboBoxCell *)aCell selectItemWithObjectValue:type];
        [(NSComboBoxCell *)aCell setStringValue:type];
        
    } else if(aTableColumn == lockedTableColumn) {
        [(NSButtonCell *)aCell setState:([verse locked] ? NSOnState : NSOffState)];
    }
}

#pragma mark -
#pragma mark Script Conversion

- (void)transcriptionTypeChanged:(id)dummy
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"])
		[self regenerateAllScript];
}

- (void)transliterationOnChanged:(id)dummy
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"]) {
		[versesTableView addTableColumn:scriptTableColumn];
		[versesTableView moveColumn:([versesTableView numberOfColumns] - 1) toColumn:4];
		
		[splitViewOfTextViews addSubview:scriptView
							  positioned:NSWindowBelow
							  relativeTo:romanView];
		
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"])
			[self regenerateAllScript];
	} else {
		[versesTableView removeTableColumn:scriptTableColumn];
		[scriptView removeFromSuperview];
        
	}
	[self readSplitViewRectsFromDefaults];
	[self writeSplitViewRectsToDefaults];
}



- (void)mainThreadUpdateUI:(id)dummy
{
    if(!windowIsOpen)
        return;
    NSRect rowRect = [versesTableView rectOfRow:[versesTableView selectedRow]];    
    [versesTableView setNeedsDisplayInRect:rowRect];
    
    [[scriptPublishedTextView textStorage] setAttributedString:[book mutableAttributedString:NO]];  // YES = roman, NO = script
    [self highlightVerse:[[book verses] objectAtIndex:[versesTableView selectedRow]] inTextView:scriptPublishedTextView];
    
    [scriptTextView setString:[[currentVerse currentRevision] script]];
    
    [self updateUI];
}

- (void)regenerateAllScript
{
    NSEnumerator * verseEnumerator = [[book verses] objectEnumerator];
    RTKVerse * verse;
	
    while(verse = [verseEnumerator nextObject]) {
        [[self doSelf] convertRevision:[[verse revisions] each]
                      withHighPriority:NO];
    }
}

- (void)convertRevision:(RTKRevision *)revision
	   withHighPriority:(BOOL)highPriority
{
    [revisionsToConvertLock lock];
    if(highPriority)
        [revisionsToConvert insertObject:revision atIndex:0];
    else
        [revisionsToConvert addObject:revision];
    [revisionsToConvertLock unlock];
    [convertingLock unlock];
}

- (void)doConversionThread:(id)dummy
{
    while(1) {
		
        while(![revisionsToConvert count]) {
            [convertingLock lock];
        }
        if([revisionsToConvert count]) {
            NSAutoreleasePool * autoreleasePool = [[NSAutoreleasePool alloc] init];
			
            [revisionsToConvertLock lock];
            //NSLog(@"%@ removing 1 of %i revisions from queue", self, [revisionsToConvert count]);
            RTKRevision * revision = [revisionsToConvert objectAtIndex:0];
            [revisionsToConvert removeObjectAtIndex:0];
            [revisionsToConvertLock unlock];
			
            NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
            NSString * fontOutputString = nil;
            
            NSString * transcriptionType = [d valueForKey:@"RTKTranscriptionType"];
            fontOutputString = transcriptionType;
            {
            NSString * definitionDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/active_definitions/"];
                 NSDictionary * output = [RTKSharedConvertor convertString:[revision roman]
                                                               inputSystem:[definitionDir stringByAppendingString:
                                                                            [[d objectForKey:@"RTKInputSystem"] stringByAppendingString:@".rtkinput"]]
                                                              scriptSystem:[definitionDir stringByAppendingString:
                                                                            [[d objectForKey:@"RTKScriptSystem"] stringByAppendingString:@".rtkscript"]]
                                                                fontSystem:[definitionDir stringByAppendingString:
                                                                            [[d objectForKey:@"RTKEncodingSystem"] stringByAppendingString:@".rtkfont"]]
                                                           withMetaStrings:generateMetaStrings
                                                       checkForPunctuation:NO];
                 
                 if(generateMetaStrings)
                     NSLog(@"%@", [output description]);
                 
                 fontOutputString = [output objectForKey:@"RTKFont"];            
             }
			
            if(fontOutputString)
                [revision setScript:fontOutputString];
                
            
            [autoreleasePool release];
            
        }
        [self performSelectorOnMainThread: @selector(mainThreadUpdateUI:)
                               withObject: nil
                            waitUntilDone: NO];
    }
}


@end

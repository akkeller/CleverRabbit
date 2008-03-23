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
#import "RTKStringCategory.h"
#import "RTKMutableAttributedStringCategory.h"

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
        //revisionsToConvertLock = [[NSLock alloc] init];
        
        // RTKSharedDatabase and RTKSharedConvertor are global for now.
        // They may not always be global, so don't depend on them.
        if(!RTKSharedConvertor)
            RTKSharedConvertor = [[RTKConvertor alloc] init];
        if(!RTKSharedDatabase)
            RTKSharedDatabase = [RTKSharedConvertor generalDatabase];
        
        [self setCreationDate:[NSDate dateWithTimeIntervalSinceNow:0.0]];
        
        [self setBindingsFromDictionary:nil];
        
        [self setVerseTypes:[NSMutableArray arrayWithObjects:
                             @"\\v", @"\\p", @"\\s1", @"\\s2", @"\\r", @"\\mt1", @"\\mt2", @"\\mt3", @"\\is", @"\\ip", @"\\h", nil]];
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
    [toolbarItems release];
    [toolbarKeys release];
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
		[versesTableView setDoubleAction:@selector(tableViewDoubleClicked)];
		
		[versesTableView setVerticalMotionCanBeginDrag:NO];
		
		[scriptTableColumn retain]; // Prevent dealloc of tablecolumn when hiding column. 
		[scriptView retain];
		if(![[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"]) {
			[versesTableView removeTableColumn:scriptTableColumn];
			[scriptView removeFromSuperview];
		}
		
		NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
		
		[self readSplitViewRectsFromDefaults];
		
		// The toolbar needs icons and a bit of other work.
		//[self setupToolbar];
		
		[self ensureOneBlankVerse];
		
		[self search:searchField];
		[documentWindow makeFirstResponder:romanTextView];
		
		[self setDictionary:[NSDictionary dictionary]];
        
		[self updateUI];
		
		[versesTableView selectRow:0 byExtendingSelection:NO];
		
		alreadyAwokeFromNib = YES;
	}
}

- (void)tableViewDoubleClicked
{
    // This isn't being used yet.
	// NSLog(@"tableViewDoubleClicked");
}

#pragma mark -

- (BOOL)keepBackupFile
{
    return NO;
}

#pragma mark -
#pragma mark toolbar
/*
 http://www.cocoadevcentral.com/articles/000037.php
 */

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag 
{
    return [toolbarItems objectForKey:itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return toolbarKeys;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    //return [[toolbarItems allKeys] subarrayWithRange:NSMakeRange(0,6)];
    return [toolbarItems allKeys];
}

- (void) toolbarWillAddItem: (NSNotification *) notification
{
    NSToolbarItem *addedItem = [[notification userInfo] objectForKey:@"item"];
    
    // set up the item here
}

- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
    NSToolbarItem *removedItem = [[notification userInfo] objectForKey:@"item"];
    
    // clear associated info here 
}

- (IBAction)customizeToolbar:(id)sender 
{ 
    [toolbar runCustomizationPalette:sender]; 
}

- (IBAction)hideShowToolbar:(id)sender 
{ 
    [toolbar setVisible:![toolbar isVisible]]; 
}

- (void)newToolbarItemWithName:(NSString *)name
						action:(SEL)action
{
    NSToolbarItem * item = [[NSToolbarItem alloc] initWithItemIdentifier:name];
    [item setPaletteLabel:name];
    [item setLabel:name];
    [item setTarget:self];
    [item setAction:action];
    
    [toolbarItems setObject:item forKey:name];
    [toolbarKeys addObject:name];
    [item release];
}

- (void)setupToolbar
{
    
    toolbarItems = [[NSMutableDictionary alloc] init];
    toolbarKeys = [[NSMutableArray alloc] init];
    
    [self newToolbarItemWithName:@"New Sentence" action:@selector(newVerse:)];
    [self newToolbarItemWithName:@"Delete Sentence" action:@selector(deleteVerse:)];
    
    [self newToolbarItemWithName:@"New Revision" action:@selector(newRevision:)];
    [self newToolbarItemWithName:@"Delete Revision" action:@selector(deleteRevision:)];
    
    [self newToolbarItemWithName:@"Lock Revision" action:@selector(lockRevision:)];    
	
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"RTKTigerToolbar"];
    
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    
    [documentWindow setToolbar:toolbar];
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
	
	
    [[NSApp delegate] setCopiedVersesArray:[selectedVerses deepCopy]];     
    [pasteboard setData:nil forType:@"RTKBook"];
}

- (void)paste:(id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *type = [pasteboard availableTypeFromArray:[NSArray arrayWithObject:@"RTKBook"]];
    if (type != nil) {
        int lastIndex = [[versesTableView selectedRowIndexes] lastIndex];
        if(lastIndex == NSNotFound)
            lastIndex = [[book verses] count];
        else
            lastIndex++;
        
        NSMutableArray * pastedVerses = [[[NSApp delegate] copiedVersesArray] deepCopy];
        
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
    [[NSApp delegate] setDraggedVersesArray:[[book verses] arrayWithObjectsAtIndexes:rows]];
    [[NSApp delegate] setDraggedVersesOwner:self];
    
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
	
    if ([pboard availableTypeFromArray:[NSArray arrayWithObject: @"RTKVersesInternalToBook"]]) {
        if([[NSApp delegate] draggedVersesOwner] == self) {
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
            NSMutableArray * draggedVerses = [[NSApp delegate] draggedVersesArray];
            
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
    } else {
        [romanTextView setCharacterSwaps:nil];
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

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    NSData * data = nil;
	
    [self writeSplitViewRectsToDefaults];
	
    if([aType isEqualToString:@"rtktiger"])
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
	 } else if([aType isEqualToString:@"txt"]) {        
		 
		 NSString * string = [book string];
		 
		 if(!book)
			 NSLog(@"nil book");
		 if(!string)
			 NSLog(@"nil string");
		 
		 data = [string utf8Data];
		 
		 if(!data)
			 NSLog(@"nil data from outputData");
	 } else if([aType isEqualToString:@"ptx"]) {        
		 
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

- (void)updatePublishedTextView
{
    // quick non-editable prototype
    [[publishedTextView textStorage] setAttributedString:[book mutableAttributedString]];
}

- (void)updateUI
{
	[self performSelectorOnMainThread: @selector(updateUIMainThread:)
						   withObject: nil
						waitUntilDone: NO];
}

// This method updates pretty much everything regardless of what needs updating. 
- (void)updateUIMainThread:(id)dummy
{
    int selectedRow;
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
        [romanTextView setString:@""];
        [scriptTextView setString:@""];
        [backTranslationTextView setString:@""];
        [notesTextView setString:@""];
        [checkingTextView setString:@""];
        
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
        // Get the context we are working in.
        NSMutableArray * verses = [book verses];
        RTKVerse * verse = nil;
        if([visibleVerseIndexes count] > selectedRow) {
            verse = [verses objectAtIndex:[[visibleVerseIndexes objectAtIndex:selectedRow] intValue]];
        } else {
            NSLog(@"[visibleVerseIndexes count] <= selectedRow: %i, %i", [visibleVerseIndexes count], selectedRow);
            return;
        }
        int verseCount = [verses count];
        
        NSMutableArray * revisions = [verse revisions];
        int revisionCount = [revisions count];
        int currentRevisionIndex = [verse currentRevisionIndex];
        RTKRevision * revision = [revisions objectAtIndex:currentRevisionIndex];
        
        // Set the text views that need to change.
        // Shouldn't be doing it like this -- see repeated accessor calls.
        if(![[romanTextView string] isEqualToString:[revision roman]])
            [romanTextView setString:[revision roman]];
        if(![[scriptTextView string] isEqualToString:[revision script]]) {
            [scriptTextView setString:[revision script]];
        [self updateCommiteeMeetingText:YES];		}
        if(![[backTranslationTextView string] isEqualToString:[revision backTranslation]])
            [backTranslationTextView setString:[revision backTranslation]];
        if(![[notesTextView string] isEqualToString:[revision notes]])
            [notesTextView setString:[revision notes]];
        if(![[checkingTextView string] isEqualToString:[revision checking]])
            [checkingTextView setString:[revision checking]];
        
        
        
        NSFont * font;
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKScriptFontName"]
                               size:[(NSString *) [d valueForKey:@"RTKScriptFontSize"] floatValue]];
        if(font) {
            [scriptTextView setFont:font];
        }
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKRomanFontName"]
                               size:[(NSString *) [d valueForKey:@"RTKRomanFontSize"] floatValue]];
        if(font) {
            [romanTextView setFont:font];
        }
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKBackTranslationFontName"]
                               size:[(NSString *) [d valueForKey:@"RTKBackTranslationFontSize"] floatValue]];
        if(font) {
            [backTranslationTextView setFont:font];
        }
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKNotesFontName"]
							   size:[(NSString *) [d valueForKey:@"RTKNotesFontSize"] floatValue]];
        if(font) {
            [notesTextView setFont:font];
        }
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKCheckingFontName"]
                               size:[(NSString *) [d valueForKey:@"RTKCheckingFontSize"] floatValue]];
        if(font) {
            [checkingTextView setFont:font];
        }
        
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKScriptFontName"]
                               size:12];
        if(font) {
            [[scriptTableColumn dataCell] setFont:font];
        }
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKRomanFontName"]
                               size:12];
        if(font) {
            [[romanTableColumn dataCell] setFont:font];
        }
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKBackTranslationFontName"]
                               size:12];
        if(font) {
            [[backTranslationTableColumn dataCell] setFont:font];
        }
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKNotesFontName"]
                               size:12];
        if(font) {
            [[notesTableColumn dataCell] setFont:font];
        }
        
        font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKCheckingFontName"]
                               size:12];
        if(font) {
            [[checkingTableColumn dataCell] setFont:font];
        }
        
#pragma mark Locking
		
     {
         BOOL verseLocked = [verse locked];
         BOOL revisionLocked = [revision locked];
         int revisionCount = [verse revisionCount];
         int revisionIndex = [verse currentRevisionIndex];
         
         [[[NSApp delegate] newVerseMenuItem] setEnabled:YES];
         [[[NSApp delegate] deleteVerseMenuItem] setEnabled:!verseLocked];
         [[[NSApp delegate] lockVerseMenuItem] setState:(verseLocked ? NSOnState : NSOffState)];
         
         [deleteVerseButton setEnabled:(!verseLocked ? NSOnState : NSOffState)];
         
         [referenceTableColumn setEditable:!(verseLocked || revisionLocked)];
         [typeTableColumn setEditable:!(verseLocked || revisionLocked)];
         [revisionTableColumn setEditable:!(verseLocked || revisionLocked)];
         
         [[[NSApp delegate] lockRevisionMenuItem] setEnabled:!verseLocked];
         [[[NSApp delegate] lockRevisionMenuItem] setState:(revisionLocked ? NSOnState : NSOffState)];
         [[[NSApp delegate] deleteRevisionMenuItem] setEnabled:!(verseLocked || revisionLocked)];
         [[[NSApp delegate] newRevisionMenuItem] setEnabled:!verseLocked];
         
         [newRevisionButton setEnabled:!verseLocked];
         [deleteRevisionButton setEnabled:!(verseLocked || revisionLocked)];
         
         [[appController nextRevisionMenuItem] setEnabled:
          (([verse currentRevisionIndex] < [verse revisionCount] - 1) && !verseLocked)];
         [[appController previousRevisionMenuItem] setEnabled:
          (([verse currentRevisionIndex] > 0) && !verseLocked)];
         
         [[appController nextVerseMenuItem] setEnabled:(selectedRow < verseCount - 1)];
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
    
    [self updatePublishedTextView];
}


- (void)readSplitViewRectsFromDefaults
{
	//NSLog(@"readSplitViewRectsFromDefaults");
	
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
	//NSLog(@"writeSplitViewRectsToDefaults");
	
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
    NSMutableArray * verses = [book verses];
    
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
    [self updateUI];
    
    if(rowIndex > 0)
        [versesTableView selectRow:(rowIndex - 1) byExtendingSelection:NO];
    
    // TODO: Change this when undo/redo is supported
    [self updateChangeCount:NSChangeDone];
}

- (void)nextVerse:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    int rowCount = [versesTableView numberOfRows];
    
    if(selectedRow < rowCount - 1) {
        [versesTableView selectRow:(selectedRow + 1) byExtendingSelection:NO];
        [versesTableView scrollRowToVisible:(selectedRow + 1)];
    }
}

- (void)previousVerse:(id)sender
{
    int selectedRow = [versesTableView selectedRow];
    if(selectedRow >= 0) {
        int rowCount = [versesTableView numberOfRows];
        
        if(selectedRow > 0) {
            [versesTableView selectRow:(selectedRow - 1) byExtendingSelection:NO];    
            [versesTableView scrollRowToVisible:(selectedRow - 1)];
        }
    }
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
#pragma mark commitee meeting update

- (void)updateCommiteeMeetingText:(BOOL)mirrorText
{
	NSString *string = @"";
	if(mirrorText)
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"])
			string = [scriptTextView string];
		else
			string = [romanTextView string];
	
	[[NSNotificationCenter defaultCenter] postNotification:
     [NSNotification notificationWithName:@"RTKChangedCommitteeString" object:string]];
}

#pragma mark -
#pragma mark window delegate methods

- (void)windowWillClose:(NSNotification *)aNotification
{
    windowIsOpen = NO;
    [convertingLock unlock];
	[self updateCommiteeMeetingText:NO];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[self updateCommiteeMeetingText:YES];
	[self readSplitViewRectsFromDefaults];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	//NSLog(@"windowDidResignKey");
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
	//NSLog(@"constrain");
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
    NSTextView * changedTextView = [notification object];
    
    NSMutableArray * verses = [book verses];
    RTKVerse * verse = [verses objectAtIndex:[[visibleVerseIndexes objectAtIndex:[versesTableView selectedRow]] intValue]];
    int revisionIndex = [verse currentRevisionIndex];
    NSMutableArray * revisions = [verse revisions];
    RTKRevision * revision = [revisions objectAtIndex:revisionIndex];
    
    if(changedTextView == romanTextView) {
        [revision setRoman:[[changedTextView string] copy]];
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"RTKTransliterationOn"])
			[self convertRevision:revision
				 withHighPriority:YES];
		else
			[self updateCommiteeMeetingText:YES];
        [self updatePublishedTextView];
    } else if(changedTextView == scriptTextView) {
        [revision setScript:[[changedTextView string] copy]];
        [self updatePublishedTextView];
    } else if(changedTextView == backTranslationTextView) {
        [revision setBackTranslation:[[changedTextView string] copy]];
        [self updatePublishedTextView];
    } else if(changedTextView == notesTextView) {
        [revision setNotes:[[changedTextView string] copy]];
        [self updatePublishedTextView];
    } else if(changedTextView == checkingTextView) {
        [revision setChecking:[[changedTextView string] copy]];
        [self updatePublishedTextView];
    } else if(changedTextView == publishedTextView) {
        [self publishedTextViewDidChange:notification];
    } else {
        NSLog(@"unhandled textview %@ sent to textDidChange", changedTextView);
        NSLog(@"publishedTextView: %@", publishedTextView);
    }
    // TODO: Change this when undo/redo is supported
    [self updateChangeCount:NSChangeDone];
    
    NSRect rowRect = [versesTableView rectOfRow:[versesTableView selectedRow]];    
    [versesTableView setNeedsDisplayInRect:rowRect];
	
    [self ensureOneBlankVerse];
}

// Informs the appropriate RTKVerse object of its changes.
- (void)publishedTextViewDidChange:(NSNotification *)notification
{
    NSTextStorage *textStorage = [publishedTextView textStorage];
    NSRange selectedRange = [publishedTextView selectedRange];
    
    NSRange verseRange;    
    RTKVerse *verse = [textStorage attribute:@"RTKVerse" 
                                     atIndex:selectedRange.location
                       longestEffectiveRange:&verseRange
                                     inRange:NSMakeRange(0, [textStorage length])];
    NSAttributedString *verseString = [textStorage attributedSubstringFromRange:verseRange];
    
    BOOL changeAccepted = [verse updateWithAttributedString:verseString atIndex:(selectedRange.location - verseRange.location)];
    
    if(!changeAccepted) {
        NSLog(@"RTKVerse rejected change.");
        [self updatePublishedTextView];
        [publishedTextView setSelectedRange:selectedRange];
    }
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{   
    NSLog(@"textViewDidChangeSelection");
    NSTextView * changedTextView = [notification object];
    
    if(changedTextView = publishedTextView) {
        NSTextStorage *textStorage = [publishedTextView textStorage];
        NSRange selectedRange = [publishedTextView selectedRange];
        
        // Don't allow editing end of text field.
        if(selectedRange.location == [textStorage length]) {
            [publishedTextView setEditable:NO];
            return;
        }
        
        // Temporary logging for testing.
        NSLog([[textStorage attributesAtIndex:selectedRange.location effectiveRange:NULL] description]);
        
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
        if((selectedRange.location + selectedRange.length - 1) > 0) {
            nextToLastComponent = [textStorage attribute:@"RTKVerseComponent" 
                                                 atIndex:selectedRange.location + selectedRange.length - 1
                                   longestEffectiveRange:&nextToLastComponentRange
                                                 inRange:NSMakeRange(0, [textStorage length])];
        }
        
        // Don't allow editing if selection spans multiple verses or components.
        if((firstVerse != lastVerse) || ((firstComponent != lastComponent) && (firstComponent != nextToLastComponent)) ) {
            [publishedTextView setEditable:NO];
            return;
        }
        
        [textStorage removeAttribute:NSBackgroundColorAttributeName];
        
        // Allow editing if selection is within the text of a verse.
        if([firstComponent isEqualToString:@"Verse Text"]) {
            [publishedTextView setEditable:YES];
            [textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:firstComponentRange];
        } else {
            if((selectedRange.location + selectedRange.length - 1) > 0) {
                
                // Allow editing if at the end of a "Verse Text" section.
                if([nextToLastComponent isEqualToString:@"Verse Text"]) {
                    [publishedTextView setEditable:YES];
                    NSRange verseTextRange;
                    [publishedTextView setTypingAttributes:[textStorage attributesAtIndex:selectedRange.location + selectedRange.length - 1
                                                                           effectiveRange:NULL]];
                    [textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:nextToLastComponentRange];
                } else {
                    [publishedTextView setEditable:NO];
                }
            }
        }
    }
}


- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self updateUI];
}

- (void)reloadTableData:(id)dummy
{
    [versesTableView reloadData];
}

#pragma mark -
#pragma mark table delegate methods

- (void)tableView:(NSTableView *)tableView 
didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSLog(@"click in column header %@, row %i", tableColumn, [versesTableView selectedRow]);
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
    [self updateUI];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    [self ensureOneBlankVerse];
    [self updateUI];
}

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
        NSLog(@"unhandled object %@ calling tableView:objectValueForTableColumn:row:");
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
        } else if(aTableColumn == typeTableColumn) {
            [verse setType:anObject];
        } else if(aTableColumn == revisionTableColumn) {
            [verse setCurrentRevisionIndex:[(NSNumber *)anObject intValue]];
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
	[self updateCommiteeMeetingText:YES];
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
	[self updateCommiteeMeetingText:YES];
}



- (void)mainThreadUpdateUI:(id)dummy
{
    if(!windowIsOpen)
        return;
    NSRect rowRect = [versesTableView rectOfRow:[versesTableView selectedRow]];    
    [versesTableView setNeedsDisplayInRect:rowRect];
	
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
            /*if([transcriptionType isEqualToString:@"No Transcription"]) {
             fontOutputString = @"No Transcription -- You can turn this on in the Preferences.";
             } else if([transcriptionType isEqualToString:@"External Transcription"]) {
             fontOutputString = @"External Transcription -- This should eventually use TECkit, Perl, Python or any other command line tool.";
             } else if([transcriptionType isEqualToString:@"RTK Transcription"]) */{
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

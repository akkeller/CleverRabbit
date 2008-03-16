//
//   RTKTigerDocument.h
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//


#import <Cocoa/Cocoa.h>
#import "RTKBook.h"
#import "RTKVerse.h"
#import "RTKRevision.h"
#import "RTKConvertor.h"
#import "RTKTigerTextView.h"


@interface RTKTigerDocument : NSDocument
{
    // Permanent data object
    RTKBook * book;
    
    // Drag and Drop internal to this document
    NSArray * draggedVerseIndexArray;
    
    // Search
    NSArray * visibleVerseIndexes;
    
    // transcription queue
    NSMutableArray * revisionsToConvert;
    
    // Window state information
    BOOL windowIsOpen;
	
	// Nib life-cycle information.
    BOOL alreadyAwokeFromNib;
	
    // Verse Types
    NSMutableArray * verseTypes;
    
    // UI Objects
    
    // Single Verse View
    IBOutlet NSWindow * documentWindow;
    IBOutlet NSToolbar * toolbar;
    NSMutableDictionary * toolbarItems;
    NSMutableArray *toolbarKeys;
    
    IBOutlet NSButton * newVerseButton;
    IBOutlet NSButton * deleteVerseButton;
    IBOutlet NSButton * newRevisionButton;
    IBOutlet NSButton * deleteRevisionButton;
    
    IBOutlet NSTableView * versesTableView;
    IBOutlet NSSearchField * searchField;
    
    // Verse specific columns
    IBOutlet NSTableColumn * referenceTableColumn;
    IBOutlet NSTableColumn * typeTableColumn;
    IBOutlet NSTableColumn * revisionTableColumn;
    
    // Revision specific columns
    IBOutlet NSTableColumn * lockedTableColumn;
    IBOutlet NSTableColumn * romanTableColumn;
    IBOutlet NSTableColumn * scriptTableColumn;
    IBOutlet NSTableColumn * backTranslationTableColumn;
    IBOutlet NSTableColumn * notesTableColumn;
    IBOutlet NSTableColumn * checkingTableColumn;
        
    // Revision specific text fields
    IBOutlet RTKTigerTextView * romanTextView;
    IBOutlet RTKTigerTextView * scriptTextView;
    IBOutlet RTKTigerTextView * backTranslationTextView;
    IBOutlet RTKTigerTextView * notesTextView;
    IBOutlet RTKTigerTextView * checkingTextView;
	
	IBOutlet NSSplitView * horizontalSplitView;
	IBOutlet NSSplitView * verticalSplitView;
	
	IBOutlet NSView * rowView;
	IBOutlet NSView * editView;
	
	IBOutlet NSView * romanView;
	IBOutlet NSView * scriptView;
	IBOutlet NSView * backTranslationView;
	IBOutlet NSView * notesView;
	IBOutlet NSView * checkingView;

	
	IBOutlet NSSplitView * splitViewOfTextViews;
    
    // Published View
    IBOutlet NSTextView * publishedTextView;
    NSMutableArray * publishedVerses;
    /*
     Structure to map from a position in the text view to an RTKVerse in the RTKBook.
     Each verse represented as an NSMutableDictionary containing a verse number, verse text, and eventually footnote offsets.
     */
    
	
    // Definition files
    NSString * inputDefinitionPath;
    NSString * scriptDefinitionPath;
    NSString * encodingDefinitionPath;
    
    // Script Conversion
    NSLock * convertingLock;
    NSLock * revisionsToConvertLock;
    BOOL dirtyUI;
	
	// Document Bindings
	int RTKDocumentWidth;
    int RTKDocumentHeight;
    
    int RTKReferenceColumnWidth;
    int RTKRevisionColumnWidth;
    int RTKScriptColumnWidth;
    int RTKRomanColumnWidth;
    int RTKBackTranslationColumnWidth;
    int RTKNotesColumnWidth;
    int RTKCheckingColumnWidth;
    
    NSDate * creationDate;
    
    // Lossless forwards/backwards compatibility
    NSDictionary * dictionary;
}

- (RTKBook *)book;
- (void)setBook:(RTKBook *)theBook;

- (void)setDictionary:(NSDictionary *)theDictionary;
- (NSDictionary *)dictionary;

- (NSDate *)creationDate;
- (void)setCreationDate:(NSDate *)newCreationDate;
- (IBAction)search:(id)sender;
- (void)setVerseTypes:(NSMutableArray *)theVerseTypes;

- (IBAction)newVerse:(id)sender;
- (IBAction)deleteVerse:(id)sender;
- (IBAction)nextVerse:(id)sender;
- (IBAction)previousVerse:(id)sender;
- (IBAction)setVerseType:(id)sender;

- (IBAction)newRevision:(id)sender;
- (IBAction)deleteRevision:(id)sender;
- (IBAction)nextRevision:(id)sender;
- (IBAction)previousRevision:(id)sender;

- (IBAction)switchRevision:(id)sender;
- (IBAction)lockRevision:(id)sender;

- (void)updateUI;
- (void)readSplitViewRectsFromDefaults;
- (void)ensureOneBlankVerse;

- (void)setFieldEditor:(BOOL)editor;

- (void)setVisibleVerseIndexes:(NSArray *)indexes;
- (void)setBindingsFromDictionary:(NSDictionary *)dict;

- (void)setupToolbar;

- (void)cut:(id)sender;
- (void)copy:(id)sender;
- (void)paste:(id)sender;

-(void)regenerateAllScript;
-(void)convertRevision:(RTKRevision *)revision
      withHighPriority:(BOOL)highPriority;


@end

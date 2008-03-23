//
//   RTKCleverRabbitController.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import "RTKCleverRabbitController.h"

@implementation RTKCleverRabbitController

- (id)init
{
	if(self = [super init]) {		
		// Set default preferences settings
		// This should really be in RTKPreferencesController.m
		NSMutableDictionary * d = [NSMutableDictionary dictionary];
		
		[d setObject:@"KSCII" forKey:@"RTKEncodingSystem"];
		[d setObject:@"Phonemic" forKey:@"RTKInputSystem"];
		[d setObject:@"NewKrung" forKey:@"RTKScriptSystem"];
		[d setObject:@"^" forKey:@"RTKPlainTextDelimiter"];
		[d setObject:@"<return>" forKey:@"RTKPlainTextReturnCharacter"];
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"RTKZVXSubstitution"];  
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"RTKTransliterationOn"];  
		
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"RTKHorizonatalSplitViewSizeSaved"];
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"RTKSplitViewSizesWithTransliterationSaved"];
		[d setObject:[NSNumber numberWithBool:NO] forKey:@"RTKSplitViewSizesWithoutTransliterationSaved"];
		
		[d setObject:[NSNumber numberWithInt:700] forKey:@"RTKDocumentWidth"];  
		[d setObject:[NSNumber numberWithInt:500] forKey:@"RTKDocumentHeight"];  
		
		[d setObject:[NSNumber numberWithInt:100] forKey:@"RTKReferenceColumnWidth"];  
		[d setObject:[NSNumber numberWithInt:100] forKey:@"RTKRevisionColumnWidth"];  
		[d setObject:[NSNumber numberWithInt:100] forKey:@"RTKScriptColumnWidth"];  
		[d setObject:[NSNumber numberWithInt:100] forKey:@"RTKRomanColumnWidth"];  
		[d setObject:[NSNumber numberWithInt:100] forKey:@"RTKBackTranslationColumnWidth"];
		[d setObject:[NSNumber numberWithInt:100] forKey:@"RTKNotesColumnWidth"];  
		[d setObject:[NSNumber numberWithInt:100] forKey:@"RTKCheckingColumnWidth"];  
		
		[d setObject:@"Helvetica" forKey:@"RTKCommitteeFontName"];
		[d setObject:[NSNumber numberWithInt:48] forKey:@"RTKCommitteeFontSize"];
		[d setObject:@"Helvetica" forKey:@"RTKScriptFontName"];
		[d setObject:[NSNumber numberWithInt:12] forKey:@"RTKScriptFontSize"];
		[d setObject:@"Helvetica" forKey:@"RTKRomanFontName"];
		[d setObject:[NSNumber numberWithInt:12] forKey:@"RTKRomanFontSize"];
		[d setObject:@"Helvetica" forKey:@"RTKBackTranslationFontName"];
		[d setObject:[NSNumber numberWithInt:12] forKey:@"RTKBackTranslationFontSize"];
		[d setObject:@"Helvetica" forKey:@"RTKNotesFontName"];
		[d setObject:[NSNumber numberWithInt:12] forKey:@"RTKNotesFontSize"];
		[d setObject:@"Helvetica" forKey:@"RTKCheckingFontName"];
		[d setObject:[NSNumber numberWithInt:12] forKey:@"RTKCheckingFontSize"];
        [d setObject:@"Helvetica" forKey:@"RTKPublishedFontName"];
		[d setObject:[NSNumber numberWithInt:12] forKey:@"RTKPublishedFontSize"];

		[d setValue:@"No Transcription" forKey:@"RTKTranscriptionType"];
		
		[[NSUserDefaults standardUserDefaults]
			registerDefaults:d];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		[nc addObserver:self 
			   selector:@selector(changedCommitteeString:) 
				   name:@"RTKChangedCommitteeString" 
				 object:nil];
		
		[nc addObserver:self
               selector:@selector(fontsChanged:)
                   name:@"RTKFontsChanged"
                 object:nil];
	}
	return self;
}

- (void)changedCommitteeString:(NSNotification *)aNotification
{
	[committeeMeetingTextView setString:(NSString *) [aNotification object]];
	
	NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    NSFont *font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKCommitteeFontName"]
								   size:[(NSString *) [d valueForKey:@"RTKCommitteeFontSize"] floatValue]];
	if(font) {
		[committeeMeetingTextView setFont:font];
	}
}

- (void)fontsChanged:(NSNotification *)aNotification
{
	NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    NSFont *font = [NSFont fontWithName:(NSString *)[d valueForKey:@"RTKCommitteeFontName"]
								   size:[(NSString *) [d valueForKey:@"RTKCommitteeFontSize"] floatValue]];
	if(font) {
		[committeeMeetingTextView setFont:font];
	}
}

- (IBAction)openBugsAndFeatures:(id)sender
{
    NSMutableString * path = [NSMutableString string];
    
    [path appendString:@"/usr/bin/open "];
    [path appendString:[[NSBundle mainBundle] resourcePath]];
    [path appendString:@"/bugsAndFeatures.txt"];
    
    system([path cString]);
}

#pragma mark -
// I'm not sure this is the best way to implement 
// document-centric menu items.
// This code might later be moved into RTKTigerDocument class.

- (IBAction)newVerse:(id)sender
{
    [[[NSApp keyWindow] delegate] newVerse:sender];
}

- (IBAction)deleteVerse:(id)sender
{
    [[[NSApp keyWindow] delegate] deleteVerse:sender];    
}

- (IBAction)nextVerse:(id)sender
{
    [[[NSApp keyWindow] delegate] nextVerse:sender]; 
}

- (IBAction)previousVerse:(id)sender
{
    [[[NSApp keyWindow] delegate] previousVerse:sender];
}

- (IBAction)lockVerse:(id)sender
{
    [[[NSApp keyWindow] delegate] lockVerse:sender];
}

- (IBAction)newRevision:(id)sender
{
    [[[NSApp keyWindow] delegate] newRevision:sender];
}

- (IBAction)deleteRevision:(id)sender
{
    [[[NSApp keyWindow] delegate] deleteRevision:sender];
}

- (IBAction)nextRevision:(id)sender
{
    [[[NSApp keyWindow] delegate] nextRevision:sender];
}

- (IBAction)previousRevision:(id)sender
{
    [[[NSApp keyWindow] delegate] previousRevision:sender];
}

- (IBAction)lockRevision:(id)sender
{
    [[[NSApp keyWindow] delegate] lockRevision:sender];
}

- (IBAction)showCommitteeMeetingPanel:(id)sender
{
	[committeeMeetingPanel orderFront:self];
}

- (NSMenuItem *)newVerseMenuItem
{
    return newVerseMenuItem;
}

- (NSMenuItem *)deleteVerseMenuItem
{
    return deleteVerseMenuItem;
}

- (NSMenuItem *)nextVerseMenuItem
{
    return nextVerseMenuItem;
}

- (NSMenuItem *)previousVerseMenuItem
{
    return previousVerseMenuItem;
}

- (NSMenuItem *)lockVerseMenuItem
{
    return lockVerseMenuItem;
}

- (NSMenuItem *)newRevisionMenuItem
{
    return newRevisionMenuItem;
}

- (NSMenuItem *)deleteRevisionMenuItem
{
    return deleteRevisionMenuItem;
}

- (NSMenuItem *)nextRevisionMenuItem
{
    return nextRevisionMenuItem;
}

- (NSMenuItem *)previousRevisionMenuItem
{
    return previousRevisionMenuItem;
}

- (NSMenuItem *)lockRevisionMenuItem
{
    return lockRevisionMenuItem;
}

#pragma mark -
#pragma mark drag and drop

- (void)setDraggedVersesArray:(NSArray *)versesArray
{
    [versesArray retain];
    [draggedVersesArray release];
    draggedVersesArray = versesArray;
}

- (NSArray *)draggedVersesArray
{
    return draggedVersesArray;
}

- (void)setDraggedVersesOwner:(id)sender
{
    // TODO: This could lead to a memory leak when closing documents after dragging.
    // FIX: Use clearDraggedVersesOwnerIfEqualTo method below when closing a document
    [sender retain];
    [draggedVersesOwner release];
    draggedVersesOwner = sender;
}

- (void)clearDraggedVersesOwnerIfEqualTo:(id)sender
{
    if(draggedVersesOwner == sender) {
        [draggedVersesOwner release];
        draggedVersesOwner = nil;
    }
}

- (id)draggedVersesOwner
{
    return draggedVersesOwner;
}

#pragma mark -
#pragma mark copy and paste

- (void)setCopiedVersesArray:(NSArray *)versesArray
{
    [versesArray retain];
    [copiedVersesArray release];
    copiedVersesArray = versesArray;
}

- (NSArray *)copiedVersesArray
{
    return copiedVersesArray;
}

#pragma mark -

- (void)dealloc
{
    [draggedVersesArray release];
    [draggedVersesOwner release];
    [copiedVersesArray release];
    
    [super dealloc];
}

@end

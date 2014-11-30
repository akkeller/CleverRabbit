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

#import <Cocoa/Cocoa.h>

@interface RTKCleverRabbitController : NSObject <NSApplicationDelegate>
{
    IBOutlet NSMenuItem * newVerseMenuItem;
    IBOutlet NSMenuItem * deleteVerseMenuItem;
    IBOutlet NSMenuItem * nextVerseMenuItem;
    IBOutlet NSMenuItem * previousVerseMenuItem;
    IBOutlet NSMenuItem * lockVerseMenuItem;	
	
    IBOutlet NSMenuItem * newRevisionMenuItem;
    IBOutlet NSMenuItem * deleteRevisionMenuItem;
    IBOutlet NSMenuItem * nextRevisionMenuItem;
    IBOutlet NSMenuItem * previousRevisionMenuItem;
    IBOutlet NSMenuItem * lockRevisionMenuItem;
	
	IBOutlet NSPanel *committeeMeetingPanel;
	IBOutlet NSTextView *committeeMeetingTextView;
	
	NSArray * draggedVersesArray;
    id draggedVersesOwner;
    NSArray * copiedVersesArray;
}

- (IBAction)openBugsAndFeatures:(id)sender;

- (void)changedCommitteeString:(NSNotification *)aNotification;
 
- (NSMenuItem *)newVerseMenuItem;
- (NSMenuItem *)deleteVerseMenuItem;
- (NSMenuItem *)nextVerseMenuItem;
- (NSMenuItem *)previousVerseMenuItem;
- (NSMenuItem *)lockVerseMenuItem;

- (NSMenuItem *)newRevisionMenuItem;
- (NSMenuItem *)deleteRevisionMenuItem;
- (NSMenuItem *)nextRevisionMenuItem;
- (NSMenuItem *)previousRevisionMenuItem;
- (NSMenuItem *)lockRevisionMenuItem;

- (void)setDraggedVersesArray:(NSArray *)versesArray;
- (NSArray *)draggedVersesArray;

- (void)setDraggedVersesOwner:(id)sender;
- (id)draggedVersesOwner;

- (void)setCopiedVersesArray:(NSArray *)versesArray;
- (NSArray *)copiedVersesArray;


@end

//
//   RTKPreferencesController.m
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

@interface RTKPreferencesController : NSObject
{
    IBOutlet NSTextField * delimiterTextField;
    IBOutlet NSTextField * returnCharacterTextField;
    
    IBOutlet NSButton * zvxButton;
    
    IBOutlet NSPopUpButton * inputPopUpButton;
    IBOutlet NSPopUpButton * scriptPopUpButton;
    IBOutlet NSPopUpButton * encodingPopUpButton;
    
    IBOutlet NSButton * webUpdateDefinitionsButton;
    IBOutlet NSProgressIndicator * webUpdateDefinitionsProgressIndicator;
	IBOutlet NSTextField * definitionVersionTextField;
	
	IBOutlet NSButton * transliterationOnButton;
    
	IBOutlet NSButton * committeeFontButton;
    IBOutlet NSButton * scriptFontButton;
    IBOutlet NSButton * romanFontButton;
    IBOutlet NSButton * backTranslationFontButton;
    IBOutlet NSButton * notesFontButton;
    IBOutlet NSButton * checkingFontButton;
    
	IBOutlet NSTextField * committeeFontTextField;
    IBOutlet NSTextField * scriptFontTextField;
    IBOutlet NSTextField * romanFontTextField;
    IBOutlet NSTextField * backTranslationFontTextField;
    IBOutlet NSTextField * notesFontTextField;
    IBOutlet NSTextField * checkingFontTextField;
    
    IBOutlet NSMatrix * convertorMatrix;

    IBOutlet NSTextField * externalConvertorTextField;
    
    IBOutlet NSWindow * preferencesWindow;
    
    NSTask * downloaderTask;
    
    NSMutableDictionary * inputSystemDict;
    NSMutableDictionary * scriptSystemDict;
    NSMutableDictionary * encodingSystemDict;
    
    NSString * definitionDir;
    
    NSPipe * standardOutputPipe;
    NSFileHandle * standardOutputFile;
}


- (IBAction)plainTextDelimiterChanged:(id)sender;
- (IBAction)plainTextReturnChanged:(id)sender;

- (IBAction)substituteZVXChanged:(id)sender;

- (IBAction)inputSystemChanged:(id)sender;
- (IBAction)scriptSystemChanged:(id)sender;
- (IBAction)encodingSystemChanged:(id)sender;

- (IBAction)transliterationOnChanged:(id)sender;

- (IBAction)webUpdateDefinitionsClicked:(id)sender;

- (IBAction)changeFont:(id)sender;

- (IBAction)convertorSwitched:(id)sender;
- (IBAction)setExternalConvertor:(id)sender;


@end

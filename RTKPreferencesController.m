//
//   RTKPreferencesController.h
//   (CleverRabbit.app)
//
//   Copyright (c) 2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//


#import "RTKPreferencesController.h"
extern id RTKSharedConvertor;

@implementation RTKPreferencesController

- (id)init
{
    if(self = [super init]) {
        inputSystemDict = [[NSMutableDictionary alloc] init];
        scriptSystemDict = [[NSMutableDictionary alloc] init];
        encodingSystemDict = [[NSMutableDictionary alloc] init];
        
        definitionDir = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/active_definitions"] retain];
    }
    return self;
}

- (void)dealloc
{
    [inputSystemDict release];
    [scriptSystemDict release];
    [encodingSystemDict release];
    [definitionDir release];
    
    [super dealloc];
}

-(void)loadDefFilesAt:(NSString *)defLocation 
               ofType:(NSString *)extension 
      intoPopUpButton:(NSPopUpButton *)popUp 
              andDict:(NSMutableDictionary *)dict
{
    NSString *file;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
        enumeratorAtPath:defLocation];
    
    [popUp removeAllItems];
    [dict removeAllObjects];
    
    while (file = [enumerator nextObject]) {
        if ([[file pathExtension] isEqualToString:extension]) {
            [dict setObject:[definitionDir stringByAppendingPathComponent:file]
                     forKey:[[file lastPathComponent] stringByDeletingPathExtension]];
            [popUp addItemWithTitle:[[file lastPathComponent] stringByDeletingPathExtension]];
        }
    }
}

-(void)loadDefinitions
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    
    [self loadDefFilesAt:definitionDir
                  ofType:@"rtkinput"
         intoPopUpButton:inputPopUpButton
                 andDict:inputSystemDict];
    
    [self loadDefFilesAt:definitionDir
                  ofType:@"rtkscript"
         intoPopUpButton:scriptPopUpButton
                 andDict:scriptSystemDict];
    
    [self loadDefFilesAt:definitionDir
                  ofType:@"rtkfont"
         intoPopUpButton:encodingPopUpButton
                 andDict:encodingSystemDict];
    
    [inputPopUpButton selectItemWithTitle:[d objectForKey:@"RTKInputSystem"]];
    [scriptPopUpButton selectItemWithTitle:[d objectForKey:@"RTKScriptSystem"]];
    [encodingPopUpButton selectItemWithTitle:[d objectForKey:@"RTKEncodingSystem"]];    
    
    [RTKSharedConvertor resetDefinitions];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    [self updateUI];
}

- (void)updateFontTextField:(NSTextField *)field
               withFontName:(NSString *)name
                       size:(NSNumber *)size
{
    [field setStringValue:[NSString stringWithFormat:@"%@ - %g", name, [size floatValue]]];
}

- (void)updateUI
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    
    NSString * plainTextDelimiter = [d objectForKey:@"RTKPlainTextDelimiter"];
    NSString * plainTextReturnCharacter = [d objectForKey:@"RTKPlainTextReturnCharacter"];
    
    if(plainTextDelimiter)
        [delimiterTextField setStringValue:plainTextDelimiter];
    
    if(plainTextReturnCharacter)
        [returnCharacterTextField setStringValue:plainTextReturnCharacter];
    if(externalConvertorTextField)
        [externalConvertorTextField setStringValue:[d objectForKey:@"RTKExternalConvertor"]];
    
    [zvxButton setState:[d boolForKey:@"RTKZVXSubstitution"]];
	
	[transliterationOnButton setState:[d boolForKey:@"RTKTransliterationOn"]];
    
    [self updateFontTextField:committeeFontTextField
                 withFontName:(NSString *)[d valueForKey:@"RTKCommitteeFontName"] 
                         size:(NSNumber *)[d valueForKey:@"RTKCommitteeFontSize"]];
	[self updateFontTextField:scriptFontTextField
                 withFontName:(NSString *)[d valueForKey:@"RTKScriptFontName"] 
                         size:(NSNumber *)[d valueForKey:@"RTKScriptFontSize"]];
    [self updateFontTextField:romanFontTextField
                 withFontName:(NSString *)[d valueForKey:@"RTKRomanFontName"] 
                         size:(NSNumber *)[d valueForKey:@"RTKRomanFontSize"]];
    [self updateFontTextField:backTranslationFontTextField
                 withFontName:(NSString *)[d valueForKey:@"RTKBackTranslationFontName"] 
                         size:(NSNumber *)[d valueForKey:@"RTKBackTranslationFontSize"]];
    [self updateFontTextField:notesFontTextField
                 withFontName:(NSString *)[d valueForKey:@"RTKNotesFontName"] 
                         size:(NSNumber *)[d valueForKey:@"RTKNotesFontSize"]];
    [self updateFontTextField:checkingFontTextField
                 withFontName:(NSString *)[d valueForKey:@"RTKCheckingFontName"] 
                         size:(NSNumber *)[d valueForKey:@"RTKCheckingFontSize"]];
    
    NSString * transcriptionType = [d valueForKey:@"RTKTranscriptionType"];
    if([transcriptionType isEqualToString:@"No Transcription"]) {
        [convertorMatrix setState:1 atRow:0 column:0];
    } else if([transcriptionType isEqualToString:@"External Transcription"]) {
        [convertorMatrix setState:1 atRow:1 column:0];
    } else if([transcriptionType isEqualToString:@"RTK Transcription"]) {
        [convertorMatrix setState:1 atRow:2 column:0];
    }

    [self loadDefinitions];    
}

- (IBAction)substituteZVXChanged:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender state]
                                            forKey:@"RTKZVXSubstitution"];
    [[NSNotificationCenter defaultCenter] postNotification:
        [NSNotification notificationWithName:@"RTKZVXSubstitutionChanged" object:nil]];
}

- (IBAction)transliterationOnChanged:(id)sender;
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state]
                                            forKey:@"RTKTransliterationOn"];
    [[NSNotificationCenter defaultCenter] postNotification:
        [NSNotification notificationWithName:@"RTKTransliterationOnChanged" object:nil]];	
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    id * object = [aNotification object];
    if(object == delimiterTextField) {
        [d setObject:[delimiterTextField stringValue] 
              forKey:@"RTKPlainTextDelimiter"];
    } else if(object == returnCharacterTextField) {
        [d setObject:[returnCharacterTextField stringValue] 
              forKey:@"RTKPlainTextReturnCharacter"];
    }
}

- (IBAction)setExternalConvertor:(id)sender
{
    NSOpenPanel * op = [NSOpenPanel openPanel];
    
    [op setCanChooseDirectories:NO];
    [op setCanChooseFiles:YES];
    [op setAllowsMultipleSelection:NO];
    [op setAllowsOtherFileTypes:YES];
    
    [op beginSheetForDirectory:[@"~" stringByExpandingTildeInPath]
                          file:@""
                         types:nil
                modalForWindow:preferencesWindow
                 modalDelegate:self
                didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                   contextInfo:op];
}
    
    
- (void)openPanelDidEnd:(NSWindow *)sheet
             returnCode:(int)returnCode 
            contextInfo:(void  *)contextInfo 
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    NSOpenPanel * op = (NSOpenPanel *)contextInfo;
    NSString * filename = [op filename];
    
    if(returnCode == NSOKButton) {
        [d setObject:filename
              forKey:@"RTKExternalConvertor"];
        [nc postNotification:
            [NSNotification notificationWithName:@"RTKExternalConvertorChanged" object:nil]]; 
        NSLog([d objectForKey:@"RTKExternalConvertor"]);
        [externalConvertorTextField setStringValue:filename];
        
        NSLog([[self parametersForExternalConvertor:filename] description]);
    }
}
    

- (NSDictionary *)parametersForExternalConvertor:(NSString *)convertor
{
    //[parameters setObject:@"test" forKey:@"this is a"];
    
    standardOutputPipe = [NSPipe pipe];
    standardOutputFile = [standardOutputPipe fileHandleForReading];
    
    NSTask * convertorTask = [[NSTask alloc] init];
    [convertorTask setLaunchPath:convertor];
    [convertorTask setStandardOutput:standardOutputPipe];
    [convertorTask setArguments:[NSArray arrayWithObjects:@"--parameters", nil]];
    [convertorTask launch];
    
    NSData * outputData = [standardOutputFile readDataToEndOfFile];
    NSString * outputString = [NSString stringWithUTF8String:[outputData bytes]];
    
    NSDictionary * parameters = [convertor propertyList];
    
    return parameters;
}
    /*
- (void) searchAction: (id) sender
{
    NSString *file;
    NSArray *args;
    NSTask *task;
    
    file = [sender stringValue];
    args = [NSArray arrayWithObjects: NSHomeDirectory(), @"-name", file, @"-print", nil];
    
    ASSIGN(pipe, [NSPipe pipe]);
    task = [NSTask new];
    [task setLaunchPath: @"/usr/bin/find"];
    [task setArguments: args];
    [task setStandardOutput: pipe];
    fileHandle = [pipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskEnded:)
                                                 name: NSTaskDidTerminateNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(readData:)
                                                 name: NSFileHandleReadCompletionNotification
                                               object: fileHandle];
    [fileHandle readInBackgroundAndNotify];
    [task launch];
}
*/

- (IBAction)inputSystemChanged:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender titleOfSelectedItem] 
                                              forKey:@"RTKInputSystem"];
    [[NSNotificationCenter defaultCenter] postNotification:
        [NSNotification notificationWithName:@"RTKDefinitionsChanged" object:nil]];    
}

- (IBAction)scriptSystemChanged:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender titleOfSelectedItem] 
                                              forKey:@"RTKScriptSystem"];
    [[NSNotificationCenter defaultCenter] postNotification:
        [NSNotification notificationWithName:@"RTKDefinitionsChanged" object:nil]];        
}

- (IBAction)encodingSystemChanged:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender titleOfSelectedItem] 
                                              forKey:@"RTKEncodingSystem"];
    [[NSNotificationCenter defaultCenter] postNotification:
        [NSNotification notificationWithName:@"RTKDefinitionsChanged" object:nil]];            
}

- (IBAction)webUpdateDefinitionsClicked:(id)sender
{
    if(downloaderTask)
        NSLog(@"downloaderTask still set to %@", downloaderTask);
    
    downloaderTask = [[NSTask alloc] init];
    [downloaderTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/get_definitions.command"]];
    [downloaderTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    [downloaderTask launch];
    
    [webUpdateDefinitionsButton setHidden:YES];
    [webUpdateDefinitionsProgressIndicator setUsesThreadedAnimation:YES];
    [webUpdateDefinitionsProgressIndicator setHidden:NO];
    [webUpdateDefinitionsProgressIndicator setIndeterminate:YES];
    [webUpdateDefinitionsProgressIndicator startAnimation:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(finishedDownload:) 
                                                 name:NSTaskDidTerminateNotification 
                                               object:nil];
}

- (void)finishedDownload:(NSNotification *)aNotification 
{
    [webUpdateDefinitionsButton setHidden:NO];
    [webUpdateDefinitionsProgressIndicator setHidden:YES];
    [webUpdateDefinitionsProgressIndicator stopAnimation:nil];
    [downloaderTask release]; 
    downloaderTask = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSTaskDidTerminateNotification
                                                  object:nil];
    [self loadDefinitions];
    
    [[NSNotificationCenter defaultCenter] postNotification:
        [NSNotification notificationWithName:@"RTKDefinitionsChanged" object:nil]];
}

// Font selection methods

static NSString * fontNameToChange = nil;
static NSString * fontSizeToChange = nil;

- (IBAction)changeFont:(id)sender
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    
    if(sender == [NSFontManager sharedFontManager]) {
        NSFont * font = [NSFont fontWithName:(NSString *)[d valueForKey:fontNameToChange]
                                        size:[(NSNumber *)[d valueForKey:fontSizeToChange] floatValue]];
        font = [sender convertFont:font];
        [d setValue:[font displayName] forKey:fontNameToChange];
        [d setValue:[NSNumber numberWithFloat:[font pointSize]] forKey:fontSizeToChange];
        [self updateUI];
        [[NSNotificationCenter defaultCenter] postNotification:
            [NSNotification notificationWithName:@"RTKFontsChanged" object:nil]];
        return;
    }  if(sender == committeeFontButton) {
        fontNameToChange = @"RTKCommitteeFontName";
        fontSizeToChange = @"RTKCommitteeFontSize";
    }  if(sender == scriptFontButton) {
        fontNameToChange = @"RTKScriptFontName";
        fontSizeToChange = @"RTKScriptFontSize";
    } else if(sender == romanFontButton) {
        fontNameToChange = @"RTKRomanFontName";
        fontSizeToChange = @"RTKRomanFontSize";
    } else if(sender == backTranslationFontButton) {
        fontNameToChange = @"RTKBackTranslationFontName";
        fontSizeToChange = @"RTKBackTranslationFontSize";
    } else if(sender == notesFontButton) {
        fontNameToChange = @"RTKNotesFontName";
        fontSizeToChange = @"RTKNotesFontSize";
    } else if(sender == checkingFontButton) {
        fontNameToChange = @"RTKCheckingFontName";
        fontSizeToChange = @"RTKCheckingFontSize";
    }
    
    [preferencesWindow makeFirstResponder:preferencesWindow];
    
    NSFont * font = [NSFont fontWithName:(NSString *)[d valueForKey:fontNameToChange]
                                    size:[(NSNumber *)[d valueForKey:fontSizeToChange] floatValue]];
    [[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (IBAction)convertorSwitched:(id)sender
{
    NSUserDefaults * d = [NSUserDefaults standardUserDefaults];
    int selectedRow = [sender selectedRow];
    
    if(selectedRow == 0) {
        [d setValue:@"No Transcription" forKey:@"RTKTranscriptionType"];
    } else if(selectedRow == 1) {
        [d setValue:@"External Transcription" forKey:@"RTKTranscriptionType"];
    } else if(selectedRow == 2) {
        [d setValue:@"RTK Transcription" forKey:@"RTKTranscriptionType"];
    }
    
    [[NSNotificationCenter defaultCenter] postNotification:
        [NSNotification notificationWithName:@"RTKTranscriptionTypeChanged" object:nil]];
}


@end

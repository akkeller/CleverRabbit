//
//  transliterate.m
//   (CleverRabbit.app)
//
//   Copyright (c) 2008 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//

#import <Cocoa/Cocoa.h>
#import "RTKConvertor.h"

// This is likely temporary, a nasty relic of the project
// that the transcription code was borrowed from
id RTKSharedConvertor = nil;
id RTKSharedDatabase = nil;
id RTKClass = @"RTKClass";

// Test flag
//BOOL generateMetaStrings = YES;
BOOL generateMetaStrings = NO;

int processArguments(int argc, char *argv[]) 
{
	NSMutableArray * arguments = [NSMutableArray new];
    int i = 0;
    while(argv[i] != nil) {
        [arguments addObject:[NSString stringWithCString:argv[i++]]];
    }
    
    if([arguments count] < 4) {
        NSLog(@"Not enough arguments.");
        return 0;
    }
    
    NSString *inputDefinitionPath = [arguments objectAtIndex:1];
    NSString *scriptDefinitionPath = [arguments objectAtIndex:2];
    NSString *encodingDefinitionPath = [arguments objectAtIndex:3];
    
 /*   NSLog([NSString stringWithFormat:@"\nInput Definition Path: %@\nScript Definition Path: %@\nEncoding Definition Path: %@",
           inputDefinitionPath, scriptDefinitionPath, encodingDefinitionPath]);
*/
    NSFileHandle *standardInput = [NSFileHandle fileHandleWithStandardInput];
    NSFileHandle *standardOutput = [NSFileHandle fileHandleWithStandardOutput];
    
    if(!RTKSharedConvertor)
        RTKSharedConvertor = [[RTKConvertor alloc] init];
    if(!RTKSharedDatabase)
        RTKSharedDatabase = [RTKSharedConvertor generalDatabase];
    
    while(1) {
        NSData *inputData = [standardInput availableData]; // TODO: Fix for buffer length. 
        if([inputData length] == 0)
            continue;

        NSString *inputString = [NSString stringWithCString:(const char *)[inputData bytes]  
                                                     length:[inputData length]];
        
        NSDictionary * output = [RTKSharedConvertor convertString:inputString
                                                      inputSystem:inputDefinitionPath
                                                     scriptSystem:scriptDefinitionPath
                                                       fontSystem:encodingDefinitionPath
                                                  withMetaStrings:generateMetaStrings
                                              checkForPunctuation:NO];
        
        if(generateMetaStrings)
            NSLog(@"%@", [output description]);
        
        NSString *outputString = [output objectForKey:@"RTKFont"];
        NSData *outputData = [NSData dataWithBytes:[outputString cString] 
                                            length:[outputString length]];
        [standardOutput writeData:outputData];
        [standardOutput writeData:[NSData dataWithBytes:"\n" length:1]]; 
    }
    
    return 0;	
}

int main(int argc, char *argv[])
{
    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    int result = processArguments(argc, argv);
    
    [pool release];
    
    return result;
}


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


int processArguments(int argc, char *argv[]) 
{
	NSMutableArray * arguments = [NSMutableArray new];
    int i = 0;
    while(argv[i] != nil) {
        [arguments addObject:[NSString stringWithCString:argv[i++]]];
    }
    
    NSString *inputDefinitionPath = [arguments objectAtIndex:
    
    NSFileHandle *standardInput = [NSFileHandle fileHandleWithStandardInput];
    NSFileHandle *standardOutput = [NSFileHandle fileHandleWithStandardOutput];
    
    RTKConvertor *convertor = [[RTKConvertor alloc] init];
    
    while(1) {
        NSData *inputData = [standardInput availableData];
        NSString *inputString = [NSString stringWithCString:(const char *)[inputData bytes]  
                                                     length:[inputData length]];
        
        NSString *outputString = [NSString stringWithString:inputString];
        NSData *outputData = [NSData dataWithBytes:[outputString cString] 
                                            length:[outputString length]];
        [standardOutput writeData:outputData];
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


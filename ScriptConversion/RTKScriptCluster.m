//
//  RTKScriptCluster.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKScriptCluster.h"
#import "RTKSyllableUnit.h"
#import "RTKIDDatabase.h"
#import "RTKLinkedListNode.h"
#import "RTKLinkedListHeader.h"
#import "RTKIDMarker.h"
#import "RTKScriptDefinition.h"
#import "RTKVowelDefinition.h"
#import "RTKConsonantDefinition.h"
#import "RTKContextualParsing.h"

@implementation RTKScriptCluster


-(id)initFromSyllableUnit:(RTKSyllableUnit *)sylUnit
                 position:(int)clusterPosition
    usingScriptDefinition:(RTKScriptDefinition *)def
		  usingIDDatabase:(RTKIDDatabase *)idDatabase
			defaultSeries:(const int)DEFAULTSERIES
			  firstSeries:(const int)FIRSTSERIES
			 secondSeries:(const int)SECONDSERIES
			  presyllable:(const int)PRESYLLABLE
      beginningOfSyllable:(const int)BEGINNINGOFSYLLABLE
            endOfSyllable:(const int)ENDOFSYLLABLE
          beginningOfWord:(const int)BEGINNINGOFWORD
                endOfWord:(const int)ENDOFWORD              
{
    if(self = [super init])
    {
		characterList = [[RTKLinkedListHeader alloc] init];
		{
			id tempVowel = [[RTKVowelDefinition alloc] initWithPhoneme:[sylUnit vowel]];
			id vowel;
            
			id tempConsonant = [[RTKConsonantDefinition alloc] initWithPhoneme:[sylUnit firstConsonant]];
			RTKConsonantDefinition *consonant = [[[[[def consonantTree] findNode:tempConsonant] instanceList] first] data];
			
			int baseConsonant = 0;
			int footConsonant = 0;
			int finalConsonant = 0;
			
			int series;
			int scriptVowel;
			
			[tempConsonant release];
			
			if([sylUnit type] == 0)
            {
				vowel = [[[[[def vowelTree] findNode:tempVowel] instanceList] first] data];
                
            }
			else 
            {
                // This code was useful for debugging the bug 
                // in which there were no <presyllableVowelList>
                // or </presyllableVowelList> defined
                
                //NSLog(@"using presyllableVowelTree");
                //[[def presyllableVowelTree] display];
                 //NSLog(@"trying to find vowel: %@", tempVowel);
                //NSLog(@"trying to find vowel: %@", [tempVowel display]);
				vowel = [[[[[def presyllableVowelTree] findNode:tempVowel] instanceList] first] data];
                
                //NSLog(@"using vowel %@", [vowel display]);
            }
			
			[tempVowel release];
			
			series = [vowel series];
			
			scriptVowel = [vowel character];
			
			if([sylUnit type] == PRESYLLABLE) {
				baseConsonant = [consonant presyllable];
			} else {
				if(series == 0)
					series = DEFAULTSERIES;
				
				if(series == FIRSTSERIES)
				{
					baseConsonant = [consonant firstSeriesMain];
				}
				else if(series == SECONDSERIES)
				{
					baseConsonant = [consonant secondSeriesMain];
				}
				else if(series == DEFAULTSERIES)
				{
					baseConsonant = [consonant defaultSeriesMain];
				}
			}
			
			tempConsonant = [[RTKConsonantDefinition alloc] initWithPhoneme:[sylUnit secondConsonant]];
			consonant = [[[[[def consonantTree] findNode:tempConsonant] instanceList] first] data];
			footConsonant = [consonant foot];
			[tempConsonant release];
			
			
			tempConsonant = [[RTKConsonantDefinition alloc] initWithPhoneme:[sylUnit finalConsonant]];
			consonant = [[[[[def consonantTree] findNode:tempConsonant] instanceList] first] data];
			[tempConsonant release];
			

			if([sylUnit type] == PRESYLLABLE)
			{
				finalConsonant = [consonant presyllableFinal];
			}
			else
			{
				finalConsonant = [consonant final];
			}
			
			{
				if(baseConsonant != 0)
				{
					
					RTKIDMarker *scriptChar = [[RTKIDMarker alloc] initWithIDNumber:baseConsonant];
                    [[RTKLinkedListNode alloc] initWithData:scriptChar
											   atBackOfList:characterList];
					[scriptChar release];
				}
				
				if(footConsonant != 0)
				{
					
					RTKIDMarker *scriptChar = [[RTKIDMarker alloc] initWithIDNumber:footConsonant];
					[[RTKLinkedListNode alloc] initWithData:scriptChar
											   atBackOfList:characterList];
					[scriptChar release];
				}
				
				if(scriptVowel != 0)
				{
					
					RTKIDMarker *scriptChar = [[RTKIDMarker alloc] initWithIDNumber:scriptVowel];
					[[RTKLinkedListNode alloc] initWithData:scriptChar
											   atBackOfList:characterList];
					[scriptChar release];
				}
				
				if(finalConsonant != 0)
				{
					
                    RTKIDMarker *scriptChar = [[RTKIDMarker alloc] initWithIDNumber:finalConsonant];
					
					[[RTKLinkedListNode alloc] initWithData:scriptChar
											   atBackOfList:characterList];
					[scriptChar release];
				}
			}
		}
        
        
        switch(clusterPosition)
        {
            RTKIDMarker *mark;
            case kOnlyCluster:
                mark = [[RTKIDMarker alloc] initWithIDNumber:BEGINNINGOFWORD];
                [[RTKLinkedListNode alloc] initWithData:mark
										  atFrontOfList:characterList];
                [mark release];
				
                mark = [[RTKIDMarker alloc] initWithIDNumber:ENDOFWORD];
                [[RTKLinkedListNode alloc] initWithData:mark
										   atBackOfList:characterList];
                [mark release];
                
                break;
            case kFirstCluster:
                mark = [[RTKIDMarker alloc] initWithIDNumber:BEGINNINGOFWORD];
                [[RTKLinkedListNode alloc] initWithData:mark
										  atFrontOfList:characterList];
                [mark release];
				
                mark = [[RTKIDMarker alloc] initWithIDNumber:ENDOFSYLLABLE];
                [[RTKLinkedListNode alloc] initWithData:mark
										   atBackOfList:characterList];
                [mark release];
                
                break;
            case kLastCluster:
                mark = [[RTKIDMarker alloc] initWithIDNumber:BEGINNINGOFSYLLABLE];
                [[RTKLinkedListNode alloc] initWithData:mark
										  atFrontOfList:characterList];
                [mark release];
				
                mark = [[RTKIDMarker alloc] initWithIDNumber:ENDOFWORD];
                [[RTKLinkedListNode alloc] initWithData:mark
										   atBackOfList:characterList];
                [mark release];
                break;
            case kInternalCluster:
                mark = [[RTKIDMarker alloc] initWithIDNumber:BEGINNINGOFSYLLABLE];
                [[RTKLinkedListNode alloc] initWithData:mark
										  atFrontOfList:characterList];
                [mark release];
				
                mark = [[RTKIDMarker alloc] initWithIDNumber:ENDOFSYLLABLE];
                [[RTKLinkedListNode alloc] initWithData:mark
										   atBackOfList:characterList];
                [mark release];
                break;
        }
        [RTKContextualParsing parse:characterList with:[def filterList] testing:NO];
    }
    return self;
}


- (void)dealloc
{
    [characterList release];
    [super dealloc];
}


-(void)display
{
    NSLog(@"RTKScriptCluster");
    [characterList display];
}


-(RTKLinkedListHeader *)characterList
{
    return characterList;
}


@end

//
//  RTKScriptPunctuationGroup.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKScriptPunctuationGroup.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKPunctuationGroupUnit.h"
#import "RTKIDMarker.h"
#import "RTKPunctuationUnit.h"


@implementation RTKScriptPunctuationGroup


-(id)initFromPunctuationList:(RTKLinkedListHeader *)list
{
    if(self = [super init])
    {
        punctuationList = [[RTKLinkedListHeader alloc] init];
        {
            RTKLinkedListNode *currentPuncNode = [list first];
            while(currentPuncNode != nil)
            {
                RTKPunctuationUnit *currentPunc = [currentPuncNode data];
                
                RTKIDMarker *punc = [[RTKIDMarker alloc] initWithIDNumber:[currentPunc idNumber]];

                [[RTKLinkedListNode alloc] initWithData:punc
                            atBackOfList:punctuationList];
                [currentPunc release];
                
                currentPuncNode = [currentPuncNode next];
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [punctuationList release];
    [super dealloc];
}

-(void)display
{
    NSLog(@"ScriptPunctuation");
    [punctuationList display];
}

-(RTKLinkedListHeader *)punctuationList
{
    return punctuationList;
}

@end

//
//  RTKScriptWord.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKScriptWord.h"
#import "RTKLinkedListHeader.h"
#import "RTKLinkedListNode.h"
#import "RTKSyllableUnit.h"
#import "RTKScriptCluster.h"
#import "RTKScriptDefinition.h"
#import "RTKIDDatabase.h"


@implementation RTKScriptWord


-(id)initFromSyllableList:(RTKLinkedListHeader *)list
    usingScriptDefinition:(RTKScriptDefinition *)scriptDef
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
        clusterList = [[RTKLinkedListHeader alloc] init];
        {
            RTKLinkedListNode *currentSyllableNode = [list first];
            
            int clusterPosition = ([clusterList count] == 1 ? kOnlyCluster : kFirstCluster);
            while(currentSyllableNode != nil)
            {
                RTKSyllableUnit *currentSyllable = [currentSyllableNode data];
                RTKScriptCluster *cluster;
                
                
                cluster = [[RTKScriptCluster alloc] initFromSyllableUnit:currentSyllable
                                                                position:clusterPosition
                                                   usingScriptDefinition:scriptDef
                                                         usingIDDatabase:idDatabase
                                                           defaultSeries:DEFAULTSERIES
                                                             firstSeries:FIRSTSERIES
                                                            secondSeries:SECONDSERIES
                                                             presyllable:PRESYLLABLE
                                                     beginningOfSyllable:BEGINNINGOFSYLLABLE
                                                           endOfSyllable:ENDOFSYLLABLE
                                                         beginningOfWord:BEGINNINGOFWORD
                                                               endOfWord:ENDOFWORD];
																
                [[RTKLinkedListNode alloc] initWithData:cluster
                                           atBackOfList:clusterList];
                [cluster release];
                
                currentSyllableNode = [currentSyllableNode next];
                
                clusterPosition = ([currentSyllableNode next] == nil ? kLastCluster : kInternalCluster);
            }
        }
    }
    return self;
}


- (void)dealloc
{
    [clusterList release];
    [super dealloc];
}


-(void)display
{
    NSLog(@"RTKScriptWord");
    [clusterList display];
}


-(RTKLinkedListHeader *)clusterList
{
    return clusterList;
}

@end

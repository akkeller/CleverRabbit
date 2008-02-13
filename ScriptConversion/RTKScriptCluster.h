//
//  RTKScriptCluster.h
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import <Foundation/Foundation.h>
#import "RTKLinkedListHeader.h"
#import "RTKSyllableUnit.h"
#import "RTKScriptDefinition.h"
#import "RTKIDDatabase.h"


@interface RTKScriptCluster : NSObject 
{
    RTKLinkedListHeader *characterList;
}

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
                endOfWord:(const int)ENDOFWORD;
-(void)display;
-(RTKLinkedListHeader *)characterList;

@end

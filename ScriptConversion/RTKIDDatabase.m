//
//  RTKIDDatabase.m
//   (RomanToKhmer.app)
//
//   Copyright (c) 2002-2005 A. Karl Keller (http://karlk.net)
//
//   This code is open-source, free software, made available without warranty under
//   the terms of the GNU General Public License, either version 2 or later (see 
//   http://www.gnu.org/licenses/gpl.html or included copy); as such, it may be 
//   redistributed and/or modified in accordance with that document.
//




#import "RTKIDDatabase.h"
#import "RTKConvertor.h"

@implementation RTKIDDatabase

-(id)init
{
    if(self = [super init])
    {
		nextIDNumber = 1;  // Starts counting at 1 
						   // any with ID 0 haven't gotten a correct value
		dictByString = [[NSMutableDictionary alloc] init];
		dictByNumber = [[NSMutableDictionary alloc] init];
	}
    return self;
}

-(void)dealloc
{
	[dictByString release];
	[dictByNumber release];
    [super dealloc];
}


-(int)idForString:(NSString *)theString
{
	int idNumber;
    if([theString isKindOfClass:[NSString class]])
    {
        if([theString length] == 0)
        {
            return 0;
        }
        else
        {
			idNumber = [[dictByString objectForKey:theString] intValue];
			if(idNumber)
			{
				return idNumber;
			}
			else 
			{
				[dictByString setObject:[[[NSNumber alloc] initWithInt:nextIDNumber] retain] forKey:theString];
				[dictByNumber setObject:[theString retain] forKey:[[[NSNumber alloc] initWithInt:nextIDNumber] retain]] ;
				return nextIDNumber++;
			}
        }
    }
    return 0;
}



-(int)lookupIDNumber:(RTKLinkedListHeader *)charList
{	int number;
	NSMutableString * str = [[NSMutableString alloc] init];
	RTKLinkedListNode * node = [charList first];
	
	[charList retain]; // prevents bad access during popautoreleasepool
	
	do
	{
		unichar character = [[node data] character];
		[str appendString:[NSString stringWithCharacters:&character length:1]];
	}while(node = [node next]);
	
	number = [[dictByString objectForKey:str] intValue];
		
	if(number == 0)
	{
			[dictByString setObject:[[NSNumber alloc] initWithInt:nextIDNumber] forKey:str];
			[dictByNumber setObject:str forKey:[[NSNumber alloc] initWithInt:nextIDNumber]];
			return nextIDNumber++;
	}
	return number;
}


-(NSString *)stringForID:(int)idNumber
{
	id str = [dictByNumber objectForKey:[[NSNumber alloc] initWithInt:idNumber]];
	if(str)
		return str;
	else
		return [NSString stringWithString:@""];
}

-(void)display
{
    NSLog(@"RTKIDDatabase -- nextIDNumber: %i", nextIDNumber);
}

@end

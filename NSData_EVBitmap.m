#import "NSData_EVBitmap.h"

@implementation NSData (EVBitmap)

- (int)colorCount{
	NSMutableArray *colorCounter = [[NSMutableArray alloc] init];
	NSUInteger i;
	NSUInteger offset = 0x36;
	NSUInteger colorsUsed = 0;
	NSUInteger length = [self length];
	for(i = 0; i < length; i++){
		if(offset < length-3){
			NSData *subData = [NSData data];
			subData = [self subdataWithRange:NSMakeRange(offset, 3)];
			if(![colorCounter containsObject:subData]){
				[colorCounter addObject:subData];
				colorsUsed++;
			}
			offset += 3;
		}
	}
	[colorCounter release];
	return colorsUsed;
}

@end

#import "HexColorAdditions.h"

@implementation NSColor (HexColorAdditions)

- (NSString *)hexString{
	return([NSString stringWithFormat:@"%02X%02X%02X",
								(int)([self redComponent] * 255.0),
								(int)([self greenComponent] * 255.0),
								(int)([self blueComponent] * 255.0)]
	);
}

@end

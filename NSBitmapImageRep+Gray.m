// Heinrich Giesen
#import "NSBitmapImageRep+Gray.h"
#import	"HexColorAdditions.h"

@implementation NSBitmapImageRep(Gray)

- (NSBitmapImageRep *) grayRepresentation{
	NSSize origSize = [self size];
	// create a new representation
	NSBitmapImageRep *newRep =
	[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
											pixelsWide:[self pixelsWide]
											pixelsHigh:[self pixelsHigh]
										 bitsPerSample:8
									   samplesPerPixel:1
											  hasAlpha:NO  // not allowed !
											  isPlanar:NO
										colorSpaceName:NSCalibratedWhiteColorSpace
										   bytesPerRow:0
										  bitsPerPixel:0];
	// this new imagerep has (as default) a resolution of 72 dpi
	[NSGraphicsContext saveGraphicsState];
	NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:newRep];
	[NSGraphicsContext setCurrentContext:context];
	[self drawInRect:NSMakeRect(0, 0, [newRep pixelsWide], [newRep pixelsHigh])];
	[NSGraphicsContext restoreGraphicsState];
	[newRep setSize:origSize];
	return [newRep autorelease];
}

- (NSUInteger) colorCount{
	NSMutableArray *colorCounter = [[[NSMutableArray alloc] init] autorelease];
	NSInteger colorsUsed = 0;
	NSUInteger x = 0;
	NSUInteger y = 0;
	NSInteger width = [self pixelsWide];
	NSInteger height = [self pixelsHigh];
	for(x = 0; x <= width; x++){
		for(y = 0; y <= height; y++){
			if(![colorCounter containsObject: [self colorAtX:x y:y]]){
				if([self colorAtX:x y:y]){
					[colorCounter addObject: [self colorAtX:x y:y]];
					colorsUsed++;
				}
			}
		}
	}
	return colorsUsed;
}

- (void) generatePalette:(NSString *)palette filename:(NSString *)filename;{
	NSInteger realWidth  = [self pixelsWide];
	NSInteger realHeight = [self pixelsHigh];

	NSMutableArray *colorCounter = [NSMutableArray array];
	NSInteger x = 0;
	NSInteger y = 0;
	NSInteger colorsUsed = 0;
	NSUInteger b = 0;
	NSUInteger g = 0;
	NSUInteger r = 0;
	NSUInteger bgrColor = 0;
	NSString *outputString = [NSString string];
	NSString *outputHTML = [NSString string];
	NSMutableData *output = [NSMutableData data];
	for(y = 0; y < realHeight; y++){
		for(x = 0; x < realWidth; x++){
			if(![colorCounter containsObject:[self colorAtX:x y:y]]){
				if([self colorAtX:x y:y]){
					b = (int)([[self colorAtX:x y:y] blueComponent]*255);
					g = (int)([[self colorAtX:x y:y] greenComponent]*255);
					r = (int)([[self colorAtX:x y:y] redComponent]*255);
					// convert from 8-bit RGB to 5-bit BGR
					bgrColor = (((b >> 3) << 10) | ((g >> 3) << 5) | (r >> 3));
					if([palette isEqualToString:@"asm"]){
						if(colorsUsed % 4 == 0){
							if(colorsUsed == 0){
								outputString = [outputString stringByAppendingString:@"; Palette\n.db "];
							}
							else{
								outputString = [outputString stringByAppendingFormat:@"; %@\n.db ", outputHTML];
								outputHTML = [NSString stringWithString:@""];
							}
						}
						outputString = [outputString stringByAppendingFormat:@"$%02X, $%02X ", (bgrColor & 0xFF), (bgrColor >> 8)];
						outputHTML = [outputHTML stringByAppendingFormat:@"#%@ ",[[self colorAtX:x y:y] hexString]];
					}
					else{
						NSUInteger bgrColorLow = (bgrColor & 0xFF);
						NSUInteger bgrColorHigh = (bgrColor >> 8);
						[output appendBytes:&bgrColorLow length:1];
						[output appendBytes:&bgrColorHigh length:1];
					}
					[colorCounter addObject:[self colorAtX:x y:y]];
					colorsUsed++;
				}
			}
		}
	}
	if([palette isEqualToString:@"asm"]){
		outputString = [outputString stringByAppendingFormat:@"; %@\n", outputHTML];
		[outputString writeToFile:[NSString stringWithFormat:@"%@.h",filename] atomically:TRUE encoding:NSUTF8StringEncoding error:nil];
	}
	else{
		[output writeToFile:[NSString stringWithFormat:@"%@.clr",filename] atomically:TRUE];
	}

	return;
}

@end

#import <Cocoa/Cocoa.h>
#import "NSBitmapImageRep+Gray.h"
#import "HexColorAdditions.h"
#import "main.h"

int main(int argc, const char * argv[]){
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
	NSString* fileName = [NSString stringWithFormat:@"%@/%@", [[NSFileManager defaultManager] currentDirectoryPath], [args stringForKey:@"f"]];
	NSImage *sourceImage = [[[NSImage alloc] initWithContentsOfFile:fileName] autorelease];
	if(![sourceImage isValid]){
		printf("Error: Invalid Image! See below for usage.\n\n");
		printf("snesimg v0.2 - Convert images to SNES Format with Palette\n");
		printf("By Matthew Callis eludevisibility.org / superfamicom.org\n");
		printf("=========================================================\n");
		printf("-f	string		input filename can be anyone one of:\n");
		printf("			TIFF, BMP, JPEG, GIF, PNG, ICO\n");
		printf("			PSD, XBM, CUR, TGA, PICT, EPS\n");
		printf("-c	asm/-		the format of the palette\n");
		printf("			asm outputs in '.db $##, $##' format\n");
		printf("			otherwise it defaults to raw .clr format\n");
		printf("-pf	string		palette filename\n");
		printf("			if none it defaults to the input filename\n");
		printf("-w	int		overide width of image\n");
		printf("-h	int		overide height of image\n");
		printf("-d	YES/NO		verbose information printed on screen\n\n");
		printf("Example: snesimg -f sprite-32x32.png -w 128 -h 32 -c asm\n");
	}
	else{
		NSString *fileNameOnly = [[args stringForKey:@"f"] stringByDeletingPathExtension];
		NSString *paletteFormat = ([args stringForKey:@"c"] ? [args stringForKey:@"c"] : @"raw");
		BOOL debug = [args boolForKey:@"d"];

		NSUInteger z = 0;
		NSUInteger x = 0;
		NSUInteger y = 0;
		NSUInteger px = 0;
		NSUInteger py = 0;

		NSBitmapImageRep *bitmapData = [[sourceImage representations] objectAtIndex:0];
		NSInteger width  = ([args integerForKey:@"w"] ? [args integerForKey:@"w"] : [bitmapData pixelsWide]);
		NSInteger height = ([args integerForKey:@"h"] ? [args integerForKey:@"h"] : [bitmapData pixelsHigh]);
		NSInteger realWidth  = [bitmapData pixelsWide];
		NSInteger realHeight = [bitmapData pixelsHigh];

		// If not a multiple of 8, make it one for later
		height = ((height % 8) == 0) ? height : (height + (height % 8));

		// Built and save the palette as requested
		[bitmapData generatePalette:paletteFormat filename:fileNameOnly];

		unsigned char buffer[512*512];
		unsigned char output[512*512];
		if(debug){
			NSLog(@"Working on %@...",fileNameOnly);
			NSLog(@"Size:  %d px wide", width);
			NSLog(@"Size:  %d px high", height);
			NSLog(@"Bits:  %d bpp", [bitmapData bitsPerSample]);
			NSLog(@"Bytes: %d", [bitmapData samplesPerPixel]);
			NSLog(@"Color Space: %@", [bitmapData colorSpace]);
			NSLog(@"Colors: %d", [bitmapData colorCount]);
		}

		NSBitmapImageRep *grayData = [bitmapData grayRepresentation];
		NSData *grayImage = [grayData TIFFRepresentation];
		if(debug) [grayImage writeToFile:[NSString stringWithFormat:@"%@.tif",fileName] atomically:TRUE];

		NSBitmapImageRep *brep = [[NSBitmapImageRep alloc] initWithData:[[NSData alloc] initWithData:grayImage]];
//		NSData *crap = [NSData alloc];
//		crap = [brep representationUsingType:NSBMPFileType properties:nil];
//		const unsigned char *displayImage = [crap bytes];
		const unsigned char *displayImage = [[brep representationUsingType:NSBMPFileType properties:nil] bytes];

		NSMutableDictionary *colorIndex = [NSMutableDictionary dictionary];
		NSMutableArray *colorCounter = [NSMutableArray array];
		NSInteger colorsUsed = 0;
		NSUInteger offset = 0x36;
		NSNumber *na = nil;
		NSNumber *nb = nil;
		unsigned char colorByte;
		unsigned char colorValue;
		for(y = 0; y < realHeight; y++){
			for(x = 0; x < realWidth; x++){
				colorByte = displayImage[offset];
				na = [NSNumber numberWithInteger: colorsUsed];
				nb = [NSNumber numberWithUnsignedChar: colorByte];
				if(![colorCounter containsObject:[brep colorAtX:x y:y]]){
					if([brep colorAtX:x y:y]){
						if(debug) NSLog(@"Color %d: %@", colorsUsed, [[brep colorAtX:x y:y] hexString]);
						[colorCounter addObject:[brep colorAtX:x y:y]];
						[colorIndex setObject:na forKey:nb];
						colorValue = colorsUsed;
						colorsUsed++;
					}
				}
				else{
					colorValue = [[colorIndex objectForKey:nb] unsignedCharValue];
				}
				buffer[y * width + x] = colorValue;
				offset+=3;
			}
		}
		[brep release];

		for(y = 0; y < height; y += 8){
			for(x = 0; x < width; x += 8){
				for(py = 0; py < 8; py++){
					for(px = 0; px < 8; px++){
						unsigned char color = buffer[(y + py) * width + (x + px)];
						unsigned char mask = 0x80 >> px;
						output[z +  0] |= (color & 1) ? mask : 0;
						output[z +  1] |= (color & 2) ? mask : 0;
						output[z + 16] |= (color & 4) ? mask : 0;
						output[z + 17] |= (color & 8) ? mask : 0;
					}
					z += 2;
				}
				z += 16;
			}
		}
		NSData *snesData = [[NSData alloc] init];
		[snesData initWithBytesNoCopy:output length:(width*height)];
		[snesData writeToFile:[NSString stringWithFormat:@"%@.pic",fileNameOnly] atomically:TRUE];
	}
	[pool release];
	return 0;
}

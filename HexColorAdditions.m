#import "HexColorAdditions.h"

// Convert hex to an int
int hexToInt(char hex){
	if(hex >= '0' && hex <= '9')		return (hex - '0');
	else if(hex >= 'a' && hex <= 'f')	return (hex - 'a' + 10);
	else if(hex >= 'A' && hex <= 'F')	return (hex - 'A' + 10);
    else								return (0);
}

// Convert int to a hex
char intToHex(int digit){
	if(digit > 9)	return('a' + digit - 10);
	else			return('0' + digit);
}

@implementation NSString (HexColorAdditions)

- (NSColor *)hexColor{
	const char	*hexString = [self UTF8String];
	float		red, green, blue;
	
	if(hexString[0] == '#'){
		red = ( hexToInt(hexString[1]) * 16 + hexToInt(hexString[2]) ) / 255.0;
		green = ( hexToInt(hexString[3]) * 16 + hexToInt(hexString[4]) ) / 255.0;
		blue = ( hexToInt(hexString[5]) * 16 + hexToInt(hexString[6]) ) / 255.0;
	}
	else{
		red = ( hexToInt(hexString[0]) * 16 + hexToInt(hexString[1]) ) / 255.0;
		green = ( hexToInt(hexString[2]) * 16 + hexToInt(hexString[3]) ) / 255.0;
		blue = ( hexToInt(hexString[4]) * 16 + hexToInt(hexString[5]) ) / 255.0;
	}
	return([NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1.0]);
}

@end

@implementation NSColor (HexColorAdditions)

- (NSString *)hexString{
	float 	red,green,blue;
	char	hexString[7];
	int		tempNum;
	NSColor	*convertedColor;
	
	convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[convertedColor getRed:&red green:&green blue:&blue alpha:nil];
	
	tempNum = (red * 255) / 16;
	hexString[0] = intToHex(tempNum);
	hexString[1] = intToHex((red * 255) - (tempNum * 16));
	
	tempNum = (green * 255) / 16;
	hexString[2] = intToHex(tempNum);
	hexString[3] = intToHex((green * 255) - (tempNum * 16));
	
	tempNum = (blue * 255) / 16;
	hexString[4] = intToHex(tempNum);
	hexString[5] = intToHex((blue * 255) - (tempNum * 16));
	hexString[6] = '\0';
	
    return([NSString stringWithCString:hexString encoding:NSUTF8StringEncoding]);
}

- (NSData *)hexData{
	NSColor	*tempColor = [self colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"];
	NSData *myData = [[NSData alloc] init];
	char hexChar[3];
	
	hexChar[0] = (int)([tempColor redComponent] * 255.0);
	hexChar[1] = (int)([tempColor greenComponent] * 255.0);
	hexChar[2] = (int)([tempColor blueComponent] * 255.0);
	
	[myData initWithBytes:hexChar length:3];
	
	return [myData autorelease];
}

- (NSString *)stringRepresentation{
	NSColor	*tempColor = [self colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"];
	
	return(
		   [NSString stringWithFormat:@"%x,%x,%x",
			(int)([tempColor redComponent] * 255.0),
			(int)([tempColor greenComponent] * 255.0),
			(int)([tempColor blueComponent] * 255.0)]
		   );
}

NSColor *NSColorToGrayScale(NSColor *aColor){
#define RGB_TO_GRAYSCALE(R,G,B) (CGFloat)(0.29900f * (R) + 0.58700f * (G) + 0.11400f * (B))
	CGFloat grayScale = RGB_TO_GRAYSCALE([aColor redComponent], [aColor greenComponent], [aColor blueComponent]);
	return [NSColor colorWithDeviceWhite:grayScale alpha:1.0];
}

NSColor *NSColorToFakeComplementaryColor(NSColor *aColor){
	CGFloat r,g,b;
	r = 0.9999 - [aColor redComponent];
	g = 0.9999 - [aColor greenComponent];
	b = 0.9999 - [aColor blueComponent];
	return [NSColor colorWithDeviceRed:r green:g blue:b alpha:1.0];
}

CGFloat NSRandomFloatBetween(CGFloat low, CGFloat high){
	CGFloat swap;
	if(low > high){
		swap = low;
		low = high;
		high = swap;
	}
	return (CGFloat)(rand() / (CGFloat)(RAND_MAX)) * (high - low) + low;
}

NSColor *NSReadPixelsAverage(NSBitmapImageRep *bitmapImageRep){
	if(bitmapImageRep){
		NSInteger i = 0;
		NSInteger r = 0, g = 0, b = 0;
		unsigned char *data = [bitmapImageRep bitmapData];
		NSInteger n = ([bitmapImageRep size].width *[bitmapImageRep size].height);
		
		do{
			r += *data++; 
			g += *data++; 
			b += *data++;
		} while (++i < n);
		
		CGFloat red = (CGFloat)r / n / 256;
		CGFloat green = (CGFloat)g / n / 256;
		CGFloat blue = (CGFloat)b / n / 256;
		
		return [NSColor colorWithDeviceRed:red green:green blue:blue alpha:1.0];
	}
	return nil;
}

NSColor *NSReadPixelsAverageForRect(NSRect aRect){
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:aRect];
	
	NSColor *average = NSReadPixelsAverage(imageRep);
	[imageRep release];
	
	return average;
}

@end
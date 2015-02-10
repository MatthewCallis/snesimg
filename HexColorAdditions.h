
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface NSString (HexColorAdditions)

- (NSColor *)hexColor;

@end

@interface NSColor (HexColorAdditions)

- (NSData *)hexData;
- (NSString *)hexString;
- (NSString *)stringRepresentation;

@end

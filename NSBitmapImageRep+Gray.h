#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>

@interface NSBitmapImageRep(Gray)

- (NSBitmapImageRep *) grayRepresentation;
- (NSUInteger) colorCount;
- (void) generatePalette:(NSString *)palette filename:(NSString *)filename;

@end

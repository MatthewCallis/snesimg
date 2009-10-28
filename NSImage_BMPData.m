//  NSImage_BMPData.m
//  Florent Pillet, Code Segment 
//
//  Created by Florent Pillet, Code Segment on Wed Oct 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSImage_BMPData.h"
#import <QuickTime/QuickTime.h>

@implementation NSImage(BMPData)

Handle myCreateHandleDataRef(Handle dataHandle, Str255 fileName, OSType fileType, StringPtr mimeTypeString, Ptr initDataPtr, Size initDataByteCount){
	OSErr err;	
	Handle dataRef = nil;
	Str31 tempName;
	long atoms[3];
	StringPtr name;

	// First create a data reference handle for our data
	err = PtrToHand( &dataHandle, &dataRef, sizeof(Handle));

	if(err) goto bail;

	// If this is QuickTime 3 or later, we can add
	// the filename to the data ref to help importer finding process. Find uses the extension.

	name = fileName;
	if(name == nil){
		tempName[0] = 0;
		name = tempName;
    }

	// Only add the file name if we are also adding a
	// file type, MIME type or initialization data

	if((fileType) || (mimeTypeString) || (initDataPtr)){
		err = PtrAndHand(name, dataRef, name[0]+1);
		if (err) goto bail;
	}

	// If this is QuickTime 4, the handle data handler
	// can also be told the filetype and/or
	// MIME type by adding data ref extensions. These
	// help the importer finding process.
	// NOTE: If you add either of these, you MUST add
	// a filename first -- even if it is an empty Pascal
	// string. Under QuickTime 3, any data ref extensions
	// will be ignored.
	// to add file type, you add a classic atom followed
	// by the Mac OS filetype for the kind of file
	if(fileType){
		atoms[0] = EndianU32_NtoB(sizeof(long) * 3);
		atoms[1] = EndianU32_NtoB(kDataRefExtensionMacOSFileType);
		atoms[2] = EndianU32_NtoB(fileType);
		err = PtrAndHand(atoms, dataRef, sizeof(long) * 3);
		if(err) goto bail;
	}

	// to add MIME type information, add a classic atom followed by
	// a Pascal string holding the MIME type
	if(mimeTypeString){
		atoms[0] = EndianU32_NtoB(sizeof(long) * 2 + mimeTypeString[0]+1);
		atoms[1] = EndianU32_NtoB(kDataRefExtensionMIMEType);
		err = PtrAndHand(atoms, dataRef, sizeof(long) * 2);
		if (err) goto bail;
		err = PtrAndHand(mimeTypeString, dataRef, mimeTypeString[0]+1);
		if (err) goto bail;
	}

	// add any initialization data, but only if a dataHandle was
	// not already specified (any initialization data is ignored
	// in this case)
	if((dataHandle == nil) && (initDataPtr)){
		atoms[0] = EndianU32_NtoB(sizeof(long) * 2 + initDataByteCount);
		atoms[1] = EndianU32_NtoB(kDataRefExtensionInitializationData);
		err = PtrAndHand(atoms, dataRef, sizeof(long) * 2);
		if (err) goto bail;
		err = PtrAndHand(initDataPtr, dataRef, initDataByteCount);
		if (err) goto bail;
	}
	return dataRef;

	bail:
	if(dataRef){
		// make sure and dispose the data reference handle once we are done with it
		DisposeHandle(dataRef);
	}
	return nil;
}

- (NSData *)BMPData{
	NSSize size = [self size];
	NSRect r = NSMakeRect(0,0,size.width,size.height);

	[self lockFocus];

	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:r];
	[self unlockFocus];
	NSData *bmpData = [rep representationUsingType:NSBMPFileType properties:nil];
	if(bmpData == nil){
		// no joy. there's a bug in the OS which doesn't generate BMP data (all other types are supported, though). Use QuickTime to generate the bmp data.
		NSData *pngData = [rep representationUsingType:NSPNGFileType properties:nil];
		if([pngData length] == 0){
			NSLog(@"Can't export bitmap data to BMP");
			[rep release];
			return nil;
        }

		// create a data reference handle for quicktime (see TN 1195 for myCreateHandleDataRef source)
		Handle pngDataH = NULL;
		PtrToHand([pngData bytes], &pngDataH, [pngData length]);
		Handle dataRef = myCreateHandleDataRef(pngDataH, "\pdummy.png", kQTFileTypePNG, nil, nil, 0);

		// create a Graphics Importer component that will read from the PNG data
		ComponentInstance importComponent=0, exportComponent=0;
		OSErr err = GetGraphicsImporterForDataRef(dataRef, HandleDataHandlerSubType, &importComponent);
		DisposeHandle(dataRef);
		if(err == noErr){
			// create a Graphics Exporter component that will write BMP data
			err = OpenADefaultComponent(GraphicsExporterComponentType, kQTFileTypeBMP, &exportComponent);
			if(err == noErr){
				// set export parameters
				Handle bmpDataH = NewHandle(0);
				GraphicsExportSetInputGraphicsImporter(exportComponent, importComponent);
				GraphicsExportSetOutputHandle(exportComponent, bmpDataH);
				// export data to BMP into handle
				unsigned long actualSizeWritten = 0;
				err = GraphicsExportDoExport(exportComponent, &actualSizeWritten);
				if(err == noErr){
					// export done: create the NSData that will be returned
					HLock(bmpDataH);
					bmpData = [NSData dataWithBytes:*bmpDataH length:GetHandleSize(bmpDataH)];
					HUnlock(bmpDataH);
				}
				DisposeHandle(bmpDataH);
				CloseComponent(exportComponent);
			}
			CloseComponent(importComponent);
		}
		DisposeHandle(pngDataH);
	}
	[rep release];
	return bmpData;
}

@end

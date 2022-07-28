//
//  CameraExtensionConnector.cpp
//  CameraTest
//
//  Created by Mark Bessey on 7/26/22.
//

#include "CameraExtensionConnector.h"

typedef NSArray<NSNumber*>* NumberArray;

@interface CameraExtensionConnector() {
	CMSimpleQueueRef _queue;
}
@property(readwrite) CMSimpleQueueRef queue;
@end

@implementation CameraExtensionConnector
NSArray<NSNumber*>* getDeviceIDs(void);
NSString* getStringValue(CMIODeviceID id,
						 CMIOObjectPropertySelector selector);
NSArray<NSNumber*>* getArrayValue(CMIODeviceID id,
								  CMIOObjectPropertySelector selector);
void getPointerValue(CMIODeviceID id,
					  CMIOObjectPropertySelector selector, void** dest);
UInt32 getIntValue(CMIODeviceID id,
			CMIOObjectPropertySelector selector);
OSStatus startSinkStream(void);

- (CMIODeviceID) getCameraID: (NSString *) name {
	CMIODeviceID cameraID = 0;
	NumberArray devices = getDeviceIDs();
	for (NSNumber* id in devices) {
		NSString *name = getStringValue(id.unsignedIntValue,
										kCMIOObjectPropertyName);
		if (name != NULL) {
			// check it here
			if ([name isEqualToString:@"Sample Camera"]) {
				cameraID = id.unsignedIntValue;
			}
		}
	}
	return cameraID;
}

-(CMIOStreamID) getSinkStreamID: (CMIODeviceID)device {
	NumberArray streams = getArrayValue(device, kCMIODevicePropertyStreams);
	CMIOStreamID streamID = 0;
	for (NSNumber* id in streams) {
		UInt32 direction = getIntValue(id.unsignedIntValue, kCMIOStreamPropertyDirection);
		if (direction == 0) { // output stream
			// ignore the output stream - it's the camera
			NSLog(@"Ignoring output stream %@", id);
		} else if (direction == 1) { // input stream
			streamID = id.unsignedIntValue;
		} else { // not valid
			streamID = -1;
		}
	}
	return streamID;
}

void queueAlteredProc(CMIOStreamID streamID, void* token, void* refCon) {
	// okay, a buffer has been processed. Now what?
	CameraExtensionConnector* connector = (__bridge CameraExtensionConnector*)refCon;
	if (connector == nil) {
		NSLog(@"Oops, no self pointer.");
		return;
	}
	int32_t count = CMSimpleQueueGetCount(connector.queue);
	int32_t capacity = CMSimpleQueueGetCapacity(connector.queue);
	if (count >= capacity) {
		NSLog(@"queue stalled");
		return;
	}
}

- (OSStatus) startSinkStream {
	int width = 1920;
	int height = 1080;
	CMIODeviceID device = [self getCameraID: @"Sample Camera"];
	CMIOStreamID stream = [self getSinkStreamID: device];
	CMFormatDescriptionRef formatDescription;
	CMVideoFormatDescriptionCreate(NULL, kCVPixelFormatType_32BGRA, width, height, NULL, &formatDescription);
	NSDictionary* pixelBufferAttributes = @{
		(NSString*)kCVPixelBufferWidthKey: [NSNumber numberWithInt: width],
		(NSString*)kCVPixelBufferHeightKey: [NSNumber numberWithInt: height],
		(NSString*)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:CMFormatDescriptionGetMediaSubType(formatDescription)],
		(NSString*)kCVPixelBufferIOSurfacePropertiesKey: @{},
	};
	CVPixelBufferPoolRef pool;
	CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes), &pool);
	OSStatus result = CMIOStreamCopyBufferQueue(stream, queueAlteredProc, (__bridge void *)(self)/*refCon*/, &_queue);
	if (result != 0) {
		NSLog(@"Failed to get queue.");
	}
	CMIODeviceStartStream(device, stream);
	return 0;
}

- (void) send:(CMSampleBufferRef)buffer {
	OSStatus result = CMSimpleQueueEnqueue(_queue, buffer);
	if (result == kCMSimpleQueueError_QueueIsFull) {
		NSLog(@"queue is full.");
	} else if (result != noErr) {
		NSLog(@"failed to enqueue, error = %d", result);
	}
}
OSStatus stopSinkStream(CMIOStreamID stream) {
	return 0;
}

NSString* getStringValue(CMIODeviceID id,
						 CMIOObjectPropertySelector selector) {
	CFStringRef name;
	getPointerValue(id, selector, (void**)&name);
	NSString* str;
	if (name != NULL) {
		str = [(NSString*)CFBridgingRelease(name) copy];
	} else {
		str = NULL;
	}
	return str;
}

UInt32 getIntValue(CMIODeviceID id,
				   CMIOObjectPropertySelector selector) {
	UInt32 value;
	UInt32 usedSpace = 0;
	CMIOObjectPropertyScope scope = kCMIOObjectPropertyScopeGlobal;
	CMIOObjectPropertyAddress address = {
		selector,
		scope,
		0 // Element
	};
	if (!CMIOObjectHasProperty(id, &address)) {
		value = 0;
	}
	OSStatus result = CMIOObjectGetPropertyData(id, &address, 0, nil, sizeof(UInt32), &usedSpace, &value);
	if (result != kCMIOHardwareNoError) {
		NSLog(@"uh, oh");
		value = 0;
	}
	return value;
}


void getPointerValue(CMIODeviceID id,
					  CMIOObjectPropertySelector selector, void** dest) {
	UInt32 usedSpace = 0;
	CMIOObjectPropertyScope scope = kCMIOObjectPropertyScopeGlobal;
	CMIOObjectPropertyAddress address = {
		selector,
		scope,
		0 // Element
	};
	if (!CMIOObjectHasProperty(id, &address)) {
		*dest = NULL;
	}
	OSStatus result = CMIOObjectGetPropertyData(id, &address, 0, nil, sizeof(CFStringRef), &usedSpace, dest);
	if (result != kCMIOHardwareNoError) {
		NSLog(@"uh, oh");
		*dest = NULL;
	}
}

NSArray<NSNumber*>* getArrayValue(CMIODeviceID id,
								  CMIOObjectPropertySelector selector) {
	CMIOObjectPropertyScope scope = kCMIOObjectPropertyScopeGlobal;
	CMIOObjectPropertyAddress address = {
		selector,
		scope,
		0 // Element
	};
	NSMutableArray* devices = [NSMutableArray array];
	if (!CMIOObjectHasProperty(id, &address)) {
		return devices;
	}
	
	UInt32 size = 0;
	UInt32 usedSpace = 0;
	OSStatus result = CMIOObjectGetPropertyDataSize(id, &address, 0, NULL, &size);
	if (result != kCMIOHardwareNoError) {
		NSLog(@"status = %d", result);
		return devices;
	}
	size_t count = size/sizeof(UInt32);
	UInt32 buffer[count];
	result = CMIOObjectGetPropertyData(id, &address, 0, nil, size, &usedSpace, buffer);
	for (int i = 0; i < count; i ++) {
		NSNumber* number = [NSNumber numberWithUnsignedInteger:buffer[i]];
		[devices addObject:number];
	}
	return devices;
}

NSArray<NSNumber*>* getDeviceIDs() {
	return getArrayValue(kCMIOObjectSystemObject, kCMIOObjectPropertyOwnedObjects);
}
@end

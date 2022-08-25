//
//  CameraExtensionConnector.cpp
//  CameraTest
//
//  Created by Mark Bessey on 7/26/22.
//

#include "CameraExtensionConnector.h"
#import <CoreMedia/CoreMedia.h>

typedef NSArray<NSNumber*>* NumberArray;
// ----
void queueAlteredProc(CMIOStreamID streamID, void* token, void* refCon);
OSStatus stopSinkStream(CMIOStreamID stream);
NSString* getStringValue(CMIODeviceID id,
						 CMIOObjectPropertySelector selector);
UInt32 getIntValue(CMIODeviceID id,
				   CMIOObjectPropertySelector selector);
void getPointerValue(CMIODeviceID id,
					 CMIOObjectPropertySelector selector, void** dest);
NSArray<NSNumber*>* getArrayValue(CMIODeviceID id,
								  CMIOObjectPropertySelector selector);
NSArray<NSNumber*>* getDeviceIDs(void);

@interface CameraExtensionConnector() {
	CMSimpleQueueRef _queue;
	CVPixelBufferPoolRef _bufferPool;
	CMFormatDescriptionRef _videoFormat;
	int _frameCount;
}
@property(readwrite) CMSimpleQueueRef queue;
@end

@implementation CameraExtensionConnector

- (instancetype) init {
	return [self initWithCameraNamed:@"Mmhmm Camera2 (new)"];
}
- (instancetype) initWithCameraNamed:(NSString *)name {
	if (self = [super init]) {
		_device = [self getCameraID:name];
		_stream = [self getSinkStreamID:_device];
		int width = 1920;
		int height = 1080;
		CMVideoFormatDescriptionCreate(NULL, kCVPixelFormatType_32BGRA, width, height, NULL, &_videoFormat);
		NSDictionary* pixelBufferAttributes = @{
			(NSString*)kCVPixelBufferWidthKey: [NSNumber numberWithInt: width],
			(NSString*)kCVPixelBufferHeightKey: [NSNumber numberWithInt: height],
			(NSString*)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:CMFormatDescriptionGetMediaSubType(_videoFormat)],
			(NSString*)kCVPixelBufferIOSurfacePropertiesKey: @{},
		};
		CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes), &_bufferPool);
		OSStatus result = CMIOStreamCopyBufferQueue(_stream, queueAlteredProc, (__bridge void *)(self)/*refCon*/, &_queue);
		if (result != 0) {
			NSLog(@"Failed to get queue.");
		}
	}
	return self;
}

- (CMIODeviceID) getCameraID: (NSString *) name {
	CMIODeviceID cameraID = 0;
	NumberArray devices = getDeviceIDs();
	for (NSNumber* id in devices) {
		NSString *name = getStringValue(id.unsignedIntValue,
										kCMIOObjectPropertyName);
		if (name != NULL) {
			// check it here
			if ([name isEqualToString:@"Mmhmm Camera2 (new)"]) {
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
		if (direction == 0) { // sink stream
			streamID = id.unsignedIntValue;
		} else if (direction == 1) { // input stream
			// ignore the output stream - it's the camera
			NSLog(@"Ignoring output stream %@", id);
		} else { // not valid
			streamID = -1;
		}
	}
	return streamID;
}

- (OSStatus) startSinkStream {
	return CMIODeviceStartStream(_device, _stream);
}

- (void) overwriteBuffer:(CVPixelBufferRef)pixelBuffer {
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	// draw some pixels
	UInt32 *memory = CVPixelBufferGetBaseAddress(pixelBuffer);
	// no planar bitmaps, please
	assert(CVPixelBufferGetPlaneCount(pixelBuffer) == 0);
	//uint8_t *memory = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
	size_t size = CVPixelBufferGetDataSize(pixelBuffer)/sizeof(UInt32);
	UInt32 offset = _frameCount;
	for (int i = 0; i < size; i++) {
		UInt32 value = ((i+offset)%256);
		UInt32 pixel = (0xff000000 | value<<16 | value<<8 | value);
		memory[i] = pixel;
	}
	_frameCount++;
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (OSStatus) createPixelBufferIn:(CVPixelBufferRef _Nullable*) pixelBuffer {
	OSStatus result = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(NULL, _bufferPool, nil, pixelBuffer);
	if (result == noErr) {
		[self overwriteBuffer:*pixelBuffer];
	}
	return result;
}

- (OSStatus) createSampleBuffer:(CMSampleBufferRef*)sampleBuffer for:(CVPixelBufferRef)pixelBuffer {
	CMSampleTimingInfo timingInfo;
	timingInfo.decodeTimeStamp = kCMTimeInvalid;
	timingInfo.duration = kCMTimeInvalid;
	timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock());
	OSStatus result = CMSampleBufferCreateForImageBuffer(nil, pixelBuffer, true, nil, nil, _videoFormat, &timingInfo, sampleBuffer);
	return result;
}

- (void) send:(CMSampleBufferRef)sampleBuffer {
  static BOOL firstError=YES;
    // retain the buffer, since the CMSimpleQueue doesn't
	CFRetain(sampleBuffer);
//    NSLog(@"queuing %p", sampleBuffer);
	OSStatus result = CMSimpleQueueEnqueue(_queue, sampleBuffer);
	if (result == kCMSimpleQueueError_QueueIsFull) {
      if (firstError) {
		NSLog(@"queue is full.");
        firstError = NO;
      }
	} else if (result != noErr) {
      if (firstError) {
		NSLog(@"failed to enqueue, error = %d", result);
        firstError = NO;
      }
	}
}

- (void) send {
	OSStatus result;
	CVPixelBufferRef pixelBuffer;
	result = [self createPixelBufferIn:&pixelBuffer];
	if (result != noErr) {
		NSLog(@"Dang. failed to create pixel buffer");
		return;
	}
	CMSampleBufferRef sampleBuffer;
	result = [self createSampleBuffer:&sampleBuffer for:pixelBuffer];
	if (result == noErr) {
		// creating the sample buffer retains the pixelBuffer
		CFRelease(pixelBuffer);
	}
	[self send:sampleBuffer];
}

@end

#pragma mark CoreMediaIO utility functions
void queueAlteredProc(CMIOStreamID streamID, void* token, void* refCon) {
	// okay, a buffer has been processed. Now what?
	CameraExtensionConnector* connector = (__bridge CameraExtensionConnector*)refCon;
	if (connector == nil) {
		NSLog(@"Oops, no self pointer.");
		return;
	}
//    NSLog(@"qap: token %p", token);
    //CMSampleBufferRef buffer = (CMSampleBufferRef)token;
	int32_t count = CMSimpleQueueGetCount(connector.queue);
	int32_t capacity = CMSimpleQueueGetCapacity(connector.queue);
	if (count >= capacity) {
		NSLog(@"queue stalled");
		return;
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


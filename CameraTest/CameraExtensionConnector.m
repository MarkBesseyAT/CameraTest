//
//  CameraExtensionConnector.m
//  CameraTest
//
// Copyright © 2020-2022 mmhmm, inc. All rights reserved.
//

#import "CameraExtensionConnector.h"
#import "CameraExtensionConnectorAPI.h"

#import <CoreMedia/CoreMedia.h>
#import <CoreMediaIO/CoreMediaIO.h>
#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wsign-compare"

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

@implementation CameraExtensionConnector
@synthesize queue=_queue;

- (instancetype) init {
	return [self initWithCameraNamed:@"Mmhmm Camera (new)"];
}
- (instancetype) initWithCameraNamed:(NSString *)name {
	if (self = [super init]) {
		_device = [self getCameraID:name];
		_stream = [self getSinkStreamID:_device];
		int width = 1920;
		int height = 1080;
        CMVideoFormatDescriptionCreate(NULL, kCVPixelFormatType_32BGRA, width, height, NULL, &_videoFormat);
        //ToDo: figure out why I can't create a buffer pool with 24BGR format
        // CMVideoFormatDescriptionCreate(NULL, kCVPixelFormatType_24BGR, width, height, NULL, &_videoFormat);
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

- (CMIODeviceID) getCameraID: (NSString *) wantedName {
	CMIODeviceID cameraID = 0;
	NumberArray devices = getDeviceIDs();
	for (NSNumber* id in devices) {
		NSString *name = getStringValue(id.unsignedIntValue,
										kCMIOObjectPropertyName);
		if (name != NULL) {
			// check it here
			if ([name isEqualToString: wantedName]) {
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

- (OSStatus) createPixelBufferIn:(CVPixelBufferRef _Nullable*) pixelBuffer {
	OSStatus result = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(NULL, _bufferPool, nil, pixelBuffer);
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
	CFRetain(sampleBuffer);
	OSStatus result = CMSimpleQueueEnqueue(_queue, sampleBuffer);
	if (result == kCMSimpleQueueError_QueueIsFull) {
		NSLog(@"queue is full.");
	} else if (result != noErr) {
		NSLog(@"failed to enqueue, error = %d", result);
	}
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
	int32_t count = CMSimpleQueueGetCount(connector.queue);
	int32_t capacity = CMSimpleQueueGetCapacity(connector.queue);
	if (count >= capacity) {
		NSLog(@"queue stalled");
		return;
	}
    CMSampleBufferRef buffer = (CMSampleBufferRef)token;
    // Todo: MarkB - I honestly don't know why this ISN'T needed, but I get a crash when it's enabled.
    // In the Hybrid app, we absolutely *need* this release to avoid leaking memory.
    // There must be some difference in how these buffers are originally getting allocated, or something.
    //CFRelease(buffer);
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
		NSLog(@"Device %d doesn't have int property %d", id, selector);
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
        NSLog(@"Device %d doesn't have pointer property %d", id, selector);
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

#pragma mark C-API
static CameraExtensionConnector* instance = NULL;
int camera_extension_open() {
  if (!instance) {
    instance = [[CameraExtensionConnector alloc]init];
  }
  OSStatus result = [instance startSinkStream];
  if (result != 0) {
    NSLog(@"Couldn't start camera, Error: %d", result);
  }
  return result;
}

int camera_extension_write(void*buffer, size_t size) {
  CVPixelBufferRef pxb;
  [instance createPixelBufferIn:&pxb];
  // copy data
  // ToDo: make this more-efficient
  assert(size == CVPixelBufferGetDataSize(pxb)*3/4);
  CVPixelBufferLockBaseAddress(pxb, 0);
  UInt8* dst = CVPixelBufferGetBaseAddress(pxb);
  // memcpy(dst, buffer, size);
  UInt8 *src = (UInt8*) buffer;
  for (int i=0; i < (int) size; i++) {
    if(i%3 == 0 && i != 0) {
      *(dst++) = 0;
    }
    *(dst++) = *(src++);
  }
  CVPixelBufferUnlockBaseAddress(pxb, 0);
  CMSampleBufferRef sampleBuffer;
  [instance createSampleBuffer:&sampleBuffer for:pxb];
  CFRelease(pxb);
  [instance send:sampleBuffer];
  return 0;
}

int camera_extension_close(void) {
  instance = nil;
  return 0;
}

#pragma clang diagnostic pop

//
//  CameraExtensionConnector.cpp
//  CameraTest
//
//  Created by Mark Bessey on 7/26/22.
//

#include "CameraExtensionConnector.h"

typedef NSArray<NSNumber*>* NumberArray;

NSString* getStringValue(CMIODeviceID id,
						 CMIOObjectPropertySelector selector);
NSArray<NSNumber*>* getArrayValue(CMIODeviceID id,
								  CMIOObjectPropertySelector selector);
void getPointerValue(CMIODeviceID id,
					  CMIOObjectPropertySelector selector, void** dest);
UInt32 getIntValue(CMIODeviceID id,
			CMIOObjectPropertySelector selector);

CMIODeviceID getCameraID(NSString *name) {
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

CMIOStreamID getSinkStreamID(void) {
	CMIODeviceID id = getCameraID(@"Sample Camera");
	NumberArray streams = getArrayValue(id, kCMIODevicePropertyStreams);
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

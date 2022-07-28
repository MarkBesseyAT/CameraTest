//
//  CameraExtensionConnector.h
//  CameraTest
//
//  Created by Mark Bessey on 7/26/22.
//

#ifndef CameraExtensionConnector_h
#define CameraExtensionConnector_h
#import <Foundation/Foundation.h>
// The C API for CoreMediaIO
#import <CoreMediaIO/CMIOHardware.h>

@interface CameraExtensionConnector: NSObject {
}
- (CMIODeviceID) getCameraID:(NSString*) name;
- (CMIOStreamID) getSinkStreamID:(CMIODeviceID) device;
- (OSStatus) startSinkStream;
- (void) send:(CMSampleBufferRef)buffer;
@end
#endif /* CameraExtensionConnector_h */

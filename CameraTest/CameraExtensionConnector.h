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
@property CMIODeviceID device;
@property CMIOStreamID stream;
- (instancetype) initWithCameraNamed:(NSString*)name;
- (OSStatus) startSinkStream;
//- (void) send:(CMSampleBufferRef)buffer;
- (OSStatus) createPixelBufferIn:(CF_RETURNS_RETAINED CVPixelBufferRef *) pixelBufferOut;
- (OSStatus) createSampleBuffer:(CF_RETURNS_RETAINED CMSampleBufferRef *)buffer for:(CVPixelBufferRef)pixelBuffer;
- (void) overwriteBuffer:(CVPixelBufferRef)pixelBuffer;
- (void) send;
- (void) send:(CMSampleBufferRef)buffer;
@end
#endif /* CameraExtensionConnector_h */

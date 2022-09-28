//
//  CameraExtensionConnector.h
//  CameraTest
//
//  Created by Mark Bessey on 9/28/22.
//

#ifndef CameraExtensionConnector_h
#define CameraExtensionConnector_h
#import <Foundation/Foundation.h>
#import <CoreMediaIO/CMIOHardware.h>

@interface CameraExtensionConnector:NSObject {
    CMIODeviceID _device;
    CMIOStreamID _stream;
  CMSimpleQueueRef _queue;
  CVPixelBufferPoolRef _bufferPool;
  CMFormatDescriptionRef _videoFormat;
  int _frameCount;
}
- (instancetype) initWithCameraNamed:(NSString *)name;
- (OSStatus) startSinkStream;
- (void) send:(CMSampleBufferRef)sampleBuffer;
@property(readwrite) CMSimpleQueueRef queue;
@end

#endif /* CameraExtensionConnector_h */

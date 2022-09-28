//
//  CameraExtensionConnector.h
//  CameraTest
//
// Copyright © 2020-2022 mmhmm, inc. All rights reserved.
//

#ifndef CameraExtensionConnector_h
#define CameraExtensionConnector_h
#include <stddef.h>
#ifdef __cplusplus
  extern "C" {
#endif
    int camera_extension_open();
    int camera_extension_write(void* buffer, size_t size);
    int camera_extension_close();
#ifdef __cplusplus
  }
#endif
#endif /* CameraExtensionConnector_h */

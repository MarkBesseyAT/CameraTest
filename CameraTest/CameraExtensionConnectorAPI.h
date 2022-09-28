//
//  CameraExtensionConnectorAPI.h
//  CameraTest
//
// Copyright © 2020-2022 mmhmm, inc. All rights reserved.
//

#ifndef CameraExtensionConnectorAPI_h
#define CameraExtensionConnectorAPI_h
#include <stddef.h>
#ifdef __cplusplus
  extern "C" {
#endif
    int camera_extension_open(void);
    int camera_extension_write(void* buffer, size_t size);
    int camera_extension_close(void);
#ifdef __cplusplus
  }
#endif
#endif /* CameraExtensionConnectorAPI_h */

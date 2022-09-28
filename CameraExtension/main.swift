//
//  main.swift
//  extension
//
//  Copyright © 2020 mmhmm, inc. All rights reserved.
//

import Foundation
import CoreMediaIO

let providerSource = CameraProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()

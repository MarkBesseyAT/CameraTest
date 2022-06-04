//
//  main.swift
//  camera
//
//  Created by Mark Bessey on 3/3/22.
//

import Foundation
import CoreMediaIO

let providerSource = cameraProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()

//
//  XPCServiceDelegate.swift
//  XPCService
//
//  Created by Mark Bessey on 5/23/22.
//

import Foundation
import os.log

class XPCServiceDelegate: NSObject, NSXPCListenerDelegate {
	func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
		os_log("XPC connection established")
		let exportedObject = MyService()
		newConnection.exportedInterface = NSXPCInterface(with: XPCServiceProtocol.self)
		newConnection.exportedObject = exportedObject
		newConnection.resume()
		return true
	}
}

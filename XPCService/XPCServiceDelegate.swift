//
//  XPCServiceDelegate.swift
//  XPCService
//
//  Created by Mark Bessey on 5/23/22.
//

import Foundation

class XPCServiceDelegate: NSObject, NSXPCListenerDelegate {
	func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
		let exportedObject = MyService()
		newConnection.exportedInterface = NSXPCInterface(with: XPCServiceProtocol.self)
		newConnection.exportedObject = exportedObject
		newConnection.resume()
		return true
	}
}

//
//  CameraTestApp.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/3/22.
//

import SwiftUI

@main
struct CameraTestApp: App {
	static let cameraID = "app.mmhmm.CameraTest.camera"
	let helper = ExtensionHelper()
	@StateObject var model = AppModel()
	init() {
		helper.installExtension()
		makeXPCcalls()
	}
	
	func makeXPCcalls() {
		// Make an XPC call to the embedded service. This works!
		let xpc_connection = NSXPCConnection(serviceName: "app.mmhmm.XPCService")
		xpc_connection.remoteObjectInterface = NSXPCInterface(with: XPCServiceProtocol.self)
		xpc_connection.resume()

		let xpc_service = xpc_connection.remoteObjectProxyWithErrorHandler { error in
			print("Received error:", error)
		} as? XPCServiceProtocol

		xpc_service?.upperCaseString("hello XPC") { response in
			print("Response from XPC service:", response)
		}

		// Make an XPC call to the camera extension. This fails!
		// This is the CMIOExtensionMachServiceName specified in the extension
//		let camera_connection = NSXPCConnection(serviceName: "M3KUT44L48.app.mmhmm.CameraTest.camera")
		let camera_connection = NSXPCConnection(machServiceName: "M3KUT44L48.app.mmhmm.CameraTest.camera")
		camera_connection.remoteObjectInterface = NSXPCInterface(with: XPCServiceProtocol.self)
		camera_connection.resume()

		let camera_service = camera_connection.remoteObjectProxyWithErrorHandler { error in
			print("Received error:", error)
		} as? XPCServiceProtocol

		camera_service?.upperCaseString("hello XPC") { response in
			print("Response from XPC service:", response)
		}

	}
    var body: some Scene {
        WindowGroup {
			ContentView(helper: ExtensionHelper())
				.environmentObject(model)
        }
    }	
}

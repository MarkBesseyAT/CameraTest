//
//  CameraTestApp.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/3/22.
//

import SwiftUI
import SystemExtensions

@main
struct CameraTestApp: App, UnInstaller {
	static let cameraID = "app.mmhmm.CameraTest.camera"
	let delegate = RequestDelegate()
	@StateObject var model = AppModel()
	init() {
		// Create an extension activation request and assign a delegate to
		// receive reports of success or failure.
		let request = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: CameraTestApp.cameraID,
							 queue: DispatchQueue.main)
		request.delegate = delegate

		// Submit the request to the system.
		let extensionManager = OSSystemExtensionManager.shared
		extensionManager.submitRequest(request)

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
		let camera_connection = NSXPCConnection(serviceName: "M3KUT44L48.app.mmhmm.CameraTest.camera")
//		let camera_connection = NSXPCConnection(machServiceName: "M3KUT44L48.app.mmhmm.CameraTest.camera")
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
            ContentView(self)
				.environmentObject(model)
        }
    }
	func unInstall() {
		// Create a deactivation request and assign a delegate to
		// receive reports of success or failure.
		let request = OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier: CameraTestApp.cameraID,
							 queue: DispatchQueue.main)
		request.delegate = delegate

		// Submit the request to the system.
		let extensionManager = OSSystemExtensionManager.shared
		extensionManager.submitRequest(request)
	}
	
}

class RequestDelegate: NSObject, OSSystemExtensionRequestDelegate {
	func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
		// Return whether to replace, or cancel the action. You'd want to check the version, here...
		return .replace
	}
	
	func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
		// Advisory, I guess? We can't do anything here, except note that the user has been asked (and reflect that in the UI?).
		// The request stays in a "pending" state while this is happening
		print("Asking user for permission")
	}
	
	func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
		switch result {
		case .completed:
			// let the user know it happened
			break
		case .willCompleteAfterReboot:
			// ask the user to reboot
			break
		default:
			// log an error
			break
		}
		print("finished with result", result.rawValue)
	}
	
	func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
		print("an error occurred: ", error.localizedDescription)
	}
	
}

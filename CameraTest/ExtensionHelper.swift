//
//  UnInstaller.swift
//  CameraTest
//
//  Created by Mark Bessey on 5/30/22.
//

//import Foundation
import SystemExtensions
import AppKit

protocol HelperMethods {
	func installExtension()
	func unInstallExtension()
}

struct ExtensionHelper: HelperMethods {
	let delegate = RequestDelegate()

	func installExtension() {
		// Create an extension activation request and assign a delegate to
		// receive reports of success or failure.
		let request = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: CameraTestApp.cameraID,
							 queue: DispatchQueue.main)
		request.delegate = delegate

		// Submit the request to the system.
		let extensionManager = OSSystemExtensionManager.shared
		extensionManager.submitRequest(request)
	}
	func unInstallExtension() {
		// Create a deactivation request and assign a delegate to
		// receive reports of success or failure.
		var request = OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier: CameraTestApp.cameraID,
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
        let alert = NSAlert(error: error)
        alert.runModal()
	}
	
}

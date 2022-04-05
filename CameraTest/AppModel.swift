//
//  AppModel.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/17/22.
//

import Foundation
import AVFoundation

class AppModel: ObservableObject {
	@Published var cameras: [CameraModel]
	@Published var selectedCameraId: String
	init() {
		cameras = []
		selectedCameraId = ""
		let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified)
		for device in session.devices {
			let name = device.localizedName
			let id = device.uniqueID
			let formats = device.formats
			var maxSize = CGSize.zero
			for format in formats {
				let description = format.formatDescription
				let size = description.presentationDimensions()
				if (size.width > maxSize.width) {
					print("New max size: ", size.debugDescription)
					maxSize = size
				}
			}
			let camera = CameraModel(name: name, size: maxSize, id: id)
			cameras.append(camera)
		}
		let defaultCamera = UserDefaults.standard.string(forKey: "SelectedCamera")
		selectedCameraId = defaultCamera ?? cameras[0].id
	}
	
	init(withFakeCameras fakeCameras:[String], selected: String) {
		cameras = []
		selectedCameraId = ""
		for name in fakeCameras {
			let camera = CameraModel(name: name, size: CGSize(width: 1920, height: 1080), id: name)
			cameras.append(camera)
		}
		selectedCameraId = cameras[0].id
	}
}

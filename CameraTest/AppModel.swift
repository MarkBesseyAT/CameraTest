//
//  AppModel.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/17/22.
//

import Foundation
import AVFoundation
import Combine

class AppModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
	let discoverySession: AVCaptureDevice.DiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified)
	@Published var captureSession:AVCaptureSession = AVCaptureSession()
	@Published var cameras:[CameraModel] = []
	@Published var selectedCameraId: String {
		didSet {
			updateCamera()
		}
	}
	var cameraCancellable:Cancellable?
	var defaultCancellable:Cancellable?
	override init() {
		selectedCameraId = ""
		super.init()
		cameraCancellable = discoverySession.publisher(for: \.devices).sink(receiveValue: { devices in
			self.updateCameras(devices)
		})
	}
	
	init(withFakeCameras fakeCameras:[String], selected: String) {
		cameras = []
		selectedCameraId = ""
		super.init()
		for name in fakeCameras {
			let camera = CameraModel(name: name, size: CGSize(width: 1920, height: 1080), id: name)
			cameras.append(camera)
		}
		selectedCameraId = cameras[0].id
	}

	func updateCameras(_ devices: [AVCaptureDevice]) -> Void {
		var newCameras:[CameraModel] = []
		for device in devices {
			let camera = CameraModel(device: device)
			newCameras.append(camera)
		}
		cameras = newCameras
		let defaultCamera = UserDefaults.standard.string(forKey: "SelectedCamera")
		selectedCameraId = defaultCamera ?? cameras[0].id
	}
	
	func updateCamera() {
		UserDefaults.standard.set(selectedCameraId, forKey: "SelectedCamera")
		let captureSession = AVCaptureSession()
		captureSession.beginConfiguration()
		var videoDevice = AVCaptureDevice(uniqueID: selectedCameraId)
		if videoDevice == nil {
			selectedCameraId = cameras[0].id
			videoDevice = AVCaptureDevice(uniqueID: selectedCameraId)
		}
		guard
			let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
			captureSession.canAddInput(videoDeviceInput)
			else { return }
		captureSession.addInput(videoDeviceInput)
		let videoOutput = AVCaptureVideoDataOutput()
		guard captureSession.canAddOutput(videoOutput) else { return }
		captureSession.sessionPreset = .high
		captureSession.addOutput(videoOutput)
		captureSession.commitConfiguration()
		captureSession.startRunning()
		self.captureSession = captureSession
	}
	
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		print("got one")
	}
}

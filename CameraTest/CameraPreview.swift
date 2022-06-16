//
//  CameraPreview.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/17/22.
//

import Foundation
import SwiftUI
import AVFoundation

struct CameraPreview: NSViewRepresentable {
	@EnvironmentObject var model:AppModel
	typealias NSViewType = NSView
	@State var previewLayer:AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
//	var previewLayer:CALayer = CALayer()
	func makeNSView(context: Context) -> NSView {
		let view = NSView()
		view.wantsLayer = true
		//view.layer?.backgroundColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
		// add the preview layer here
		previewLayer.session = model.captureSession
		view.layer = previewLayer
//		previewLayer.videoGravity = .resizeAspectFill
		return view;
	}
	
	func updateNSView(_ nsView: NSView, context: Context) {
		// do something here
		print("update")
		previewLayer.session = model.captureSession
		//previewLayer.frame = nsView.bounds
	}
	
}

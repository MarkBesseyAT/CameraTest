//
//  CameraPreview.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/17/22.
//

import Foundation
import SwiftUI
struct CameraPreview: NSViewRepresentable {
	typealias NSViewType = NSView
	func makeNSView(context: Context) -> NSView {
		var view = NSView()
		view.wantsLayer = true
		view.layer?.backgroundColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
		// add the preview layer here
		
		return view;
	}
	
	func updateNSView(_ nsView: NSView, context: Context) {
		// do something here
	}
	
}

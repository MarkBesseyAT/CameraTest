//
//  CameraModel.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/17/22.
//

import Foundation
import AVFoundation
import Combine

class CameraModel {
	var name: String
	var size: CGSize
	var id: String

	init(device:AVCaptureDevice) {
		self.name = device.localizedName
		self.id = device.uniqueID
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
		self.size = maxSize
	}
	
	init(name: String, size: CGSize, id: String) {
		self.name = name
		self.size = size
		self.id = id
	}
}

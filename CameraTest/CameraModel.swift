//
//  CameraModel.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/17/22.
//

import Foundation
class CameraModel: ObservableObject {
	var name: String
	var size: CGSize
	var id: String
	init(name: String, size: CGSize, id: String) {
		self.name = name
		self.size = size
		self.id = id
	}
}

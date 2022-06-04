//
//  CameraTestApp.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/3/22.
//

import SwiftUI

@main
struct CameraTestApp: App {
	static let cameraID = "app.mmhmm.CameraTest.CameraExtension"
	let helper = ExtensionHelper()
	@StateObject var model = AppModel()
	init() {
		helper.installExtension()
	}
	
    var body: some Scene {
        WindowGroup {
			ContentView(helper: ExtensionHelper())
				.environmentObject(model)
        }
    }
}

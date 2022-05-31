//
//  ContentView.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/3/22.
//

import SwiftUI

struct ContentView: View {
	var helper:HelperMethods
	@EnvironmentObject var model:AppModel
    var body: some View {
		VStack() {
			Text("Hello, world!")
            .padding()
			Picker(selection: $model.selectedCameraId, label: Text("Just a list of Cameras")) {
				ForEach(model.cameras, id:\.id) { camera in 
					Text(camera.name)
				}
			}.padding()

			Button("Un-install") {
			// un-install
				helper.unInstallExtension()
			}
			.padding()
		}
    }
}

class fakeHelper: HelperMethods {
	var isInstalled: Bool {
		return false;
	}
	
	func installExtension() {
		print("installing...")
	}
	
	func unInstallExtension() {
		print("uninstalling...")
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView(helper: fakeHelper())
			.environmentObject(AppModel(withFakeCameras: ["MY CAMERA"], selected: "MY CAMERA"))
    }
}

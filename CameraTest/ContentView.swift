//
//  ContentView.swift
//  CameraTest
//
//  Created by Mark Bessey on 3/3/22.
//

import SwiftUI

protocol UnInstaller {
	func unInstall()
}

struct ContentView: View {
	@EnvironmentObject var model:AppModel
	var unInstaller:UnInstaller
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
				unInstaller.unInstall()
			}
			.padding()
		}
    }
	init(_ u:UnInstaller) {
		unInstaller = u
	}
}

class fakeUnInstaller: UnInstaller {
	func unInstall() {
		print("uninstalling...")
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(fakeUnInstaller())
			.environmentObject(AppModel(withFakeCameras: ["MY CAMERA"], selected: "MY CAMERA"))
    }
}

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
			CameraPreview()
				.frame(minWidth: 100, idealWidth: 200, maxWidth: 400, minHeight: 100, idealHeight: 200, maxHeight: 400, alignment: .center)
				.aspectRatio(1.0, contentMode: .fit)
				.padding()
			Picker(selection: $model.selectedCameraId, label: Text("Camera")) {
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

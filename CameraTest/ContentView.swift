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
			CameraPreview().frame(minWidth: 100, idealWidth: nil, maxWidth: nil, minHeight: 100, idealHeight: nil, maxHeight: nil, alignment: .center)
			Picker(selection: $model.selectedCameraId, label: Text("Select Camera")) {
				ForEach(model.cameras, id:\.id) { camera in 
					Text(camera.name)
				}
			}.padding()

            Button("Install") {
              // Install
              helper.installExtension()
            }
            .padding()
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

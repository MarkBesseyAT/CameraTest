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
	var unInstaller:UnInstaller
    var body: some View {
		VStack() {
			Text("Hello, world!")
            .padding()
			CameraPreview()
				.frame(minWidth: 100, idealWidth: 200, maxWidth: 400, minHeight: 100, idealHeight: 200, maxHeight: 400, alignment: .center)
				.aspectRatio(1.0, contentMode: .fit)
				.padding()
			Picker(selection: /*@START_MENU_TOKEN@*/.constant(1)/*@END_MENU_TOKEN@*/, label: Text("Camera")) {
				/*@START_MENU_TOKEN@*/Text("1").tag(1)/*@END_MENU_TOKEN@*/
				/*@START_MENU_TOKEN@*/Text("2").tag(2)/*@END_MENU_TOKEN@*/
			}

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
    }
}

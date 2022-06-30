//
//  CMIOHelper.swift
//  CameraTest
//
//  Created by Mark Bessey on 6/28/22.
//

import CoreMediaIO
import Foundation

class CMIODeviceHelper {
	let id:UInt32
	var name:String!
	var children:[CMIODeviceHelper] = []
	init(id:UInt32) {
		self.id = id
		name = getStringProperty(id: id, property: kCMIOObjectPropertyName)
		let kids = getUInt32ArrayProperty(property: kCMIOObjectPropertyOwnedObjects)
		for id in kids {
			let kid = CMIODeviceHelper(id: id)
			children.append(kid)
		}
	}

	private func getStringProperty(id:UInt32, property:Int) -> String {
		let data = readPropertyData(property: property)
		var str:String = "(no name)"
		if data.count > 0 {
			data.withUnsafeBytes { bytes in
				let typedPointer = bytes.bindMemory(to: CFString.self)
				let cfs = typedPointer.baseAddress?.pointee
				str = String(cfs! as NSString)
			}
		}
		return str
	}
	
	private func getUInt32ArrayProperty(property:Int) -> [UInt32] {
		let data = readPropertyData(property: property)
		var array:[UInt32] = []
		var count = data.count / MemoryLayout<UInt32>.size
		data.withUnsafeBytes { bytes in
			let typedPointer = bytes.bindMemory(to: UInt32.self)
			for i in 0..<count {
				array.append(typedPointer[i])
			}
		}
		return array
	}
	
	private func readPropertyData(property:Int) -> Data {
		let selector = CMIOObjectPropertySelector(property)
		let scope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal)
		let element = CMIOObjectPropertyElement(0)
		var address = CMIOObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
		var size:UInt32 = 0
		var usedSpace:UInt32 = 0
		let result = CMIOObjectGetPropertyDataSize(self.id, &address, 0, nil, &size)
		if result != kCMIOHardwareNoError {
			print("status = \(result)")
			return Data()
		}
		let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(size))
		defer {
			pointer.deinitialize(count: Int(size))
			pointer.deallocate()
		}
		CMIOObjectGetPropertyData(self.id, &address, 0, nil, size, &usedSpace, pointer)
		let data = Data(buffer: UnsafeBufferPointer(start: pointer, count: Int(usedSpace)))
		return data
	}
	
	static func root() -> CMIODeviceHelper {
		return CMIODeviceHelper(id: CMIOObjectID(kCMIOObjectSystemObject))
	}
}

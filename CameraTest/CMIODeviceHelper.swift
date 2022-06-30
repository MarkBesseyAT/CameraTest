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
	var name:String? {
		return _name
	}
	var children:[CMIODeviceHelper]? {
		return _children
	}
	var uuid:String? {
		return _uuid
	}
	var streams:[UInt32]? {
		return _streams
	}
	private var _name:String?
	private var _children:[CMIODeviceHelper]?
	private var _uuid:String?
	private var _streams:[UInt32]?
	init(id:UInt32) {
		self.id = id
		_name = CMIODeviceHelper.getStringProperty(id: id, property: kCMIOObjectPropertyName)
		let kids = CMIODeviceHelper.getUInt32ArrayProperty(id: id, property: kCMIOObjectPropertyOwnedObjects)
		if let kids = kids {
			var allKids:[CMIODeviceHelper] = []
			for id in kids {
				let kid = CMIODeviceHelper(id: id)
				allKids.append(kid)
			}
			_children = allKids
		}
		_uuid = CMIODeviceHelper.getStringProperty(id: id, property: kCMIODevicePropertyDeviceUID)
		let streams = CMIODeviceHelper.getUInt32ArrayProperty(id: id, property: kCMIODevicePropertyStreams)
		_streams = streams
	}

	private static func getStringProperty(id:UInt32, property:Int) -> String? {
		let data = readPropertyData(id: id, property: property)
		guard data.count > 0 else { return nil }
		var str:String = "(no value)"
		if data.count > 0 {
			data.withUnsafeBytes { bytes in
				let typedPointer = bytes.bindMemory(to: CFString.self)
				let cfs = typedPointer.baseAddress?.pointee
				str = String(cfs! as NSString)
			}
		}
		return str
	}
	
	private static func getUInt32ArrayProperty(id:UInt32, property:Int) -> [UInt32]? {
		let data = readPropertyData(id: id, property: property)
		var array:[UInt32] = []
		let count = data.count / MemoryLayout<UInt32>.size
		data.withUnsafeBytes { bytes in
			let typedPointer = bytes.bindMemory(to: UInt32.self)
			for i in 0..<count {
				array.append(typedPointer[i])
			}
		}
		return array
	}
	
	private static func readPropertyData(id: UInt32, property:Int) -> Data {
		let selector = CMIOObjectPropertySelector(property)
		let scope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal)
		let element = CMIOObjectPropertyElement(0)
		var address = CMIOObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
		if !CMIOObjectHasProperty(id, &address) {
			return Data()
		}
		var size:UInt32 = 0
		var usedSpace:UInt32 = 0
		let result = CMIOObjectGetPropertyDataSize(id, &address, 0, nil, &size)
		if result != kCMIOHardwareNoError {
			print("status = \(result)")
			return Data()
		}
		let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(size))
		defer {
			pointer.deinitialize(count: Int(size))
			pointer.deallocate()
		}
		CMIOObjectGetPropertyData(id, &address, 0, nil, size, &usedSpace, pointer)
		let data = Data(buffer: UnsafeBufferPointer(start: pointer, count: Int(usedSpace)))
		return data
	}
	
	static func systemObject() -> CMIODeviceHelper {
		return CMIODeviceHelper(id: CMIOObjectID(kCMIOObjectSystemObject))
	}
}

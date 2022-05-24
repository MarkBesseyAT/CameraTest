//
//  XPCService.swift
//  XPCService
//
//  Created by Mark Bessey on 5/23/22.
//

import Foundation
import os.log

class MyService: NSObject, XPCServiceProtocol {
	func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void) {
		os_log("running XPC function")
		let response = string.uppercased()
		reply(response)
	}
}

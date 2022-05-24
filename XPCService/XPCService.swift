//
//  XPCService.swift
//  XPCService
//
//  Created by Mark Bessey on 5/23/22.
//

import Foundation

class MyService: NSObject, XPCServiceProtocol {
	func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void) {
		let response = string.uppercased()
		reply(response)
	}
}

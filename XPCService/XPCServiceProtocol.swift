import Foundation

@objc public protocol XPCServiceProtocol {
	func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void)
}

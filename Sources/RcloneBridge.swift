import Foundation

/// A thread-safe Swift wrapper around the `librclone` C header.
class RcloneBridge {
    static let shared = RcloneBridge()
    private let queue = DispatchQueue(label: "com.rclonegui.rpc", attributes: .concurrent)

    private init() {}

    /// Call rclone RPC method
    /// - Parameters:
    ///   - method: The RPC method to call (e.g., "core/command")
    ///   - input: JSON string of arguments
    /// - Returns: JSON response string
    func callRcloneRPC(method: String, input: String) -> String {
        return queue.sync {
            let methodCString = method.cString(using: .utf8)
            let inputCString = input.cString(using: .utf8)

            let result = RcloneRPC(methodCString, inputCString)
            
            var responseString = ""
            if let outputC = result.Output {
                responseString = String(cString: outputC)
                RcloneFreeString(result.Output)
            }
            
            // Note: In a real app we might check result.Status, but 
            // the JSON response usually contains the error details too.
            return responseString
        }
    }
}

import Foundation
import Rclonebridge

/// A thread-safe Swift wrapper around the `RcloneKit` xcframework (gomobile).
class RcloneBridge {
    static let shared = RcloneBridge()
    private let queue = DispatchQueue(label: "com.rclonegui.rpc", attributes: .concurrent)

    private init() {
        RclonebridgeInitialize()
    }

    /// Call rclone RPC method
    /// - Parameters:
    ///   - method: The RPC method to call (e.g., "core/command")
    ///   - input: JSON string of arguments
    /// - Returns: JSON response string
    func callRcloneRPC(method: String, input: String) -> String {
        return queue.sync {
            let result = RclonebridgeRPC(method, input)
            return result?.output ?? "{}"
        }
    }
}

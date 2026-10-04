import Foundation
import SwiftUI

class BrowserViewModel: ObservableObject {
    @Published var items: [RcloneItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDownloading = false
    
    let remoteName: String
    let currentPath: String
    
    init(remoteName: String, currentPath: String) {
        self.remoteName = remoteName
        self.currentPath = currentPath
    }
    
    func fetchItems() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let inputDict: [String: Any] = [
                "fs": "\(self.remoteName):",
                "remote": self.currentPath
            ]
            
            guard let data = try? JSONSerialization.data(withJSONObject: inputDict),
                  let inputStr = String(data: data, encoding: .utf8) else {
                return
            }
            
            let responseStr = RcloneBridge.shared.callRcloneRPC(method: "operations/list", input: inputStr)
            
            guard let responseData = responseStr.data(using: .utf8) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to parse data."
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(RcloneListResponse.self, from: responseData)
                DispatchQueue.main.async {
                    self.items = response.list ?? []
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error decoding JSON: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func downloadFile(item: RcloneItem, completion: @escaping (URL?) -> Void) {
        DispatchQueue.main.async {
            self.isDownloading = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let tempDir = FileManager.default.temporaryDirectory
            let destinationURL = tempDir.appendingPathComponent(item.Name)
            
            // Format input for operations/copyfile
            // srcFs: remote:, srcRemote: path/to/file, dstFs: /tmp, dstRemote: file
            let srcFs = "\(self.remoteName):"
            let srcRemote = self.currentPath.isEmpty ? item.Name : "\(self.currentPath)/\(item.Name)"
            let dstFs = tempDir.path
            let dstRemote = item.Name
            
            let inputDict: [String: Any] = [
                "srcFs": srcFs,
                "srcRemote": srcRemote,
                "dstFs": dstFs,
                "dstRemote": dstRemote
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: inputDict),
               let inputStr = String(data: data, encoding: .utf8) {
                
                _ = RcloneBridge.shared.callRcloneRPC(method: "operations/copyfile", input: inputStr)
                
                DispatchQueue.main.async {
                    self.isDownloading = false
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        completion(destinationURL)
                    } else {
                        self.errorMessage = "Download failed."
                        completion(nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    completion(nil)
                }
            }
        }
    }
}

import Foundation

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    @Published var remotes: [RcloneRemote] = []
    @Published var isInitialized: Bool = false
    
    private let configFileName = "rclone.conf"
    
    private var configFilePath: String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(configFileName).path
    }
    
    init() {
        setupConfigIfNeeded()
        initializeRclone()
    }
    
    private func setupConfigIfNeeded() {
        if !FileManager.default.fileExists(atPath: configFilePath) {
            FileManager.default.createFile(atPath: configFilePath, contents: nil, attributes: nil)
        }
    }
    
    private func initializeRclone() {
        // According to prompt: core/command with {"command": "config", "arg": ["--config", "/path/to/rclone.conf"]}
        let input = """
        {
            "command": "config",
            "arg": ["--config", "\(configFilePath)"]
        }
        """
        _ = RcloneBridge.shared.callRcloneRPC(method: "core/command", input: input)
        isInitialized = true
        fetchRemotes()
    }
    
    func fetchRemotes() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Using config/dump to get all configured drives
            let response = RcloneBridge.shared.callRcloneRPC(method: "config/dump", input: "{}")
            
            guard let data = response.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            var newRemotes: [RcloneRemote] = []
            for (key, value) in json {
                if let dict = value as? [String: Any], let type = dict["type"] as? String {
                    newRemotes.append(RcloneRemote(name: key, type: type))
                }
            }
            
            DispatchQueue.main.async {
                self.remotes = newRemotes.sorted(by: { $0.name < $1.name })
            }
        }
    }
    
    func importConfig(from string: String) {
        do {
            try string.write(toFile: configFilePath, atomically: true, encoding: .utf8)
            initializeRclone()
        } catch {
            print("Failed to save config file: \(error)")
        }
    }
    
    func addRemote(name: String, type: String, parameters: [String: String], completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var paramsDict: [String: Any] = parameters
            let inputDict: [String: Any] = [
                "name": name,
                "type": type,
                "parameters": paramsDict
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: inputDict),
               let inputStr = String(data: data, encoding: .utf8) {
                _ = RcloneBridge.shared.callRcloneRPC(method: "config/create", input: inputStr)
                self.fetchRemotes()
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}

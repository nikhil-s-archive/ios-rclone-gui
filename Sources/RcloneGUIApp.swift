import SwiftUI

@main
struct RcloneGUIApp: App {
    @StateObject private var configManager = ConfigManager.shared
    
    var body: some Scene {
        WindowGroup {
            if configManager.remotes.isEmpty {
                SetupView()
            } else {
                RemotesView()
            }
        }
    }
}

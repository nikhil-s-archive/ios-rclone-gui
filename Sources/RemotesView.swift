import SwiftUI

struct RemotesView: View {
    @ObservedObject var configManager = ConfigManager.shared
    
    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(configManager.remotes) { remote in
                        NavigationLink(destination: BrowserView(remoteName: remote.name, currentPath: "")) {
                            RemoteCard(remote: remote)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("My Drives")
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationBarItems(trailing: Button(action: {
                // Future: show add provider sheet from here too
            }) {
                Image(systemName: "plus")
            })
            .onAppear {
                configManager.fetchRemotes()
            }
        }
    }
}

struct RemoteCard: View {
    let remote: RcloneRemote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: iconForType(remote.type))
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(remote.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(remote.type.capitalized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func iconForType(_ type: String) -> String {
        switch type {
        case "drive": return "externaldrive.fill"
        case "dropbox": return "shippingbox.fill"
        case "mega": return "m.circle.fill"
        case "s3": return "cylinder.split.1x2.fill"
        default: return "cloud.fill"
        }
    }
}

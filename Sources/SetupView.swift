import SwiftUI

struct SetupView: View {
    @ObservedObject var configManager = ConfigManager.shared
    @State private var showingImportSheet = false
    @State private var showingAddProvider = false
    @State private var rawConfigText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "cloud.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Welcome to Rclone")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Connect your cloud storage providers to easily manage and browse your files natively.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: { showingAddProvider = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Cloud Provider")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button(action: { showingImportSheet = true }) {
                    Text("Import rclone.conf")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImportSheet) {
                ImportConfigView(rawConfigText: $rawConfigText, isPresented: $showingImportSheet)
            }
            .sheet(isPresented: $showingAddProvider) {
                AddProviderView(isPresented: $showingAddProvider)
            }
        }
    }
}

struct ImportConfigView: View {
    @Binding var rawConfigText: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            TextEditor(text: $rawConfigText)
                .padding()
                .navigationTitle("Import Config")
                .navigationBarItems(
                    leading: Button("Cancel") { isPresented = false },
                    trailing: Button("Save") {
                        ConfigManager.shared.importConfig(from: rawConfigText)
                        isPresented = false
                    }
                )
        }
    }
}

struct AddProviderView: View {
    @Binding var isPresented: Bool
    
    let providers = [
        ("Google Drive", "drive", "externaldrive.fill"),
        ("Dropbox", "dropbox", "shippingbox.fill"),
        ("MEGA", "mega", "m.circle.fill"),
        ("Yandex", "yandex", "y.circle.fill"),
        ("Proton Drive", "protondrive", "lock.shield.fill"),
        ("Custom S3", "s3", "cylinder.split.1x2.fill")
    ]
    
    var body: some View {
        NavigationView {
            List(providers, id: \.1) { provider in
                NavigationLink(destination: ProviderSetupForm(providerName: provider.0, providerType: provider.1, isPresented: $isPresented)) {
                    HStack {
                        Image(systemName: provider.2)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text(provider.0)
                    }
                }
            }
            .navigationTitle("Add Provider")
            .navigationBarItems(leading: Button("Cancel") { isPresented = false })
        }
    }
}

struct ProviderSetupForm: View {
    let providerName: String
    let providerType: String
    @Binding var isPresented: Bool
    
    @State private var remoteName = ""
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var user = ""
    @State private var pass = ""
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                TextField("Remote Name (e.g. MyDrive)", text: $remoteName)
            }
            
            if providerType == "drive" || providerType == "dropbox" {
                Section(header: Text("OAuth Credentials (Optional)")) {
                    TextField("Client ID", text: $clientId)
                    TextField("Client Secret", text: $clientSecret)
                }
            } else if providerType == "mega" {
                Section(header: Text("Credentials")) {
                    TextField("Email", text: $user)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $pass)
                }
            }
            
            Button("Save") {
                var params: [String: String] = [:]
                if providerType == "drive" || providerType == "dropbox" {
                    if !clientId.isEmpty { params["client_id"] = clientId }
                    if !clientSecret.isEmpty { params["client_secret"] = clientSecret }
                } else if providerType == "mega" {
                    params["user"] = user
                    params["pass"] = pass
                }
                
                ConfigManager.shared.addRemote(name: remoteName, type: providerType, parameters: params) { success in
                    if success {
                        isPresented = false
                    }
                }
            }
            .disabled(remoteName.isEmpty)
        }
        .navigationTitle("Setup \(providerName)")
    }
}

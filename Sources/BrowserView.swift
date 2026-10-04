import SwiftUI

struct BrowserView: View {
    @StateObject private var viewModel: BrowserViewModel
    @State private var itemToShare: URL?
    @State private var showingError = false
    
    init(remoteName: String, currentPath: String) {
        _viewModel = StateObject(wrappedValue: BrowserViewModel(remoteName: remoteName, currentPath: currentPath))
    }
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.items) { item in
                    if item.IsDir {
                        NavigationLink(destination: BrowserView(remoteName: viewModel.remoteName, currentPath: (viewModel.currentPath.isEmpty ? item.Name : "\(viewModel.currentPath)/\(item.Name)"))) {
                            ItemRow(item: item)
                        }
                    } else {
                        Button(action: {
                            downloadAndShare(item: item)
                        }) {
                            ItemRow(item: item)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                viewModel.fetchItems()
            }
            
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView("Loading...")
                    .padding()
                    .background(Material.regular)
                    .cornerRadius(10)
            }
            
            if viewModel.isDownloading {
                ProgressView("Downloading...")
                    .padding()
                    .background(Material.regular)
                    .cornerRadius(10)
            }
        }
        .navigationTitle(viewModel.currentPath.isEmpty ? viewModel.remoteName : URL(fileURLWithPath: viewModel.currentPath).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.fetchItems()
            }
        }
        .sheet(item: Binding<ShareURL?>(
            get: { itemToShare.map { ShareURL(url: $0) } },
            set: { itemToShare = $0?.url }
        )) { shareURL in
            ActivityViewController(activityItems: [shareURL.url])
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            if newValue != nil {
                showingError = true
            }
        }
    }
    
    func downloadAndShare(item: RcloneItem) {
        viewModel.downloadFile(item: item) { url in
            if let url = url {
                self.itemToShare = url
            }
        }
    }
}

struct ShareURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ItemRow: View {
    let item: RcloneItem
    
    var body: some View {
        HStack {
            Image(systemName: item.IsDir ? "folder.fill" : "doc.text")
                .foregroundColor(item.IsDir ? .blue : .gray)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(item.Name)
                    .font(.headline)
                
                if !item.IsDir {
                    Text(ByteCountFormatter.string(fromByteCount: item.Size, countStyle: .file))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = "generate"
    @EnvironmentObject var modelManager: ModelManager
    @EnvironmentObject var generationService: GenerationService
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } content: {
            switch selectedTab {
            case "generate":
                GenerationView()
            case "gallery":
                GalleryView()
            case "models":
                ModelManagementView()
            case "presets":
                PresetsView()
            case "settings":
                SettingsView()
            default:
                GenerationView()
            }
        } detail: {
            // Detail view for selected items
            if selectedTab == "gallery" {
                ImageDetailView()
            } else {
                EmptyView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Generate") {
                    // Trigger generation from toolbar
                }
                .keyboardShortcut("g", modifiers: [.command])
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct SidebarView: View {
    @Binding var selectedTab: String
    @EnvironmentObject var modelManager: ModelManager
    @EnvironmentObject var generationService: GenerationService
    
    var body: some View {
        List(selection: $selectedTab) {
            Section("Main") {
                NavigationLink(value: "generate") {
                    Label("Generate", systemImage: "wand.and.stars")
                }
                
                NavigationLink(value: "gallery") {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                }
            }
            
            Section("Management") {
                NavigationLink(value: "models") {
                    Label("Models", systemImage: "cpu")
                }
                
                NavigationLink(value: "presets") {
                    Label("Presets", systemImage: "bookmark")
                }
            }
            
            Section("System") {
                NavigationLink(value: "settings") {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("MFLUX")
        
        // Status bar at bottom
        VStack {
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(generationService.isGenerating ? "Generating..." : "Ready")
                        .font(.caption)
                        .foregroundColor(generationService.isGenerating ? .orange : .green)
                }
                
                Spacer()
                
                if generationService.isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ModelManagementView: View {
    @EnvironmentObject var modelManager: ModelManager
    @State private var hfToken = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Model Management")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Refresh") {
                    modelManager.refreshModels()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
            .padding()
            
            // Authentication Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: modelManager.isAuthenticated ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundColor(modelManager.isAuthenticated ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hugging Face Authentication")
                            .font(.headline)
                        
                        if modelManager.isAuthenticated {
                            HStack {
                                Text("✅ Authenticated")
                                    .foregroundColor(.green)
                                if !modelManager.userEmail.isEmpty {
                                    Text("(\(modelManager.userEmail))")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                        } else {
                            Text("⚠️ Authentication required to download FLUX models")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    if modelManager.isAuthenticated {
                        Button("Sign Out") {
                            modelManager.clearAuthentication()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Sign In") {
                            modelManager.showAuthSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                if !modelManager.isAuthenticated {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To download FLUX models:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("1.")
                            Button("Request access to FLUX models") {
                                modelManager.requestAccess()
                            }
                            .buttonStyle(.link)
                        }
                        
                        HStack {
                            Text("2.")
                            Button("Get your access token") {
                                modelManager.openTokenSettings()
                            }
                            .buttonStyle(.link)
                        }
                        
                        Text("3. Use the 'Sign In' button above to authenticate")
                    }
                    .padding(.leading, 16)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Models List
            List {
                ForEach(modelManager.availableModels, id: \.name) { model in
                    ModelRowView(model: model)
                }
            }
        }
        .sheet(isPresented: $modelManager.showAuthSheet) {
            HuggingFaceAuthSheet(token: $hfToken)
                .environmentObject(modelManager)
        }
        .alert(isPresented: $modelManager.showDownloadErrorAlert) {
            Alert(
                title: Text("Download Failed"),
                message: Text(modelManager.downloadErrorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ModelRowView: View {
    let model: AIModel
    @EnvironmentObject var modelManager: ModelManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Size: \(model.size)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Type: \(model.type.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if model.isDownloaded {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Downloaded")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    if modelManager.isAuthenticated {
                        if modelManager.isDownloading && modelManager.downloadingModelName == model.name {
                            VStack(spacing: 8) {
                                // Progress bar with percentage
                                VStack(spacing: 4) {
                                    HStack {
                                        ProgressView(value: modelManager.downloadProgress, total: 1.0)
                                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                            .frame(width: 120, height: 8)
                                        
                                        Text("\(Int(modelManager.downloadProgress * 100))%")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                            .frame(width: 40, alignment: .trailing)
                                    }
                                    
                                    Text(modelManager.downloadStatus.isEmpty ? "Downloading \(model.name)..." : modelManager.downloadStatus)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        } else {
                            Button("Download") {
                                modelManager.downloadModel(model)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Button("Sign In Required") {
                            modelManager.showAuthSheet = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                    }
                }
                
                if model.isDownloaded {
                    Button("Remove") {
                        modelManager.removeModel(model)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct HuggingFaceAuthSheet: View {
    @Binding var token: String
    @EnvironmentObject var modelManager: ModelManager
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthenticating = false
    
    var body: some View {
        VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Hugging Face Authentication")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your Hugging Face access token to download FLUX models")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Steps to get your token:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("1.")
                            Button("Request access to FLUX models") {
                                modelManager.requestAccess()
                            }
                            .buttonStyle(.link)
                        }
                        
                        HStack {
                            Text("2.")
                            Button("Generate access token") {
                                modelManager.openTokenSettings()
                            }
                            .buttonStyle(.link)
                        }
                        
                        Text("3. Copy your token and paste it below")
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Access Token:")
                        .font(.headline)
                    
                    SecureField("hf_...", text: $token)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .disabled(isAuthenticating)
                    
                    if let error = modelManager.authenticationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    if isAuthenticating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Validating token...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isAuthenticating)
                    
                    Spacer()
                    
                    Button("Authenticate") {
                        isAuthenticating = true
                        modelManager.authenticateWithToken(token)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAuthenticating)
                }
            }
            .padding()
            .frame(width: 500, height: 650)
            .onChange(of: modelManager.isAuthenticated) { authenticated in
                if authenticated {
                    isAuthenticating = false
                    dismiss()
                }
            }
            .onChange(of: modelManager.authenticationError) { error in
                if error != nil {
                    isAuthenticating = false
                }
            }
    }
}

struct PresetsView: View {
    @State private var presets: [GenerationPreset] = []
    @State private var showingAddPreset = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Presets")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Add Preset") {
                    showingAddPreset = true
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            .padding()
            
            if presets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No presets yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Create presets to save your favorite generation settings")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Create Your First Preset") {
                        showingAddPreset = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(presets, id: \.id) { preset in
                        PresetRowView(preset: preset)
                    }
                    .onDelete(perform: deletePresets)
                }
            }
        }
        .sheet(isPresented: $showingAddPreset) {
            AddPresetView()
        }
    }
    
    private func deletePresets(offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
    }
}

struct PresetRowView: View {
    let preset: GenerationPreset
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.headline)
                
                Text(preset.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Model: \(preset.model)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Steps: \(preset.steps)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Use") {
                // TODO: Apply preset
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

struct AddPresetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var model = "schnell"
    @State private var steps = 20
    @State private var guidanceScale = 7.5
    
    var body: some View {
        NavigationView {
            Form {
                Section("Preset Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Generation Settings") {
                    Picker("Model", selection: $model) {
                        Text("Schnell").tag("schnell")
                        Text("Dev").tag("dev")
                    }
                    
                    HStack {
                        Text("Steps: \(steps)")
                        Slider(value: .constant(Double(steps)), in: 1...50, step: 1)
                    }
                    
                    HStack {
                        Text("Guidance Scale: \(guidanceScale, specifier: "%.1f")")
                        Slider(value: $guidanceScale, in: 1...20, step: 0.5)
                    }
                }
            }
            .navigationTitle("Add Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // TODO: Save preset
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

struct ImageDetailView: View {
    var body: some View {
        VStack {
            Text("Image Details")
                .font(.title)
                .padding()
            
            Spacer()
            
            Text("Select an image from the gallery to view details")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
} 
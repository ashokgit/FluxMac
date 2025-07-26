import SwiftUI

// MARK: - Design System
struct DesignSystem {
    // Colors - Now properly supporting dark mode
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.secondary
        static let accent = Color.purple
        
        // Adaptive backgrounds
        static let background = Color(NSColor.windowBackgroundColor)
        static let surface = Color(NSColor.controlBackgroundColor)
        static let surfaceSecondary = Color(NSColor.separatorColor).opacity(0.1)
        static let cardBackground = Color(NSColor.controlBackgroundColor)
        
        // Adaptive text colors
        static let text = Color(NSColor.labelColor)
        static let textSecondary = Color(NSColor.secondaryLabelColor)
        static let textTertiary = Color(NSColor.tertiaryLabelColor)
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Borders and separators
        static let border = Color(NSColor.separatorColor)
        static let borderSecondary = Color(NSColor.separatorColor).opacity(0.5)
    }
    
    // Typography
    struct Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let title = Font.system(.title, design: .rounded, weight: .semibold)
        static let title2 = Font.system(.title2, design: .rounded, weight: .medium)
        static let headline = Font.system(.headline, design: .rounded, weight: .medium)
        static let body = Font.system(.body, design: .default)
        static let caption = Font.system(.caption, design: .default)
        static let caption2 = Font.system(.caption2, design: .default)
    }
    
    // Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
    }
}

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
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        .background(DesignSystem.Colors.background)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(ModernToolbarButtonStyle())
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Generate") {
                    selectedTab = "generate"
                }
                .keyboardShortcut("g", modifiers: [.command])
                .buttonStyle(PrimaryToolbarButtonStyle())
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
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "wand.and.stars.inverse")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MFLUX")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Text("AI Image Generator")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.lg)
            }
            
            // Navigation
            List(selection: $selectedTab) {
                Section {
                    SidebarNavItem(
                        id: "generate",
                        icon: "wand.and.stars",
                        title: "Generate",
                        subtitle: "Create new images",
                        isSelected: selectedTab == "generate"
                    )
                    
                    SidebarNavItem(
                        id: "gallery",
                        icon: "photo.on.rectangle",
                        title: "Gallery",
                        subtitle: "View your creations",
                        isSelected: selectedTab == "gallery"
                    )
                } header: {
                    SectionHeader(title: "Main")
                }
                
                Section {
                    SidebarNavItem(
                        id: "models",
                        icon: "cpu",
                        title: "Models",
                        subtitle: "Manage AI models",
                        isSelected: selectedTab == "models"
                    )
                    
                    SidebarNavItem(
                        id: "presets",
                        icon: "bookmark",
                        title: "Presets",
                        subtitle: "Saved configurations",
                        isSelected: selectedTab == "presets"
                    )
                } header: {
                    SectionHeader(title: "Management")
                }
                
                Section {
                    SidebarNavItem(
                        id: "settings",
                        icon: "gear",
                        title: "Settings",
                        subtitle: "App preferences",
                        isSelected: selectedTab == "settings"
                    )
                } header: {
                    SectionHeader(title: "System")
                }
            }
            .listStyle(SidebarListStyle())
            .scrollContentBackground(.hidden)
            
            Spacer()
            
            // Status Card
            StatusCard()
                .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.surface)
    }
}

struct SidebarNavItem: View {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    
    var body: some View {
        NavigationLink(value: id) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.text)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(DesignSystem.Typography.caption2)
            .fontWeight(.semibold)
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xs)
    }
}

struct StatusCard: View {
    @EnvironmentObject var generationService: GenerationService
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: generationService.isGenerating ? "gear" : "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(generationService.isGenerating ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
                    .rotationEffect(.degrees(generationService.isGenerating ? 360 : 0))
                    .animation(
                        generationService.isGenerating ? 
                            Animation.linear(duration: 2).repeatForever(autoreverses: false) : 
                            Animation.default,
                        value: generationService.isGenerating
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Status")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(generationService.isGenerating ? "Generating..." : "Ready")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(generationService.isGenerating ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
                }
                
                Spacer()
            }
            
            if generationService.isGenerating {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                    .scaleEffect(y: 0.5)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
                )
        )
    }
}

// MARK: - Button Styles
struct ModernToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DesignSystem.Colors.text)
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(configuration.isPressed ? DesignSystem.Colors.surface : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
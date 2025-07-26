import SwiftUI

@main
struct FluxMacApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState.modelManager)
                .environmentObject(appState.generationService)
                .frame(minWidth: 1200, minHeight: 800)
                .background(Color(NSColor.windowBackgroundColor))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    // TODO: Implement update checking
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])
            }
            CommandGroup(after: .systemServices) {
                Button("Generate from Selection") {
                    // TODO: Implement services menu integration
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState.modelManager)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var modelManager: ModelManager
    @State private var selectedTab = "general"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag("general")
            
            ModelSettingsView()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
                .tag("models")
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag("advanced")
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("defaultOutputPath") private var defaultOutputPath = ""
    
    var body: some View {
        Form {
            Section("Generation") {
                Toggle("Auto-save generated images", isOn: $autoSave)
                
                HStack {
                    Text("Default output folder:")
                    Spacer()
                    Button("Choose...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        
                        if panel.runModal() == .OK {
                            defaultOutputPath = panel.url?.path ?? ""
                        }
                    }
                }
                
                if !defaultOutputPath.isEmpty {
                    Text(defaultOutputPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Performance") {
                Toggle("Use Metal acceleration", isOn: .constant(true))
                    .disabled(true)
                
                Toggle("Enable background processing", isOn: .constant(true))
                    .disabled(true)
            }
        }
    }
}

struct ModelSettingsView: View {
    @EnvironmentObject var modelManager: ModelManager
    
    var body: some View {
        VStack {
            Text("Model Management")
                .font(.title2)
                .padding()
            
            List {
                ForEach(modelManager.availableModels, id: \.name) { model in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(model.name)
                                .font(.headline)
                            Text(model.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if model.isDownloaded {
                            Text("Downloaded")
                                .foregroundColor(.green)
                        } else {
                            Button("Download") {
                                modelManager.downloadModel(model)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("maxConcurrentGenerations") private var maxConcurrent = 2
    @AppStorage("memoryLimit") private var memoryLimit = 8
    @AppStorage("enableDebugLogging") private var enableDebugLogging = false
    
    var body: some View {
        Form {
            Section("Performance") {
                HStack {
                    Text("Max concurrent generations:")
                    Spacer()
                    Picker("", selection: $maxConcurrent) {
                        Text("1").tag(1)
                        Text("2").tag(2)
                        Text("3").tag(3)
                        Text("4").tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                
                HStack {
                    Text("Memory limit (GB):")
                    Spacer()
                    Picker("", selection: $memoryLimit) {
                        Text("4").tag(4)
                        Text("8").tag(8)
                        Text("16").tag(16)
                        Text("32").tag(32)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
            }
            
            Section("Debugging") {
                Toggle("Enable debug logging", isOn: $enableDebugLogging)
                
                Button("Export logs...") {
                    // TODO: Implement log export
                }
            }
        }
    }
}

// MARK: - App State Management

class AppState: ObservableObject {
    let modelManager: ModelManager
    let generationService: GenerationService
    
    init() {
        self.modelManager = ModelManager()
        self.generationService = GenerationService(modelManager: self.modelManager)
    }
} 
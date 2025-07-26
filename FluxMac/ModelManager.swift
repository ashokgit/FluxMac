import Foundation
import SwiftUI

class ModelManager: ObservableObject {
    @Published var availableModels: [AIModel] = []
    @Published var downloadedModels: [AIModel] = []
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatus: String = ""
    @Published var downloadingModelName: String? = nil
    
    // Error handling for download
    @Published var downloadErrorMessage: String? = nil
    @Published var showDownloadErrorAlert: Bool = false
    
    // Hugging Face Authentication
    @Published var isAuthenticated = false
    @Published var showAuthSheet = false
    @Published var authenticationError: String?
    @Published var userEmail: String = ""
    
    private let modelsDirectory: URL
    private let pythonBridge: PythonBridge
    private var huggingFaceToken: String?
    
    init() {
        // Create models directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        modelsDirectory = appSupport.appendingPathComponent("FluxMac/Models")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        
        pythonBridge = PythonBridge()
        
        loadAvailableModels()
        loadDownloadedModels()
        checkAuthentication()
    }
    
    func loadAvailableModels() {
        availableModels = [
            AIModel(
                name: "Schnell",
                description: "Fast generation model optimized for speed",
                type: .schnell,
                size: "2.1 GB",
                url: "https://huggingface.co/mflux-ai/schnell",
                isDownloaded: false
            ),
            AIModel(
                name: "Dev",
                description: "Development model with advanced features",
                type: .dev,
                size: "4.2 GB",
                url: "https://huggingface.co/mflux-ai/dev",
                isDownloaded: false
            )
        ]
        
        // Update download status
        updateDownloadStatus()
    }
    
    func loadDownloadedModels() {
        do {
            let modelFiles = try FileManager.default.contentsOfDirectory(at: modelsDirectory, includingPropertiesForKeys: nil)
            downloadedModels = modelFiles.compactMap { url in
                guard let model = availableModels.first(where: { $0.name.lowercased() == url.deletingPathExtension().lastPathComponent.lowercased() }) else {
                    return nil
                }
                var downloadedModel = model
                downloadedModel.isDownloaded = true
                return downloadedModel
            }
        } catch {
            print("Error loading downloaded models: \(error)")
        }
    }
    
    func updateDownloadStatus() {
        for i in 0..<availableModels.count {
            let model = availableModels[i]
            // Check if model is actually downloaded in MFLUX cache
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            // Use the actual model names as they appear in the cache
            let modelMapping = ["schnell": "schnell", "dev": "dev"]
            let modelId = modelMapping[model.type.rawValue] ?? model.type.rawValue
            let mfluxCache = homeDir.appendingPathComponent(".cache/mflux/\(modelId)")
            
            if FileManager.default.fileExists(atPath: mfluxCache.path) {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: mfluxCache.path)
                    let hasModelFiles = contents.contains { file in
                        file.hasSuffix(".safetensors") || file.hasSuffix(".bin") || file.hasSuffix(".json")
                    }
                    availableModels[i].isDownloaded = hasModelFiles
                } catch {
                    availableModels[i].isDownloaded = false
                }
            } else {
                availableModels[i].isDownloaded = false
            }
        }
    }
    
    func downloadModel(_ model: AIModel) {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadingModelName = model.name
        downloadProgress = 0.0
        downloadStatus = "Starting download..."
        downloadErrorMessage = nil
        showDownloadErrorAlert = false
        
        // Start download in background
        Task {
            do {
                try await downloadModelAsync(model)
                
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.downloadingModelName = nil
                    self.downloadProgress = 0.0
                    self.loadDownloadedModels()
                    self.updateDownloadStatus()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.downloadingModelName = nil
                    self.downloadProgress = 0.0
                    self.downloadErrorMessage = "Model download failed: \(error.localizedDescription)"
                    self.showDownloadErrorAlert = true
                    print("Download failed: \(error)")
                }
            }
        }
    }
    
    private func downloadModelAsync(_ model: AIModel) async throws {
        guard isAuthenticated else {
            throw NSError(domain: "ModelManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Please authenticate with Hugging Face first"])
        }
        
        // Use real MFLUX download
        try await pythonBridge.downloadModel(model.type.rawValue) { progress, status in
            DispatchQueue.main.async {
                self.downloadProgress = progress
                self.downloadStatus = status
            }
        }
        
        // Mark as downloaded (MFLUX handles the actual file storage)
        let modelFile = modelsDirectory.appendingPathComponent("\(model.name.lowercased()).downloaded")
        try "Downloaded".write(to: modelFile, atomically: true, encoding: .utf8)
    }
    
    func removeModel(_ model: AIModel) {
        let modelFile = modelsDirectory.appendingPathComponent("\(model.name.lowercased()).downloaded")
        
        do {
            try FileManager.default.removeItem(at: modelFile)
            
            // Also remove MFLUX cache if it exists
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            // Use the actual model names as they appear in the cache
            let modelMapping = ["schnell": "schnell", "dev": "dev"]
            let modelId = modelMapping[model.type.rawValue] ?? model.type.rawValue
            let mfluxCache = homeDir.appendingPathComponent(".cache/mflux")
            let modelCacheDir = mfluxCache.appendingPathComponent(modelId)
            
            if FileManager.default.fileExists(atPath: modelCacheDir.path) {
                try? FileManager.default.removeItem(at: modelCacheDir)
            }
            
            loadDownloadedModels()
            updateDownloadStatus()
        } catch {
            print("Error removing model: \(error)")
        }
    }
    
    func refreshModels() {
        loadAvailableModels()
        loadDownloadedModels()
    }
    
    func getModelPath(for model: AIModel) -> URL? {
        // Check if model is actually downloaded in MFLUX cache
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        // Use the actual model names as they appear in the cache
        let modelMapping = ["schnell": "schnell", "dev": "dev"]
        let modelId = modelMapping[model.type.rawValue] ?? model.type.rawValue
        let mfluxCache = homeDir.appendingPathComponent(".cache/mflux/\(modelId)")
        
        if FileManager.default.fileExists(atPath: mfluxCache.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: mfluxCache.path)
                let hasModelFiles = contents.contains { file in
                    file.hasSuffix(".safetensors") || file.hasSuffix(".bin") || file.hasSuffix(".json")
                }
                return hasModelFiles ? mfluxCache : nil
            } catch {
                return nil
            }
        }
        return nil
    }
    
    func getDiskUsage() -> String {
        do {
            let resourceValues = try modelsDirectory.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            let size = resourceValues.totalFileAllocatedSize ?? 0
            return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        } catch {
            return "Unknown"
        }
    }
    
    private func checkAuthentication() {
        // Check if user is already authenticated
        if let token = getStoredToken(), !token.isEmpty {
            huggingFaceToken = token
            isAuthenticated = true
            validateTokenAsync()
        }
    }
    
    private func getStoredToken() -> String? {
        return UserDefaults.standard.string(forKey: "HuggingFaceToken")
    }
    
    private func storeToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "HuggingFaceToken")
        huggingFaceToken = token
    }
    
    func authenticateWithToken(_ token: String) {
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            authenticationError = "Please enter a valid token"
            return
        }
        
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear any previous error
        authenticationError = nil
        
        Task {
            do {
                print("🔐 Validating Hugging Face token...")
                let isValid = try await validateToken(trimmedToken)
                
                DispatchQueue.main.async {
                    if isValid {
                        print("✅ Token validation successful")
                        self.storeToken(trimmedToken)
                        self.isAuthenticated = true
                        self.showAuthSheet = false
                        self.authenticationError = nil
                        self.authenticateInPython(trimmedToken)
                    } else {
                        print("❌ Token validation failed")
                        self.authenticationError = "Invalid token. Please check your token and try again."
                    }
                }
            } catch {
                print("❌ Token validation error: \(error)")
                DispatchQueue.main.async {
                    self.authenticationError = "Failed to validate token: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func validateToken(_ token: String) async throws -> Bool {
        // Validate token by testing access to the FLUX model instead of whoami
        guard let url = URL(string: "https://huggingface.co/api/models/black-forest-labs/FLUX.1-schnell") else {
            throw NSError(domain: "ModelManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("FluxMac/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 HF API Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Parse model info to confirm access
                    if let modelData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📋 HF API Response: Model access confirmed")
                        
                        // Set a generic user name since we can't get user info
                        DispatchQueue.main.async {
                            self.userEmail = "FLUX User"
                        }
                        return true
                    }
                    return true
                } else if httpResponse.statusCode == 401 {
                    throw NSError(domain: "ModelManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid token or insufficient permissions"])
                } else {
                    throw NSError(domain: "ModelManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)"])
                }
            }
            return false
        } catch {
            print("🚨 HF API Error: \(error)")
            throw error
        }
    }
    
    private func validateTokenAsync() {
        guard let token = huggingFaceToken else { return }
        
        Task {
            do {
                let isValid = try await validateToken(token)
                DispatchQueue.main.async {
                    self.isAuthenticated = isValid
                    if !isValid {
                        self.clearAuthentication()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    private func authenticateInPython(_ token: String) {
        // Set up authentication in the Python environment
        Task {
            await pythonBridge.setHuggingFaceToken(token)
        }
    }
    
    func clearAuthentication() {
        UserDefaults.standard.removeObject(forKey: "HuggingFaceToken")
        huggingFaceToken = nil
        isAuthenticated = false
        userEmail = ""
        authenticationError = nil
    }
    
    func requestAccess() {
        // Open Hugging Face FLUX model page for access request
        if let url = URL(string: "https://huggingface.co/black-forest-labs/FLUX.1-schnell") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openTokenSettings() {
        // Open Hugging Face token settings
        if let url = URL(string: "https://huggingface.co/settings/tokens") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct AIModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let type: ModelType
    let size: String
    let url: String
    var isDownloaded: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        lhs.name == rhs.name
    }
}

enum ModelType: String, CaseIterable {
    case schnell = "schnell"
    case dev = "dev"
    
    var displayName: String {
        switch self {
        case .schnell:
            return "Schnell"
        case .dev:
            return "Dev"
        }
    }
} 
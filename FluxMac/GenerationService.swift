import Foundation
import SwiftUI
import AppKit

class GenerationService: ObservableObject {
    @Published var isGenerating = false
    @Published var currentImage: NSImage?
    @Published var generatedImages: [GeneratedImage] = []
    @Published var generationProgress: Double = 0.0
    @Published var currentStep = ""
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    
    private let pythonBridge: PythonBridge
    private let modelManager: ModelManager
    private var generationQueue: [GenerationRequest] = []
    private var currentRequest: GenerationRequest?
    
    init(modelManager: ModelManager) {
        self.modelManager = modelManager
        pythonBridge = PythonBridge()
        loadGeneratedImages()
    }
    
    func generateImage(with parameters: GenerationParameters) {
        // Check if model is available
        guard let model = modelManager.availableModels.first(where: { $0.name.lowercased() == parameters.model.lowercased() }) else {
            showError("Model '\(parameters.model)' not found")
            return
        }
        
        guard model.isDownloaded else {
            showError("Model '\(parameters.model)' is not downloaded. Please download it from the Models tab first.")
            return
        }
        
        let request = GenerationRequest(parameters: parameters)
        generationQueue.append(request)
        
        if !isGenerating {
            processNextRequest()
        }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showErrorAlert = true
        }
    }
    
    private func processNextRequest() {
        guard !generationQueue.isEmpty && !isGenerating else { return }
        
        currentRequest = generationQueue.removeFirst()
        isGenerating = true
        generationProgress = 0.0
        currentStep = "Initializing AI model..."
        errorMessage = nil
        
        guard let request = currentRequest else { return }
        
        Task {
            do {
                let result = try await generateImageAsync(request)
                
                DispatchQueue.main.async {
                    self.handleGenerationResult(result)
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleGenerationError(error)
                }
            }
        }
    }
    
    private func generateImageAsync(_ request: GenerationRequest) async throws -> GenerationResult {
        let params = request.parameters
        
        // Update progress
        DispatchQueue.main.async {
            self.currentStep = "Loading model: \(params.model)"
            self.generationProgress = 0.1
        }
        
        // Check if model file exists
        guard let model = modelManager.availableModels.first(where: { $0.name.lowercased() == params.model.lowercased() }),
              let modelPath = modelManager.getModelPath(for: model) else {
            throw GenerationError.modelNotFound(params.model)
        }
        
        DispatchQueue.main.async {
            self.currentStep = "Initializing generation..."
            self.generationProgress = 0.2
        }
        
        // Try to generate with real AI model
        do {
            let imageData = try await pythonBridge.generateImageWithMFLUX(
                prompt: params.prompt,
                model: params.model,
                steps: params.steps,
                guidanceScale: params.guidanceScale,
                seed: params.seed,
                width: params.width,
                height: params.height
            )
            
            guard let image = NSImage(data: imageData) else {
                throw GenerationError.invalidImageData
            }
            
            let generatedImage = GeneratedImage(
                id: UUID(),
                prompt: params.prompt,
                negativePrompt: params.negativePrompt,
                model: params.model,
                steps: params.steps,
                guidanceScale: params.guidanceScale,
                seed: params.seed ?? Int.random(in: 1...999999999),
                width: params.width,
                height: params.height,
                createdAt: Date(),
                nsImage: image
            )
            
            return GenerationResult(image: generatedImage, request: request)
            
        } catch {
            // If real AI generation fails, show a helpful error message
            if error is PythonBridgeError {
                throw error
            } else {
                throw GenerationError.generationFailed("AI model execution failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleGenerationResult(_ result: GenerationResult) {
        isGenerating = false
        generationProgress = 1.0
        currentStep = "Generation complete!"
        
        currentImage = result.image.nsImage
        generatedImages.insert(result.image, at: 0)
        
        // Save to disk
        saveGeneratedImage(result.image)
        
        // Clear progress after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.generationProgress = 0.0
            self.currentStep = ""
        }
        
        // Process next request if any
        if !generationQueue.isEmpty {
            processNextRequest()
        }
    }
    
    private func handleGenerationError(_ error: Error) {
        isGenerating = false
        generationProgress = 0.0
        currentStep = ""
        
        let errorMessage = if let genError = error as? GenerationError {
            genError.localizedDescription
        } else if let bridgeError = error as? PythonBridgeError {
            bridgeError.localizedDescription
        } else {
            "Generation failed: \(error.localizedDescription)"
        }
        
        showError(errorMessage)
        
        // Process next request if any
        if !generationQueue.isEmpty {
            processNextRequest()
        }
    }
    

    
    private func saveGeneratedImage(_ image: GeneratedImage) {
        let imagesDirectory = getImagesDirectory()
        
        do {
            let imageData = image.nsImage.tiffRepresentation
            let imageFile = imagesDirectory.appendingPathComponent("\(image.id.uuidString).tiff")
            try imageData?.write(to: imageFile)
            
            // Save metadata
            let metadata = ImageMetadata(
                id: image.id,
                prompt: image.prompt,
                negativePrompt: image.negativePrompt,
                model: image.model,
                steps: image.steps,
                guidanceScale: image.guidanceScale,
                seed: image.seed,
                width: image.width,
                height: image.height,
                createdAt: image.createdAt,
                filePath: imageFile.path
            )
            
            saveMetadata(metadata)
        } catch {
            print("Error saving image: \(error)")
        }
    }
    
    private func loadGeneratedImages() {
        let imagesDirectory = getImagesDirectory()
        let metadataDirectory = getMetadataDirectory()
        
        do {
            let metadataFiles = try FileManager.default.contentsOfDirectory(at: metadataDirectory, includingPropertiesForKeys: nil)
            
            for metadataFile in metadataFiles {
                if let metadata = loadMetadata(from: metadataFile) {
                    if let image = loadImageFromMetadata(metadata) {
                        generatedImages.append(image)
                    }
                }
            }
            
            // Sort by creation date
            generatedImages.sort { $0.createdAt > $1.createdAt }
        } catch {
            print("Error loading generated images: \(error)")
        }
    }
    
    private func loadImageFromMetadata(_ metadata: ImageMetadata) -> GeneratedImage? {
        guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: metadata.filePath)),
              let image = NSImage(data: imageData) else {
            return nil
        }
        
        return GeneratedImage(
            id: metadata.id,
            prompt: metadata.prompt,
            negativePrompt: metadata.negativePrompt,
            model: metadata.model,
            steps: metadata.steps,
            guidanceScale: metadata.guidanceScale,
            seed: metadata.seed,
            width: metadata.width,
            height: metadata.height,
            createdAt: metadata.createdAt,
            nsImage: image
        )
    }
    
    private func getImagesDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let imagesDirectory = appSupport.appendingPathComponent("FluxMac/Images")
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        return imagesDirectory
    }
    
    private func getMetadataDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let metadataDirectory = appSupport.appendingPathComponent("FluxMac/Metadata")
        try? FileManager.default.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)
        return metadataDirectory
    }
    
    private func saveMetadata(_ metadata: ImageMetadata) {
        let metadataDirectory = getMetadataDirectory()
        let metadataFile = metadataDirectory.appendingPathComponent("\(metadata.id.uuidString).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(metadata)
            try data.write(to: metadataFile)
        } catch {
            print("Error saving metadata: \(error)")
        }
    }
    
    private func loadMetadata(from url: URL) -> ImageMetadata? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ImageMetadata.self, from: data)
        } catch {
            print("Error loading metadata: \(error)")
            return nil
        }
    }
    
    func cancelGeneration() {
        // TODO: Implement cancellation
        isGenerating = false
        generationProgress = 0.0
        currentStep = ""
        
        if !generationQueue.isEmpty {
            generationQueue.removeAll()
        }
    }
}

struct GenerationParameters {
    let prompt: String
    let negativePrompt: String
    let model: String
    let steps: Int
    let guidanceScale: Double
    let seed: Int?
    let width: Int
    let height: Int
    let batchSize: Int
}

struct GenerationRequest {
    let id = UUID()
    let parameters: GenerationParameters
    let createdAt = Date()
}

struct GenerationResult {
    let image: GeneratedImage
    let request: GenerationRequest
}

struct GeneratedImage: Identifiable {
    let id: UUID
    let prompt: String
    let negativePrompt: String
    let model: String
    let steps: Int
    let guidanceScale: Double
    let seed: Int
    let width: Int
    let height: Int
    let createdAt: Date
    let nsImage: NSImage
}

struct ImageMetadata: Codable {
    let id: UUID
    let prompt: String
    let negativePrompt: String
    let model: String
    let steps: Int
    let guidanceScale: Double
    let seed: Int
    let width: Int
    let height: Int
    let createdAt: Date
    let filePath: String
}

struct GenerationPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let model: String
    let steps: Int
    let guidanceScale: Double
    let seed: Int?
    let width: Int
    let height: Int
}

enum GenerationError: Error, LocalizedError {
    case modelNotFound(String)
    case modelNotDownloaded(String)
    case generationFailed(String)
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let model):
            return "Model '\(model)' not found. Please check if the model is available."
        case .modelNotDownloaded(let model):
            return "Model '\(model)' is not downloaded. Please download it from the Models tab first."
        case .generationFailed(let message):
            return "Image generation failed: \(message)"
        case .invalidImageData:
            return "Failed to create image from generated data. Please try again."
        }
    }
} 
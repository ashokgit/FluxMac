import SwiftUI

struct GenerationView: View {
    @State private var prompt = ""
    @State private var negativePrompt = ""
    @State private var selectedModel = "schnell"
    @State private var steps = 1
    @State private var guidanceScale = 1.0
    @State private var seed: Int? = nil
    @State private var width = 256
    @State private var height = 256
    @State private var batchSize = 1
    @State private var showingAdvanced = false
    
    @EnvironmentObject var generationService: GenerationService
    @EnvironmentObject var modelManager: ModelManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Generate Image")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Clear All") {
                    clearAll()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
            .padding()
            
            Divider()
            
            // Main content
            HStack(spacing: 0) {
                // Left panel - Generation controls
                VStack(spacing: 16) {
                    PromptInputView(
                        prompt: $prompt,
                        negativePrompt: $negativePrompt
                    )
                    
                    ParameterControlsView(
                        selectedModel: $selectedModel,
                        steps: $steps,
                        guidanceScale: $guidanceScale,
                        seed: $seed,
                        width: $width,
                        height: $height,
                        batchSize: $batchSize,
                        showingAdvanced: $showingAdvanced
                    )
                    
                    GenerationControlsView(
                        isGenerating: generationService.isGenerating,
                        onGenerate: generateImage
                    )
                    
                    Spacer()
                }
                .frame(width: 400)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Right panel - Preview and results
                VStack(spacing: 0) {
                    if let currentImage = generationService.currentImage {
                        ImagePreviewView(image: currentImage)
                    } else {
                        PlaceholderView()
                    }
                    
                    if !generationService.generatedImages.isEmpty {
                        Divider()
                        
                        RecentResultsView(images: generationService.generatedImages)
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Generation Error", isPresented: $generationService.showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(generationService.errorMessage ?? "An unknown error occurred during image generation.")
        }
    }
    
    private func generateImage() {
        guard !prompt.isEmpty else { return }
        
        let parameters = GenerationParameters(
            prompt: prompt,
            negativePrompt: negativePrompt,
            model: selectedModel,
            steps: steps,
            guidanceScale: guidanceScale,
            seed: seed,
            width: width,
            height: height,
            batchSize: batchSize
        )
        
        generationService.generateImage(with: parameters)
    }
    
    private func clearAll() {
        prompt = ""
        negativePrompt = ""
        steps = 1
        guidanceScale = 1.0
        seed = nil
        width = 256
        height = 256
        batchSize = 1
    }
}

struct PromptInputView: View {
    @Binding var prompt: String
    @Binding var negativePrompt: String
    @State private var promptHistory: [String] = []
    @State private var showingHistory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Enter your prompt...", text: $prompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    Button(action: { showingHistory.toggle() }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .popover(isPresented: $showingHistory) {
                        PromptHistoryView(history: promptHistory, onSelect: { selectedPrompt in
                            prompt = selectedPrompt
                            showingHistory = false
                        })
                    }
                }
                
                Text("\(prompt.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Negative Prompt")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Things to avoid...", text: $negativePrompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
        }
    }
}

struct ParameterControlsView: View {
    @Binding var selectedModel: String
    @Binding var steps: Int
    @Binding var guidanceScale: Double
    @Binding var seed: Int?
    @Binding var width: Int
    @Binding var height: Int
    @Binding var batchSize: Int
    @Binding var showingAdvanced: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parameters")
                .font(.headline)
            
            // Basic parameters
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Model:")
                    Spacer()
                    Picker("", selection: $selectedModel) {
                        Text("Schnell").tag("schnell")
                        Text("Dev").tag("dev")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                
                HStack {
                    Text("Steps: \(steps)")
                    Spacer()
                    Slider(value: Binding(
                        get: { Double(steps) },
                        set: { steps = Int($0) }
                    ), in: 1...20, step: 1)
                        .frame(width: 200)
                }
                
                if selectedModel == "dev" {
                    HStack {
                        Text("Guidance Scale: \(guidanceScale, specifier: "%.1f")")
                        Spacer()
                        Slider(value: $guidanceScale, in: 1...20, step: 0.5)
                            .frame(width: 200)
                    }
                }
            }
            
            // Advanced parameters
            DisclosureGroup("Advanced", isExpanded: $showingAdvanced) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Seed:")
                        Spacer()
                        HStack {
                            TextField("Random", value: $seed, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            
                            Button("🎲") {
                                seed = Int.random(in: 1...999999999)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    HStack {
                        Text("Width: \(width)")
                        Spacer()
                        Picker("", selection: $width) {
                            Text("512").tag(512)
                            Text("768").tag(768)
                            Text("1024").tag(1024)
                            Text("1280").tag(1280)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Height: \(height)")
                        Spacer()
                        Picker("", selection: $height) {
                            Text("512").tag(512)
                            Text("768").tag(768)
                            Text("1024").tag(1024)
                            Text("1280").tag(1280)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Batch Size: \(batchSize)")
                        Spacer()
                        Picker("", selection: $batchSize) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("4").tag(4)
                            Text("8").tag(8)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct GenerationControlsView: View {
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onGenerate) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    
                    Text(isGenerating ? "Generating..." : "Generate Image")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGenerating)
            .keyboardShortcut(.return, modifiers: [.command])
            
            if isGenerating {
                Button("Cancel") {
                    // TODO: Cancel generation
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
    }
}

struct ImagePreviewView: View {
    let image: NSImage
    
    var body: some View {
        VStack {
            Text("Preview")
                .font(.headline)
                .padding(.top)
            
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            
            HStack {
                Button("Save") {
                    saveImage()
                }
                .buttonStyle(.bordered)
                
                Button("Copy") {
                    copyImage()
                }
                .buttonStyle(.bordered)
                
                Button("Regenerate") {
                    // TODO: Regenerate with same parameters
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func saveImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "generated_image.png"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                // TODO: Save image to URL
            }
        }
    }
    
    private func copyImage() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
}

struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No preview available")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Generate an image to see a preview here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RecentResultsView: View {
    let images: [GeneratedImage]
    @EnvironmentObject var generationService: GenerationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Results")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(images, id: \.id) { image in
                        RecentImageThumbnail(image: image)
                            .onTapGesture {
                                generationService.currentImage = image.nsImage
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(height: 120)
    }
}

struct RecentImageThumbnail: View {
    let image: GeneratedImage
    
    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: image.nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
            
            Text(image.prompt.prefix(20) + (image.prompt.count > 20 ? "..." : ""))
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

struct PromptHistoryView: View {
    let history: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt History")
                .font(.headline)
                .padding()
            
            if history.isEmpty {
                Text("No recent prompts")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(history, id: \.self) { prompt in
                        Button(action: { onSelect(prompt) }) {
                            Text(prompt)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(width: 300, height: 200)
    }
} 
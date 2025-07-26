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
            ModernHeader(
                title: "Generate Image", 
                subtitle: "Create AI-generated artwork with FLUX models",
                onClearAll: clearAll
            )
            
            Divider()
                .background(DesignSystem.Colors.secondary.opacity(0.3))
            
            // Main content
            HStack(spacing: 0) {
                // Left panel - Generation controls
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        PromptInputCard(
                            prompt: $prompt,
                            negativePrompt: $negativePrompt
                        )
                        
                        ParameterControlsCard(
                            selectedModel: $selectedModel,
                            steps: $steps,
                            guidanceScale: $guidanceScale,
                            seed: $seed,
                            width: $width,
                            height: $height,
                            batchSize: $batchSize,
                            showingAdvanced: $showingAdvanced
                        )
                        
                        GenerationControlsCard(
                            isGenerating: generationService.isGenerating,
                            canGenerate: !prompt.isEmpty,
                            onGenerate: generateImage
                        )
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
                .frame(width: 420)
                .background(DesignSystem.Colors.surface)
                
                Divider()
                    .background(DesignSystem.Colors.secondary.opacity(0.3))
                
                // Right panel - Preview and results
                VStack(spacing: 0) {
                    if let currentImage = generationService.currentImage {
                        ImagePreviewCard(image: currentImage)
                    } else {
                        PlaceholderCard()
                    }
                    
                    if !generationService.generatedImages.isEmpty {
                        Divider()
                            .background(DesignSystem.Colors.secondary.opacity(0.3))
                        
                        RecentResultsCard(images: generationService.generatedImages)
                    }
                }
            }
        }
        .background(DesignSystem.Colors.background)
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
        withAnimation(.easeInOut(duration: 0.3)) {
            prompt = ""
            negativePrompt = ""
            steps = 1
            guidanceScale = 1.0
            seed = nil
            width = 512
            height = 512
            batchSize = 1
        }
    }
}

struct ModernHeader: View {
    let title: String
    let subtitle: String
    let onClearAll: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Button("Clear All") {
                onClearAll()
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

struct PromptInputCard: View {
    @Binding var prompt: String
    @Binding var negativePrompt: String
    @State private var promptHistory: [String] = []
    @State private var showingHistory = false
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                CardHeader(
                    icon: "text.quote",
                    title: "Prompt",
                    subtitle: "Describe what you want to generate"
                )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        ModernTextField(
                            text: $prompt,
                            placeholder: "A serene landscape with mountains and a lake at sunset...",
                            axis: .vertical,
                            lineLimit: 3...6
                        )
                        
                        Button(action: { showingHistory.toggle() }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .buttonStyle(IconButtonStyle())
                        .popover(isPresented: $showingHistory) {
                            PromptHistoryView(history: promptHistory, onSelect: { selectedPrompt in
                                prompt = selectedPrompt
                                showingHistory = false
                            })
                        }
                    }
                    
                    HStack {
                        Text("\(prompt.count) characters")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        if prompt.count > 500 {
                            Label("Long prompt", systemImage: "exclamationmark.triangle")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Negative Prompt")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    ModernTextField(
                        text: $negativePrompt,
                        placeholder: "blurry, low quality, distorted...",
                        axis: .vertical,
                        lineLimit: 2...4
                    )
                }
            }
        }
    }
}

struct ParameterControlsCard: View {
    @Binding var selectedModel: String
    @Binding var steps: Int
    @Binding var guidanceScale: Double
    @Binding var seed: Int?
    @Binding var width: Int
    @Binding var height: Int
    @Binding var batchSize: Int
    @Binding var showingAdvanced: Bool
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                CardHeader(
                    icon: "slider.horizontal.3",
                    title: "Parameters",
                    subtitle: "Fine-tune your generation settings"
                )
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Model Selection
                    ParameterRow(
                        label: "Model",
                        description: "Choose the FLUX model variant"
                    ) {
                        Picker("", selection: $selectedModel) {
                            Text("Schnell (Fast)").tag("schnell")
                            Text("Dev (Detailed)").tag("dev")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    
                    // Steps
                    ParameterControlRow(
                        label: "Steps",
                        description: "\(steps) inference steps",
                        value: steps,
                        range: 1...20
                    ) { newValue in
                        steps = newValue
                    }
                    
                    // Guidance Scale (only for dev model)
                    if selectedModel == "dev" {
                        ParameterGuidanceRow(
                            label: "Guidance Scale",
                            description: String(format: "%.1f - Controls prompt adherence", guidanceScale),
                            value: guidanceScale,
                            range: 1.0...20.0,
                            step: 0.5
                        ) { newValue in
                            guidanceScale = newValue
                        }
                    }
                }
                
                // Advanced Settings
                AdvancedParametersSection(
                    isExpanded: $showingAdvanced,
                    seed: $seed,
                    width: $width,
                    height: $height,
                    batchSize: $batchSize
                )
            }
        }
    }
}

struct GenerationControlsCard: View {
    let isGenerating: Bool
    let canGenerate: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        ModernCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                Button(action: onGenerate) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Text(isGenerating ? "Generating..." : "Generate Image")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canGenerate || isGenerating)
                .keyboardShortcut(.return, modifiers: [.command])
                
                if isGenerating {
                    Button("Cancel Generation") {
                        // TODO: Cancel generation
                    }
                    .buttonStyle(DangerButtonStyle())
                }
                
                if !canGenerate && !isGenerating {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(DesignSystem.Colors.warning)
                        Text("Enter a prompt to generate")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
    }
}

struct CardHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct ParameterRow<Content: View>: View {
    let label: String
    let description: String
    let content: Content
    
    init(label: String, description: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(description)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                content
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}



struct ImagePreviewCard: View {
    let image: NSImage
    
    var body: some View {
        VStack {
            Text("Preview")
                .font(DesignSystem.Typography.headline)
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
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Copy") {
                    copyImage()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Regenerate") {
                    // TODO: Regenerate with same parameters
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func saveImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "mflux_image_\(DateFormatter.filenameDateFormatter.string(from: Date())).png"
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            // Convert NSImage to data and save
            if let tiffData = image.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                
                do {
                    try pngData.write(to: url)
                    
                    // Show success notification
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Image Saved"
                        alert.informativeText = "Image saved to \(url.lastPathComponent)"
                        alert.alertStyle = .informational
                        alert.runModal()
                    }
                } catch {
                    // Show error alert
                    let alert = NSAlert()
                    alert.messageText = "Save Failed"
                    alert.informativeText = "Could not save image: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }
    
    private func copyImage() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
}

struct PlaceholderCard: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "photo")
                .font(DesignSystem.Typography.largeIcon)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("No preview available")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.text)
            
            Text("Generate an image to see a preview here")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RecentResultsCard: View {
    let images: [GeneratedImage]
    @EnvironmentObject var generationService: GenerationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Recent Results")
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.md) {
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
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(nsImage: image.nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(DesignSystem.CornerRadius.small)
            
            Text(image.prompt.prefix(20) + (image.prompt.count > 20 ? "..." : ""))
                .font(DesignSystem.Typography.caption)
                .lineLimit(1)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(width: 80)
    }
}



struct PromptHistoryView: View {
    let history: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Prompt History")
                .font(DesignSystem.Typography.headline)
                .padding()
            
            if history.isEmpty {
                Text("No recent prompts")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
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

// MARK: - Modern UI Components

struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let axis: Axis
    let lineLimit: ClosedRange<Int>
    
    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .textFieldStyle(ModernTextFieldStyle())
            .lineLimit(lineLimit)
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
            .font(DesignSystem.Typography.body)
    }
}

struct ModernSlider: View {
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onValueChange: (Double) -> Void
    
    @State private var localValue: Double
    
    init(value: Double, range: ClosedRange<Double>, step: Double = 1, onValueChange: @escaping (Double) -> Void) {
        self.value = value
        self.range = range
        self.step = step
        self.onValueChange = onValueChange
        self._localValue = State(initialValue: value)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(String(format: step == 1 ? "%.0f" : "%.1f", localValue))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(minWidth: 40, alignment: .leading)
                
                Spacer()
                
                Text(String(format: step == 1 ? "%.0f - %.0f" : "%.1f - %.1f", range.lowerBound, range.upperBound))
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Slider(
                value: $localValue,
                in: range,
                step: step
            ) { editing in
                if !editing {
                    onValueChange(localValue)
                }
            }
            .accentColor(DesignSystem.Colors.primary)
        }
        .onChange(of: value) { newValue in
            localValue = newValue
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed ? 
                                [DesignSystem.Colors.primary.opacity(0.8), DesignSystem.Colors.accent.opacity(0.8)] :
                                [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(configuration.isPressed ? DesignSystem.Colors.surface : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.primary.opacity(0.5), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(configuration.isPressed ? DesignSystem.Colors.error.opacity(0.8) : DesignSystem.Colors.error)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(configuration.isPressed ? DesignSystem.Colors.surface : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                            .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}



// MARK: - Typography Extensions

extension DesignSystem.Typography {
    static let largeIcon = Font.system(size: 64, weight: .light)
}

// Fixed Advanced Parameters Section
struct AdvancedParametersSection: View {
    @Binding var isExpanded: Bool
    @Binding var seed: Int?
    @Binding var width: Int
    @Binding var height: Int
    @Binding var batchSize: Int
    
    var body: some View {
        DisclosureGroup("Advanced Settings", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Seed Parameter
                VStack(spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seed")
                                .font(DesignSystem.Typography.body)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            Text("Random seed for reproducible results")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack {
                            TextField("Random", value: $seed, format: .number)
                                .textFieldStyle(ModernTextFieldStyle())
                                .frame(width: 100)
                            
                            Button("🎲") {
                                seed = Int.random(in: 1...999999999)
                            }
                            .buttonStyle(IconButtonStyle())
                        }
                    }
                }
                
                // Dimensions
                HStack(spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Width")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                        
                        Picker("", selection: $width) {
                            Text("512").tag(512)
                            Text("768").tag(768)
                            Text("1024").tag(1024)
                            Text("1280").tag(1280)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Height")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                        
                        Picker("", selection: $height) {
                            Text("512").tag(512)
                            Text("768").tag(768)
                            Text("1024").tag(1024)
                            Text("1280").tag(1280)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                // Batch Size
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Batch Size")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                    
                    Picker("", selection: $batchSize) {
                        Text("1").tag(1)
                        Text("2").tag(2)
                        Text("4").tag(4)
                        Text("8").tag(8)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                }
            }
            .padding(.top, DesignSystem.Spacing.sm)
        }
        .font(DesignSystem.Typography.body)
        .fontWeight(.medium)
    }
}

// Fixed Parameter Row for the specific use cases we have
struct ParameterControlRow: View {
    let label: String
    let description: String
    let value: Int
    let range: ClosedRange<Int>
    let onValueChange: (Int) -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(description)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            ModernSlider(
                value: Double(value),
                range: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            ) { newValue in
                onValueChange(Int(newValue))
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct ParameterGuidanceRow: View {
    let label: String
    let description: String
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onValueChange: (Double) -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(description)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            ModernSlider(
                value: value,
                range: range,
                step: step,
                onValueChange: onValueChange
            )
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
} 

// MARK: - Extensions

extension DateFormatter {
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
} 
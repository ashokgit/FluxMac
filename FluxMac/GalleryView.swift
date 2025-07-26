import SwiftUI

struct GalleryView: View {
    @State private var selectedImages: Set<UUID> = []
    @State private var searchText = ""
    @State private var selectedFilter = "all"
    @State private var sortOrder = SortOrder.dateDescending
    @State private var showingImageDetail = false
    @State private var selectedImage: GeneratedImage?
    @State private var viewMode: ViewMode = .grid
    
    @EnvironmentObject var generationService: GenerationService
    
    private var filteredImages: [GeneratedImage] {
        var images = generationService.generatedImages
        
        // Filter by search text
        if !searchText.isEmpty {
            images = images.filter { image in
                image.prompt.localizedCaseInsensitiveContains(searchText) ||
                image.negativePrompt.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by type
        switch selectedFilter {
        case "schnell":
            images = images.filter { $0.model == "schnell" }
        case "dev":
            images = images.filter { $0.model == "dev" }
        default:
            break
        }
        
        // Sort
        switch sortOrder {
        case .dateDescending:
            images.sort { $0.createdAt > $1.createdAt }
        case .dateAscending:
            images.sort { $0.createdAt < $1.createdAt }
        case .promptAscending:
            images.sort { $0.prompt < $1.prompt }
        case .promptDescending:
            images.sort { $0.prompt > $1.prompt }
        }
        
        return images
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern Header
            GalleryHeader(
                selectedImages: selectedImages,
                onDeleteSelected: deleteSelectedImages,
                onExportSelected: exportSelectedImages,
                onClearSelection: { selectedImages.removeAll() }
            )
            
            Divider()
                .background(DesignSystem.Colors.secondary.opacity(0.3))
            
            // Modern Search and Filter Bar
            GalleryControlsBar(
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                sortOrder: $sortOrder,
                viewMode: $viewMode
            )
            
            Divider()
                .background(DesignSystem.Colors.secondary.opacity(0.3))
            
            // Gallery content
            if filteredImages.isEmpty {
                EmptyGalleryCard(searchText: searchText)
            } else {
                if viewMode == .grid {
                    ModernGalleryGridView(
                        images: filteredImages,
                        selectedImages: $selectedImages,
                        onImageTap: { image in
                            selectedImage = image
                            showingImageDetail = true
                        }
                    )
                } else {
                    ModernGalleryListView(
                        images: filteredImages,
                        selectedImages: $selectedImages,
                        onImageTap: { image in
                            selectedImage = image
                            showingImageDetail = true
                        }
                    )
                }
            }
        }
        .background(DesignSystem.Colors.background)
        .sheet(isPresented: $showingImageDetail) {
            if let image = selectedImage {
                ModernImageDetailSheet(image: image)
            }
        }
    }
    
    private func deleteSelectedImages() {
        let alert = NSAlert()
        alert.messageText = "Delete Selected Images"
        alert.informativeText = "Are you sure you want to delete \(selectedImages.count) image(s)? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Remove from generated images
            generationService.generatedImages.removeAll { image in
                selectedImages.contains(image.id)
            }
            
            // Clear selection
            selectedImages.removeAll()
        }
    }
    
    private func exportSelectedImages() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose export location"
        
        if panel.runModal() == .OK {
            guard let baseURL = panel.url else { return }
            
            let selectedImageObjects = generationService.generatedImages.filter { image in
                selectedImages.contains(image.id)
            }
            
            var successCount = 0
            var failCount = 0
            
            for (index, image) in selectedImageObjects.enumerated() {
                let filename = "mflux_export_\(index + 1)_\(DateFormatter.filenameDateFormatter.string(from: image.createdAt)).png"
                let fileURL = baseURL.appendingPathComponent(filename)
                
                if let tiffData = image.nsImage.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    
                    do {
                        try pngData.write(to: fileURL)
                        successCount += 1
                    } catch {
                        failCount += 1
                    }
                }
            }
            
            // Show completion notification
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Export Complete"
                alert.informativeText = "Exported \(successCount) images successfully" + (failCount > 0 ? ", \(failCount) failed" : "")
                alert.alertStyle = .informational
                alert.runModal()
            }
            
            // Clear selection after successful export
            if successCount > 0 {
                selectedImages.removeAll()
            }
        }
    }
}

// MARK: - Modern Gallery Components

struct GalleryHeader: View {
    let selectedImages: Set<UUID>
    let onDeleteSelected: () -> Void
    let onExportSelected: () -> Void
    let onClearSelection: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Gallery")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text("Browse your AI-generated artwork")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            if !selectedImages.isEmpty {
                HStack(spacing: DesignSystem.Spacing.md) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(selectedImages.count) selected")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Button("Clear") {
                            onClearSelection()
                        }
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Button("Export") {
                            onExportSelected()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Delete") {
                            onDeleteSelected()
                        }
                        .buttonStyle(DangerButtonStyle())
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

struct GalleryControlsBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: String
    @Binding var sortOrder: SortOrder
    @Binding var viewMode: ViewMode
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("Search images...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(DesignSystem.Typography.body)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                                 RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                     .fill(DesignSystem.Colors.surface)
                     .overlay(
                         RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                             .stroke(DesignSystem.Colors.border, lineWidth: 1)
                     )
            )
            .frame(minWidth: 200)
            
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                Text("All Models").tag("all")
                Text("Schnell").tag("schnell")
                Text("Dev").tag("dev")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 180)
            
            // Sort Picker
            Picker("Sort", selection: $sortOrder) {
                Text("Newest").tag(SortOrder.dateDescending)
                Text("Oldest").tag(SortOrder.dateAscending)
                Text("A-Z").tag(SortOrder.promptAscending)
                Text("Z-A").tag(SortOrder.promptDescending)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 180)
            
            // View Mode Toggle
            Picker("View", selection: $viewMode) {
                Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                Image(systemName: "list.bullet").tag(ViewMode.list)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 80)
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

struct ModernGalleryGridView: View {
    let images: [GeneratedImage]
    @Binding var selectedImages: Set<UUID>
    let onImageTap: (GeneratedImage) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: DesignSystem.Spacing.lg)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.lg) {
                ForEach(images, id: \.id) { image in
                    ModernGalleryImageCard(
                        image: image,
                        isSelected: selectedImages.contains(image.id),
                        onTap: {
                            if selectedImages.contains(image.id) {
                                selectedImages.remove(image.id)
                            } else {
                                selectedImages.insert(image.id)
                            }
                        },
                        onDoubleTap: {
                            onImageTap(image)
                        }
                    )
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
}

struct ModernGalleryListView: View {
    let images: [GeneratedImage]
    @Binding var selectedImages: Set<UUID>
    let onImageTap: (GeneratedImage) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(images, id: \.id) { image in
                    ModernGalleryListCard(
                        image: image,
                        isSelected: selectedImages.contains(image.id),
                        onTap: {
                            if selectedImages.contains(image.id) {
                                selectedImages.remove(image.id)
                            } else {
                                selectedImages.insert(image.id)
                            }
                        },
                        onDoubleTap: {
                            onImageTap(image)
                        }
                    )
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
}

struct ModernGalleryImageCard: View {
    let image: GeneratedImage
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Image
                Image(nsImage: image.nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(DesignSystem.CornerRadius.medium, corners: [.topLeft, .topRight])
                
                // Selection Overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .stroke(DesignSystem.Colors.primary, lineWidth: 3)
                        .frame(height: 220)
                }
                
                // Selection Badge
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: onTap) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(isSelected ? DesignSystem.Colors.primary : .white)
                                .background(
                                    Circle()
                                        .fill(isSelected ? Color.white : Color.black.opacity(0.5))
                                        .frame(width: 24, height: 24)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.sm)
            }
            
            // Card Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(image.prompt)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(DesignSystem.Colors.text)
                
                HStack {
                    ModelBadge(model: image.model)
                    
                    Spacer()
                    
                    Text(image.createdAt, style: .date)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                HStack {
                    Label("\(image.width)×\(image.height)", systemImage: "viewfinder")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Label("\(image.steps) steps", systemImage: "gear")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium, corners: [.bottomLeft, .bottomRight])
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isSelected ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
                                .onTapGesture {
                            onTap()
                        }
                        .onTapGesture(count: 2) {
                            onDoubleTap()
                        }
    }
}

struct ModernGalleryListCard: View {
    let image: GeneratedImage
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Selection Checkbox
            Button(action: onTap) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Thumbnail
            Image(nsImage: image.nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(DesignSystem.CornerRadius.medium)
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(image.prompt)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(DesignSystem.Colors.text)
                
                HStack {
                    ModelBadge(model: image.model)
                    
                    Text("•")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(image.width)×\(image.height)")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(image.steps) steps")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Text(image.createdAt, style: .relative)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            // Action Button
            Button("View") {
                onDoubleTap()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ModelBadge: View {
    let model: String
    
    var modelInfo: (color: Color, text: String) {
        switch model {
        case "schnell":
            return (DesignSystem.Colors.success, "Schnell")
        case "dev":
            return (DesignSystem.Colors.primary, "Dev")
        default:
            return (DesignSystem.Colors.secondary, model.capitalized)
        }
    }
    
    var body: some View {
        Text(modelInfo.text)
            .font(DesignSystem.Typography.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(modelInfo.color)
            )
    }
}

struct EmptyGalleryCard: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if searchText.isEmpty {
                    Text("No images yet")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text("Generate your first image to see it here")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("No matching images")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text("Try adjusting your search or filters")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            if searchText.isEmpty {
                NavigationLink(destination: GenerationView()) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Start Generating")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Modern Detail Sheet

struct ModernImageDetailSheet: View {
    let image: GeneratedImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Image Details")
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text("Generated \(image.createdAt, style: .relative)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(DesignSystem.Spacing.lg)
            
            Divider()
                .background(DesignSystem.Colors.secondary.opacity(0.3))
            
            HStack(spacing: 0) {
                // Image Preview
                VStack {
                    Image(nsImage: image.nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 500)
                        .cornerRadius(DesignSystem.CornerRadius.large)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button("Save Image") {
                            saveImage()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("Copy") {
                            copyImage()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Regenerate") {
                            // TODO: Regenerate with same parameters
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(DesignSystem.Spacing.lg)
                
                Divider()
                    .background(DesignSystem.Colors.secondary.opacity(0.3))
                
                // Details Panel
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        DetailSection(title: "Prompt") {
                            Text(image.prompt)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text)
                                .textSelection(.enabled)
                        }
                        
                        if !image.negativePrompt.isEmpty {
                            DetailSection(title: "Negative Prompt") {
                                Text(image.negativePrompt)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.text)
                                    .textSelection(.enabled)
                            }
                        }
                        
                        DetailSection(title: "Generation Settings") {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                DetailItem(label: "Model", value: image.model.capitalized)
                                DetailItem(label: "Steps", value: "\(image.steps)")
                                DetailItem(label: "Guidance Scale", value: String(format: "%.1f", image.guidanceScale))
                                DetailItem(label: "Seed", value: "\(image.seed)")
                                DetailItem(label: "Dimensions", value: "\(image.width) × \(image.height)")
                            }
                        }
                        
                        DetailSection(title: "Metadata") {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                DetailItem(label: "Created", value: DateFormatter.localizedString(from: image.createdAt, dateStyle: .medium, timeStyle: .short))
                                DetailItem(label: "File Size", value: "2.1 MB") // TODO: Calculate actual file size
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                }
                .frame(width: 300)
                .background(DesignSystem.Colors.surface)
            }
        }
        .frame(width: 900, height: 700)
        .background(DesignSystem.Colors.background)
    }
    
    private func saveImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "mflux_image_\(DateFormatter.filenameDateFormatter.string(from: image.createdAt)).png"
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            // Convert NSImage to data and save
            if let tiffData = image.nsImage.tiffRepresentation,
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
        NSPasteboard.general.writeObjects([image.nsImage])
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.text)
            
            content
        }
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

// MARK: - Enums

enum ViewMode: String, CaseIterable {
    case grid = "grid"
    case list = "list"
}

enum SortOrder: String, CaseIterable {
    case dateDescending = "date_desc"
    case dateAscending = "date_asc"
    case promptAscending = "prompt_asc"
    case promptDescending = "prompt_desc"
}

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        
        // Top edge and top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        if topRight > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                       radius: topRight,
                       startAngle: Angle(degrees: 270),
                       endAngle: Angle(degrees: 0),
                       clockwise: false)
        }
        
        // Right edge and bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        if bottomRight > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                       radius: bottomRight,
                       startAngle: Angle(degrees: 0),
                       endAngle: Angle(degrees: 90),
                       clockwise: false)
        }
        
        // Bottom edge and bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        if bottomLeft > 0 {
            path.addArc(center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                       radius: bottomLeft,
                       startAngle: Angle(degrees: 90),
                       endAngle: Angle(degrees: 180),
                       clockwise: false)
        }
        
        // Left edge and top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        if topLeft > 0 {
            path.addArc(center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                       radius: topLeft,
                       startAngle: Angle(degrees: 180),
                       endAngle: Angle(degrees: 270),
                       clockwise: false)
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Extensions 
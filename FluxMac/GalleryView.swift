import SwiftUI

struct GalleryView: View {
    @State private var selectedImages: Set<UUID> = []
    @State private var searchText = ""
    @State private var selectedFilter = "all"
    @State private var sortOrder = SortOrder.dateDescending
    @State private var showingImageDetail = false
    @State private var selectedImage: GeneratedImage?
    
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
            // Header with controls
            VStack(spacing: 12) {
                HStack {
                    Text("Gallery")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if !selectedImages.isEmpty {
                        HStack {
                            Text("\(selectedImages.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Delete") {
                                deleteSelectedImages()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            
                            Button("Export") {
                                exportSelectedImages()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Search and filter bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search images...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    Picker("Filter", selection: $selectedFilter) {
                        Text("All").tag("all")
                        Text("Schnell").tag("schnell")
                        Text("Dev").tag("dev")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                    
                    Picker("Sort", selection: $sortOrder) {
                        Text("Newest").tag(SortOrder.dateDescending)
                        Text("Oldest").tag(SortOrder.dateAscending)
                        Text("A-Z").tag(SortOrder.promptAscending)
                        Text("Z-A").tag(SortOrder.promptDescending)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
            }
            .padding()
            
            Divider()
            
            // Gallery content
            if filteredImages.isEmpty {
                EmptyGalleryView(searchText: searchText)
            } else {
                GalleryGridView(
                    images: filteredImages,
                    selectedImages: $selectedImages,
                    onImageTap: { image in
                        selectedImage = image
                        showingImageDetail = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingImageDetail) {
            if let image = selectedImage {
                ImageDetailSheet(image: image)
            }
        }
    }
    
    private func deleteSelectedImages() {
        // TODO: Implement image deletion
        selectedImages.removeAll()
    }
    
    private func exportSelectedImages() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose export location"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                // TODO: Export selected images to URL
            }
        }
    }
}

struct GalleryGridView: View {
    let images: [GeneratedImage]
    @Binding var selectedImages: Set<UUID>
    let onImageTap: (GeneratedImage) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(images, id: \.id) { image in
                    GalleryImageCard(
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
            .padding()
        }
    }
}

struct GalleryImageCard: View {
    let image: GeneratedImage
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: image.nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8, corners: [.topLeft, .topRight])
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(height: 200)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            // TODO: Quick actions menu
                        }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(image.prompt)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(image.model)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(image.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
        .onTapGesture {
            onTap()
        }
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

struct EmptyGalleryView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Text("No images yet")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Generate your first image to see it here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No matching images")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Try adjusting your search or filters")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ImageDetailSheet: View {
    let image: GeneratedImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Image Details")
                    .font(.title)
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            
            Image(nsImage: image.nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(title: "Prompt", value: image.prompt)
                    
                    if !image.negativePrompt.isEmpty {
                        DetailRow(title: "Negative Prompt", value: image.negativePrompt)
                    }
                    
                    DetailRow(title: "Model", value: image.model)
                    DetailRow(title: "Steps", value: "\(image.steps)")
                    DetailRow(title: "Guidance Scale", value: String(format: "%.1f", image.guidanceScale))
                    DetailRow(title: "Seed", value: "\(image.seed)")
                    DetailRow(title: "Dimensions", value: "\(image.width) × \(image.height)")
                    DetailRow(title: "Generated", value: DateFormatter.localizedString(from: image.createdAt, dateStyle: .medium, timeStyle: .none))
                }
                .padding()
            }
            
            HStack {
                Spacer()
                Button("Save Image") {
                    saveImage()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 800, height: 600)
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
}

struct DetailRow: View {
    let title: String
    let value: String
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
                .lineLimit(nil)
        }
    }
}

enum SortOrder: String, CaseIterable {
    case dateDescending = "date_desc"
    case dateAscending = "date_asc"
    case promptAscending = "prompt_asc"
    case promptDescending = "prompt_desc"
}

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
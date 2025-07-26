# MFLUX Mac App - User Guide

Welcome to MFLUX Mac App, a native macOS application that brings the power of FLUX image generation to your Apple Silicon Mac.

## Getting Started

### System Requirements

- **macOS**: 12.0 (Monterey) or later
- **Hardware**: Apple Silicon Mac (M1/M2/M3/M4)
- **Memory**: 16GB RAM minimum (32GB+ recommended)
- **Storage**: 50GB+ available space for models and cache

### First Launch

1. **Download and Install**: Download the app from the Mac App Store or direct download
2. **Launch the App**: Double-click the MFLUX app icon
3. **Model Setup**: On first launch, you'll be prompted to download models
4. **Start Generating**: Enter a prompt and click "Generate Image"

## Interface Overview

### Main Window

The app features a clean, native macOS interface with:

- **Sidebar**: Navigation between different sections
- **Generation Panel**: Input prompts and parameters
- **Gallery**: View and manage generated images
- **Settings**: Configure app preferences

### Navigation

- **Generate**: Create new images
- **Gallery**: Browse and manage generated images
- **Models**: Download and manage AI models
- **Presets**: Save and load generation configurations
- **Settings**: App configuration and preferences

## Generating Images

### Basic Generation

1. **Enter a Prompt**: Describe what you want to generate
2. **Select Model**: Choose between Schnell (fast) or Dev (advanced)
3. **Adjust Parameters**: Set steps, guidance scale, and dimensions
4. **Generate**: Click the "Generate Image" button

### Advanced Parameters

- **Steps**: Number of denoising steps (1-50)
  - Lower values = faster generation, lower quality
  - Higher values = slower generation, higher quality
- **Guidance Scale**: How closely to follow the prompt (1-20)
  - Lower values = more creative, less accurate
  - Higher values = more accurate, less creative
- **Seed**: Random seed for reproducible results
- **Dimensions**: Image size (512x512 to 1280x1280)

### Model Selection

- **Schnell**: Fast generation model, optimized for speed
- **Dev**: Advanced model with more features and higher quality

## Managing Images

### Gallery Features

- **Grid View**: Browse all generated images
- **Search**: Find images by prompt or metadata
- **Filter**: Filter by model type
- **Sort**: Sort by date, prompt, or other criteria

### Image Actions

- **Preview**: Double-click to view full size
- **Save**: Export to your preferred location
- **Copy**: Copy to clipboard
- **Delete**: Remove from gallery
- **Regenerate**: Create variations with same parameters

### Metadata

Each generated image includes:
- Original prompt
- Generation parameters
- Model used
- Creation date and time
- File size and dimensions

## Model Management

### Downloading Models

1. Go to the "Models" section
2. Click "Download" next to the model you want
3. Wait for download to complete
4. Model will be available for generation

### Model Information

- **Schnell**: 2.1 GB, optimized for speed
- **Dev**: 4.2 GB, advanced features

### Storage Management

- View disk usage in Settings
- Remove unused models to free space
- Models are stored in Application Support

## Presets

### Creating Presets

1. Configure generation parameters
2. Click "Save as Preset"
3. Enter name and description
4. Preset will be available for future use

### Using Presets

1. Go to "Presets" section
2. Click "Use" on desired preset
3. Parameters will be applied to generation panel

## Settings

### General Settings

- **Auto-save**: Automatically save generated images
- **Default output folder**: Choose where images are saved
- **Launch behavior**: Configure app startup

### Performance Settings

- **Max concurrent generations**: Limit simultaneous processes
- **Memory limit**: Set maximum memory usage
- **Metal acceleration**: Enable GPU acceleration (always on for Apple Silicon)

### Advanced Settings

- **Debug logging**: Enable detailed logs
- **Export logs**: Save log files for troubleshooting
- **Reset settings**: Restore default configuration

## Keyboard Shortcuts

- **Cmd+G**: Generate image
- **Cmd+S**: Save current image
- **Cmd+C**: Copy image to clipboard
- **Cmd+Z**: Undo last action
- **Cmd+Shift+K**: Clear all parameters
- **Cmd+R**: Refresh gallery
- **Cmd+,**: Open settings

## Tips and Best Practices

### Writing Prompts

- **Be specific**: "A majestic dragon flying over a medieval castle at sunset" vs "dragon"
- **Use descriptive language**: Include details about style, lighting, composition
- **Negative prompts**: Specify what you don't want
- **Experiment**: Try different phrasings and styles

### Parameter Optimization

- **Schnell model**: Use 10-20 steps for fast generation
- **Dev model**: Use 20-50 steps for high quality
- **Guidance scale**: Start with 7.5, adjust based on results
- **Dimensions**: Larger images take longer but may look better

### Performance Tips

- **Close other apps**: Free up memory for generation
- **Use appropriate model**: Schnell for quick tests, Dev for final images
- **Batch generation**: Generate multiple images at once
- **Monitor temperature**: Keep your Mac cool for optimal performance

## Troubleshooting

### Common Issues

**App won't launch**
- Check system requirements
- Restart your Mac
- Reinstall the app

**Generation fails**
- Check internet connection for model downloads
- Ensure sufficient disk space
- Try restarting the app

**Slow performance**
- Close other applications
- Check Activity Monitor for memory usage
- Restart your Mac

**Models won't download**
- Check internet connection
- Verify disk space
- Try downloading again

### Getting Help

- **In-app Help**: Use the Help menu
- **Documentation**: Visit our website
- **Community**: Join our Discord server
- **Support**: Contact us via email

## Privacy and Security

- **Local Processing**: All generation happens on your device
- **No Telemetry**: We don't collect usage data
- **Secure Storage**: Models and images stored securely
- **No Cloud Dependencies**: Works completely offline

## Updates

- **Automatic Updates**: App updates automatically from Mac App Store
- **Model Updates**: New model versions available in Models section
- **Feature Updates**: New features added regularly

## System Integration

### Services Menu

- Select text in any app
- Right-click and choose "Generate with MFLUX"
- Image will be generated from selected text

### Drag and Drop

- Drag images from other apps
- Use as reference for generation
- Export generated images to other apps

### Spotlight Integration

- Search generated images by prompt
- Quick access to recent images
- Metadata search support

## Advanced Features

### Batch Generation

- Generate multiple images at once
- Use different seeds for variations
- Export all images together

### Image-to-Image

- Use existing images as starting point
- Control generation with reference images
- Maintain composition while changing style

### LoRA Support

- Load custom LoRA models
- Mix multiple LoRA models
- Fine-tune generation style

### ControlNet

- Use edge detection for structure
- Control composition with reference images
- Advanced image manipulation

## Performance Monitoring

### Resource Usage

- Monitor GPU/CPU usage
- Track memory consumption
- View generation speed

### Optimization

- Automatic performance tuning
- Memory management
- Background processing

## Future Features

- **Video Generation**: Animate generated images
- **3D Generation**: Create 3D models
- **Style Transfer**: Apply artistic styles
- **Collaboration**: Share and remix images
- **Cloud Sync**: Sync across devices

---

For more information, visit our website or join our community Discord server. 
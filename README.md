# MFLUX Mac App

A native macOS application that provides a user-friendly interface for MFLUX, an MLX-based FLUX image generation tool optimized for Apple Silicon Macs.

## License

This project is provided under a custom license. Please see the [LICENSE](LICENSE) file for details.

**TL;DR:**
*   **Free for Personal Use:** You can use this software freely for personal, non-commercial, and educational purposes.
*   **Commercial Use Requires a License:** If you want to use this software for any commercial purpose, you must purchase a separate license.

## Features

- 🎨 **Native Mac Experience**: Built with SwiftUI for optimal macOS integration
- 🚀 **Apple Silicon Optimized**: Leverages M1/M2/M3/M4 neural processing capabilities
- 🔒 **Privacy-Focused**: All processing happens locally on your device
- 🎯 **No Command Line Required**: Intuitive GUI for non-technical users
- ⚡ **High Performance**: Direct integration with MFLUX for maximum speed

## Quick Start

1.  **Run the setup script**:
    ```bash
    ./setup_dev.sh
    ```
    This will install all necessary dependencies and set up the development environment.

2.  **Run the development script**:
    ```bash
    ./run_dev.sh
    ```
    This will build and launch the application.

## Project Structure

```
FluxMac/
├── FluxMac.xcodeproj/          # Xcode project
├── FluxMac/                    # Main app bundle
│   ├── ContentView.swift
│   ├── FluxMacApp.swift
│   ├── GalleryView.swift
│   ├── GenerationService.swift
│   ├── GenerationView.swift
│   ├── ModelManager.swift
│   └── PythonBridge.swift
├── PythonBridge/               # Python integration
│   ├── mflux_wrapper.py
│   ├── requirements.txt
│   └── ...
├── Models/                     # AI models storage
└── Documentation/              # User and developer docs
```

## Development Phases

### Phase 1: Core MVP ✅
- [x] Basic SwiftUI interface
- [x] MFLUX Python integration
- [x] Essential generation features
- [x] Model management
- [x] Basic gallery

### Phase 2: Advanced Features 🚧
- [ ] LoRA support
- [ ] Image-to-image generation
- [ ] Advanced UI components
- [ ] Performance optimizations
- [ ] Beta testing

### Phase 3: Polish & Release 📋
- [ ] UI/UX refinements
- [ ] App Store compliance
- [ ] Documentation
- [ ] Marketing materials
- [ ] Release preparation

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under a custom license. See the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [User Guide](Documentation/UserGuide.md)
- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discord**: [Community Server](https://discord.gg/your-server)

## Acknowledgments

- Built on top of [MFLUX](https://github.com/mflux-ai/mflux) for MLX-based FLUX implementation
- Optimized for Apple Silicon Macs
- Native macOS integration with SwiftUI 
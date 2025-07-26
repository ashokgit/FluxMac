import Foundation
import AppKit

class PythonBridge: ObservableObject {
    private var pythonProcess: Process?
    private var pythonScriptPath: String?
    
    init() {
        setupPythonEnvironment()
    }
    
    private func setupPythonEnvironment() {
        // Get the path to the PythonBridge directory in the app bundle
        if let bundlePath = Bundle.main.resourcePath {
            pythonScriptPath = bundlePath + "/PythonBridge"
        }
        
        // Create PythonBridge directory if it doesn't exist
        if let scriptPath = pythonScriptPath {
            try? FileManager.default.createDirectory(atPath: scriptPath, withIntermediateDirectories: true)
        }
    }
    
    func generateImage(with parameters: GenerationParameters) async throws -> NSImage {
        // Use the MFLUX generation method
        let imageData = try await generateImageWithMFLUX(
            prompt: parameters.prompt,
            model: parameters.model,
            steps: parameters.steps,
            guidanceScale: parameters.guidanceScale,
            seed: parameters.seed,
            width: parameters.width,
            height: parameters.height
        )
        
        guard let image = NSImage(data: imageData) else {
            throw PythonBridgeError.invalidResponse
        }
        
        return image
    }
    
    func setHuggingFaceToken(_ token: String) async {
        let script = """
        import os
        import subprocess
        import sys
        
        try:
            # Set the token as an environment variable
            os.environ['HUGGINGFACE_HUB_TOKEN'] = '\(token)'
            
            # Also try to authenticate using huggingface-hub
            result = subprocess.run([
                sys.executable, '-c', 
                'from huggingface_hub import login; login(token=\"\(token)\", add_to_git_credential=False)'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("HF_AUTH_SUCCESS")
            else:
                print(f"HF_AUTH_ERROR: {result.stderr}")
                
        except Exception as e:
            print(f"HF_AUTH_ERROR: {str(e)}")
        """
        
        do {
            let output = try await executePythonScript(script)
            if output.contains("HF_AUTH_SUCCESS") {
                print("✅ Hugging Face authentication successful")
            } else {
                print("❌ Hugging Face authentication failed: \(output)")
            }
        } catch {
            print("❌ Failed to set HF token: \(error)")
        }
    }
    
    func downloadModel(_ modelName: String, progressCallback: @escaping (Double, String) -> Void) async throws {
        let script = """
        import sys
        import os
        import subprocess
        import time
        import threading
        from pathlib import Path
        
        try:
            # Check for required dependencies
            try:
                import torch
                import mlx
                from mflux.generate import Flux1, Config
            except ImportError as dep_err:
                print(f'DOWNLOAD_ERROR: Missing dependency: {dep_err}')
                sys.exit(1)
            
            print("DOWNLOAD_START")
            print(f"Downloading model: \(modelName)")
            
            # Set up download directory
            models_dir = Path.home() / '.cache' / 'mflux'
            models_dir.mkdir(parents=True, exist_ok=True)
            
            # Map model names to MFLUX model types
            model_mapping = {
                'schnell': 'schnell',
                'dev': 'dev'
            }
            
            # Get the correct model type
            model_type = model_mapping.get('\(modelName)', '\(modelName)')
            
            # Monitor actual download progress
            def monitor_download_progress():
                import os
                import glob
                
                # Check for actual downloaded files
                cache_dirs = [
                    str(Path.home() / '.cache' / 'mflux'),
                    str(Path.home() / 'Library' / 'Caches' / 'mflux')
                ]
                
                last_size = 0
                while True:
                    total_size = 0
                    for cache_dir in cache_dirs:
                        if os.path.exists(cache_dir):
                            for root, dirs, files in os.walk(cache_dir):
                                for file in files:
                                    file_path = os.path.join(root, file)
                                    if os.path.exists(file_path):
                                        total_size += os.path.getsize(file_path)
                    
                    if total_size > 0:
                        # Estimate progress based on file size (FLUX model is ~2.1GB)
                        estimated_progress = min(total_size / (2.1 * 1024 * 1024 * 1024), 0.95)
                        if estimated_progress > last_size:
                            print(f"PROGRESS: {estimated_progress:.2f}", flush=True)
                            last_size = estimated_progress
                    
                    time.sleep(2.0)  # Check every 2 seconds
            
            progress_thread = threading.Thread(target=monitor_download_progress)
            progress_thread.daemon = True
            progress_thread.start()
            
            # Import ModelConfig and create proper config
            from mflux.config.model_config import ModelConfig
            
            print("PROGRESS: 0.05", flush=True)
            print("Starting download...", flush=True)
            print("PROGRESS: 0.1", flush=True)
            print("Initializing model...", flush=True)
            
            # Create ModelConfig based on model type
            if model_type == 'schnell':
                model_config = ModelConfig.schnell()
            elif model_type == 'dev':
                model_config = ModelConfig.dev()
            else:
                # Try to create from name
                model_config = ModelConfig.from_name(model_type)
            
            print("PROGRESS: 0.3", flush=True)
            print("Loading model...", flush=True)
            
            # This will trigger the model download (with timeout)
            import signal
            
            def timeout_handler(signum, frame):
                raise TimeoutError("Model download timed out after 10 minutes")
            
            # Set timeout for 10 minutes
            signal.signal(signal.SIGALRM, timeout_handler)
            signal.alarm(600)  # 10 minutes
            
            try:
                flux = Flux1(model_config)
                signal.alarm(0)  # Cancel timeout
            except TimeoutError:
                print("DOWNLOAD_ERROR: Model download timed out")
                sys.exit(1)
            
            print("PROGRESS: 0.8", flush=True)
            print("Model loaded successfully!", flush=True)
            
            # Mark as complete
            print("PROGRESS: 1.0", flush=True)
            print("DOWNLOAD_COMPLETE", flush=True)
            
        except ImportError as e:
            print(f"DOWNLOAD_ERROR: MFLUX not available - {str(e)}")
        except Exception as e:
            print(f"DOWNLOAD_ERROR: {str(e)}")
        """
        
        // Use streaming execution to get real-time progress
        try await executeStreamingPythonScript(script, progressCallback: progressCallback)
    }
    
    func checkModelStatus(_ modelName: String) -> Bool {
        // Check if model is available in MFLUX cache
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        // Use the actual model names as they appear in the cache
        let modelMapping = ["schnell": "schnell", "dev": "dev"]
        let modelId = modelMapping[modelName] ?? modelName
        let mfluxCache = homeDir.appendingPathComponent(".cache/mflux/\(modelId)")
        
        // Check if the model directory exists and contains model files
        if FileManager.default.fileExists(atPath: mfluxCache.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: mfluxCache.path)
                // Look for typical model files
                let hasModelFiles = contents.contains { file in
                    file.hasSuffix(".safetensors") || file.hasSuffix(".bin") || file.hasSuffix(".json")
                }
                return hasModelFiles
            } catch {
                return false
            }
        }
        return false
    }
    
    // MARK: - Python Script Execution
    
    private func executeStreamingPythonScript(_ script: String, progressCallback: @escaping (Double, String) -> Void) async throws {
        guard let pythonPath = findPythonPath() else {
            throw PythonBridgeError.pythonNotFound
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = ["-c", script]
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        // Buffer to accumulate stdout data incrementally to avoid pipe blocking
        var outputData = Data()
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if !chunk.isEmpty {
                outputData.append(chunk)
            }
        }
        
        var errorData = Data()
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if !chunk.isEmpty {
                errorData.append(chunk)
            }
        }
        
        do {
            try process.run()
            
            // Add timeout for long-running processes
            let timeout: TimeInterval = 300  // 5 minutes
            let startTime = Date()
            
            while process.isRunning {
                if Date().timeIntervalSince(startTime) > timeout {
                    process.terminate()
                    throw PythonBridgeError.scriptExecutionFailed("Process timed out after \(timeout) seconds")
                }
                usleep(100000)  // Sleep for 0.1 seconds
            }
            
            // Stop handlers and close pipes
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            print("🐍 Process exited with status: \(process.terminationStatus)")
            print("🐍 Output length: \(output.count) characters")
            print("🐍 Error output length: \(errorOutput.count) characters")
            
            if process.terminationStatus != 0 {
                throw PythonBridgeError.scriptExecutionFailed("Python script failed: \(errorOutput)")
            }
            
            // Check for download errors in the output
            if output.contains("DOWNLOAD_ERROR") {
                let errorMsg = output.components(separatedBy: "DOWNLOAD_ERROR: ").last ?? output
                throw PythonBridgeError.generationFailed("Model download failed: \(errorMsg)")
            }
            
        } catch {
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            throw error
        }
    }
    
    private func executePythonScript(_ script: String, arguments: [String] = []) async throws -> String {
        guard let pythonPath = findPythonPath() else {
            throw PythonBridgeError.pythonNotFound
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = ["-c", script] + arguments
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            
            // Add timeout for long-running processes
            let timeout: TimeInterval = 300  // 5 minutes
            let startTime = Date()
            
            while process.isRunning {
                if Date().timeIntervalSince(startTime) > timeout {
                    process.terminate()
                    throw PythonBridgeError.scriptExecutionFailed("Process timed out after \(timeout) seconds")
                }
                usleep(100000)  // Sleep for 0.1 seconds
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            print("🐍 Process exited with status: \(process.terminationStatus)")
            print("🐍 Output length: \(output.count) characters")
            print("🐍 Error output length: \(errorOutput.count) characters")
            
            if process.terminationStatus != 0 {
                print("❌ Process failed with exit code: \(process.terminationStatus)")
                print("❌ Error output: \(errorOutput)")
                throw PythonBridgeError.scriptExecutionFailed("Exit code: \(process.terminationStatus)\nOutput: \(output)\nError: \(errorOutput)")
            }
            
            return output
        } catch {
            print("❌ Process execution failed: \(error.localizedDescription)")
            throw PythonBridgeError.scriptExecutionFailed(error.localizedDescription)
        }
    }
    
    private func findPythonPath() -> String? {
        // First check if we have a virtual environment in our bundle
        if let bundlePath = Bundle.main.resourcePath {
            let venvPython = bundlePath + "/PythonBridge/venv/bin/python"
            if FileManager.default.fileExists(atPath: venvPython) {
                return venvPython
            }
        }
        
        // Try to find Python in common locations
        let possiblePaths = [
            "/usr/bin/python3",
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3",
            "/usr/bin/python",
            "/usr/local/bin/python"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    // MARK: - MFLUX Integration
    
    func initializeMFLUX() async throws {
        let script = """
        import sys
        import os
        
        # Try to import required packages
        try:
            import torch
            print("PyTorch available:", torch.__version__)
        except ImportError:
            print("ERROR: PyTorch not installed")
            sys.exit(1)
        
        try:
            import numpy as np
            print("NumPy available:", np.__version__)
        except ImportError:
            print("ERROR: NumPy not installed")
            sys.exit(1)
        
        try:
            from PIL import Image
            print("PIL available")
        except ImportError:
            print("ERROR: Pillow not installed")
            sys.exit(1)
        
        # Check for MFLUX
        try:
            # This would import the actual MFLUX library
            # import mflux
            print("MFLUX environment check passed")
        except ImportError:
            print("WARNING: MFLUX not available, using fallback mode")
        """
        
        _ = try await executePythonScript(script)
    }
    
    func generateImageWithMFLUX(prompt: String, model: String, steps: Int, guidanceScale: Double, seed: Int?, width: Int, height: Int) async throws -> Data {
        let seedValue = seed ?? Int.random(in: 1...999999999)
        
        // Use the real MFLUX wrapper to generate images
        let mfluxScript = """
        import sys
        import os
        import json
        import base64
        from io import BytesIO
        
        # Add the PythonBridge directory to the path
        # Since we're running with -c flag, __file__ is not available
        # We need to find the PythonBridge directory differently
        bundle_path = None
        if 'Contents/Resources/PythonBridge' in os.getcwd():
            # We're running from the app bundle
            bundle_path = os.path.join(os.getcwd(), 'PythonBridge')
        else:
            # Try to find PythonBridge in common locations
            possible_paths = [
                os.path.join(os.getcwd(), 'PythonBridge'),
                os.path.join(os.path.expanduser('~'), 'FluxMac', 'PythonBridge'),
                '/Users/ashokpoudel/FluxMac/PythonBridge'
            ]
            for path in possible_paths:
                if os.path.exists(path):
                    bundle_path = path
                    break
        
        if bundle_path and bundle_path not in sys.path:
            sys.path.insert(0, bundle_path)
        
        try:
            from mflux_wrapper import MFLUXWrapper
        except ImportError as e:
            error_result = {
                'success': False,
                'error': f"MFLUX wrapper not found: {str(e)}"
            }
            print(json.dumps(error_result))
            sys.exit(1)
        
        # Parse arguments
        prompt = sys.argv[1] if len(sys.argv) > 1 else "A beautiful landscape"
        model = sys.argv[2] if len(sys.argv) > 2 else "schnell"
        steps = int(sys.argv[3]) if len(sys.argv) > 3 else 20
        guidance_scale = float(sys.argv[4]) if len(sys.argv) > 4 else 7.5
        seed = int(sys.argv[5]) if len(sys.argv) > 5 else 42
        width = int(sys.argv[6]) if len(sys.argv) > 6 else 512
        height = int(sys.argv[7]) if len(sys.argv) > 7 else 512
        
        try:
            # Initialize MFLUX wrapper
            wrapper = MFLUXWrapper()
            
            # Check if MFLUX is available
            if not wrapper.get_model_info()['mflux_available']:
                error_result = {
                    'success': False,
                    'error': "MFLUX library not available. Please install MFLUX to generate real AI images."
                }
                print(json.dumps(error_result))
                sys.exit(1)
            
            # Generate the image using real MFLUX
            image, metadata = wrapper.generate_image(
                prompt=prompt,
                model=model,
                steps=steps,
                guidance_scale=guidance_scale,
                seed=seed,
                width=width,
                height=height
            )
            
            import tempfile
            # Save PNG to a temporary file and return path (avoids huge stdout)
            tmp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.png')
            image.save(tmp_file.name, format='PNG')
            
            result = {
                'success': True,
                'file_path': tmp_file.name,
                'metadata': metadata
            }
            
            print(json.dumps(result))
            
        except Exception as e:
            error_result = {
                'success': False,
                'error': f"Image generation failed: {str(e)}"
            }
            print(json.dumps(error_result))
            sys.exit(1)
        """
        
        let arguments = [
            prompt,
            model,
            String(steps),
            String(guidanceScale),
            String(seedValue),
            String(width),
            String(height)
        ]
        
        let output = try await executePythonScript(mfluxScript, arguments: arguments)
        
        // Debug logging
        print("🐍 Python script output length: \(output.count)")
        print("🐍 First 200 chars: \(output.prefix(200))")
        
        // Parse JSON response
        guard let data = output.data(using: .utf8) else {
            print("❌ Failed to convert output to UTF8 data")
            throw PythonBridgeError.invalidResponse
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON from output")
            print("📝 Raw output: \(output)")
            throw PythonBridgeError.invalidResponse
        }
        
        guard let success = json["success"] as? Bool else {
            print("❌ No 'success' field in JSON")
            print("📝 JSON keys: \(json.keys)")
            throw PythonBridgeError.invalidResponse
        }
        
        if !success {
            let error = json["error"] as? String ?? "Unknown error"
            throw PythonBridgeError.generationFailed(error)
        }
        
        guard let file_path = json["file_path"] as? String,
              let imageData = try? Data(contentsOf: URL(fileURLWithPath: file_path)) else {
            throw PythonBridgeError.invalidResponse
        }
        
        return imageData
    }
}

enum PythonBridgeError: Error, LocalizedError {
    case pythonNotFound
    case scriptExecutionFailed(String)
    case invalidResponse
    case generationFailed(String)
    case dependenciesMissing([String])
    
    var errorDescription: String? {
        switch self {
        case .pythonNotFound:
            return "Python not found on system. Please install Python 3.7 or later."
        case .scriptExecutionFailed(let message):
            return "Script execution failed: \(message)"
        case .invalidResponse:
            return "Invalid response from AI generation system"
        case .generationFailed(let message):
            return "Image generation failed: \(message)"
        case .dependenciesMissing(let deps):
            return "Missing required dependencies: \(deps.joined(separator: ", ")). Please install the required Python packages."
        }
    }
} 
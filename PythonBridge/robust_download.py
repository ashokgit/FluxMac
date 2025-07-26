#!/usr/bin/env python3
"""
Robust model download script using huggingface-cli with resume capability
"""

import os
import sys
import time
import subprocess
import threading
from pathlib import Path
from typing import Optional

def get_model_size_gb(model_name: str) -> float:
    """Get the expected model size in GB"""
    model_sizes = {
        'schnell': 31.4,  # Actual size based on our analysis
        'dev': 4.2
    }
    return model_sizes.get(model_name, 2.1)

def monitor_download_progress(model_name: str, cache_dir: Path):
    """Monitor download progress by checking file sizes"""
    expected_size_gb = get_model_size_gb(model_name)
    expected_size_bytes = expected_size_gb * 1024 * 1024 * 1024
    
    last_progress = 0
    while True:
        try:
            total_size = 0
            # Check both mflux and huggingface cache directories
            cache_dirs = [
                cache_dir,
                Path.home() / '.cache' / 'huggingface',
                Path.home() / 'Library' / 'Caches' / 'mflux'
            ]
            
            for cache_path in cache_dirs:
                if cache_path.exists():
                    for root, dirs, files in os.walk(cache_path):
                        for file in files:
                            file_path = Path(root) / file
                            if file_path.exists():
                                total_size += file_path.stat().st_size
            
            if total_size > 0:
                progress = min(total_size / expected_size_bytes, 0.95)
                if progress > last_progress:
                    print(f"PROGRESS: {progress:.2f}", flush=True)
                    last_progress = progress
            
            time.sleep(2.0)
        except Exception as e:
            print(f"PROGRESS_MONITOR_ERROR: {e}", flush=True)
            time.sleep(5.0)

def download_model_robust(model_name: str) -> bool:
    """Download model using huggingface-cli with resume capability"""
    try:
        print("DOWNLOAD_START", flush=True)
        print(f"Downloading model: {model_name}", flush=True)
        
        # Set up cache directory
        cache_dir = Path.home() / '.cache' / 'mflux'
        cache_dir.mkdir(parents=True, exist_ok=True)
        
        # Model mapping
        model_mapping = {
            'schnell': 'black-forest-labs/FLUX.1-schnell',
            'dev': 'black-forest-labs/FLUX.1-dev'
        }
        
        huggingface_model = model_mapping.get(model_name)
        if not huggingface_model:
            print(f"DOWNLOAD_ERROR: Unknown model {model_name}")
            return False
        
        print("PROGRESS: 0.05", flush=True)
        print("Starting robust download with huggingface-cli...", flush=True)
        
        # Start progress monitoring in background
        progress_thread = threading.Thread(
            target=monitor_download_progress, 
            args=(model_name, cache_dir),
            daemon=True
        )
        progress_thread.start()
        
        print("PROGRESS: 0.1", flush=True)
        print("Initializing download...", flush=True)
        
        # Use huggingface-cli to download with resume capability
        # Set environment to use Python 3.13.0 where huggingface-cli is available
        env = os.environ.copy()
        env['PYENV_VERSION'] = '3.13.0'
        
        cmd = [
            'huggingface-cli', 'download',
            huggingface_model,
            '--local-dir', str(cache_dir / model_name),
            '--local-dir-use-symlinks', 'False',
            '--resume-download',
            '--quiet'
        ]
        
        print("PROGRESS: 0.2", flush=True)
        print("Executing download command...", flush=True)
        print(f"Command: {' '.join(cmd)}", flush=True)
        
        # Run the download command
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env
        )
        
        # Monitor the process
        start_time = time.time()
        timeout = 7200  # 2 hour timeout for large models
        
        while process.poll() is None:
            if time.time() - start_time > timeout:
                print("DOWNLOAD_ERROR: Download timed out after 2 hours")
                process.terminate()
                return False
            
            time.sleep(5)
        
        # Check if download was successful
        if process.returncode == 0:
            print("PROGRESS: 1.0", flush=True)
            print("DOWNLOAD_COMPLETE", flush=True)
            return True
        else:
            stdout, stderr = process.communicate()
            print(f"DOWNLOAD_ERROR: Download failed with return code {process.returncode}")
            print(f"STDOUT: {stdout}")
            print(f"STDERR: {stderr}")
            return False
            
    except Exception as e:
        print(f"DOWNLOAD_ERROR: {str(e)}")
        return False

def main():
    """Main function"""
    if len(sys.argv) != 2:
        print("Usage: python robust_download.py <model_name>")
        sys.exit(1)
    
    model_name = sys.argv[1]
    success = download_model_robust(model_name)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main() 
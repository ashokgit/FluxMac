#!/usr/bin/env python3
"""
Test script to verify huggingface-cli download works
"""

import subprocess
import sys
from pathlib import Path

def test_hf_download():
    """Test huggingface-cli download with a small model first"""
    try:
        print("Testing huggingface-cli download...")
        
        # Test with a small model first
        test_model = "microsoft/DialoGPT-small"  # Small model for testing
        
        cmd = [
            'huggingface-cli', 'download',
            test_model,
            '--local-dir', str(Path.home() / '.cache' / 'mflux' / 'test'),
            '--local-dir-use-symlinks', 'False',
            '--resume-download',
            '--quiet'
        ]
        
        print(f"Running: {' '.join(cmd)}")
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            print("✅ huggingface-cli test successful!")
            return True
        else:
            print(f"❌ huggingface-cli test failed:")
            print(f"STDOUT: {result.stdout}")
            print(f"STDERR: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ Test timed out")
        return False
    except Exception as e:
        print(f"❌ Test error: {e}")
        return False

if __name__ == "__main__":
    success = test_hf_download()
    sys.exit(0 if success else 1) 
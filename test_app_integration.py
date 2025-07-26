#!/usr/bin/env python3
"""
Test script to simulate how the Swift app calls the MFLUX wrapper
"""

import sys
import os
import json
import base64
from io import BytesIO

# Add the PythonBridge directory to the path (simulating what the Swift app does)
script_dir = os.path.dirname(os.path.abspath(__file__))
pythonbridge_dir = os.path.join(script_dir, "PythonBridge")
if pythonbridge_dir not in sys.path:
    sys.path.insert(0, pythonbridge_dir)

try:
    from mflux_wrapper import MFLUXWrapper
    print("✅ MFLUX wrapper imported successfully")
except ImportError as e:
    print(f"❌ MFLUX wrapper import failed: {e}")
    sys.exit(1)

def test_model_loading():
    """Test if models can be loaded"""
    try:
        wrapper = MFLUXWrapper()
        print("✅ MFLUX wrapper initialized")
        
        # Check if MFLUX is available
        model_info = wrapper.get_model_info()
        print(f"✅ MFLUX available: {model_info['mflux_available']}")
        
        # List available models
        models = wrapper.list_available_models()
        print(f"✅ Available models: {models}")
        
        # Try to load a model
        print("🔄 Testing model loading...")
        success = wrapper.load_model('schnell')
        print(f"✅ Model load success: {success}")
        
        return True
    except Exception as e:
        print(f"❌ Model loading failed: {e}")
        return False

def test_image_generation():
    """Test if images can be generated"""
    try:
        wrapper = MFLUXWrapper()
        
        # Generate a test image
        print("🔄 Testing image generation...")
        image, metadata = wrapper.generate_image(
            prompt="A beautiful sunset over mountains",
            model="schnell",
            steps=5,
            width=512,
            height=512
        )
        
        print("✅ Image generation successful!")
        print(f"📊 Metadata: {metadata}")
        
        # Convert to base64 (like the Swift app does)
        buffer = BytesIO()
        image.save(buffer, format='PNG')
        image_data = base64.b64encode(buffer.getvalue()).decode('utf-8')
        
        result = {
            'success': True,
            'image_data': image_data,
            'metadata': metadata
        }
        
        print("✅ Base64 conversion successful")
        print(f"📏 Image data length: {len(image_data)} characters")
        
        return True
    except Exception as e:
        print(f"❌ Image generation failed: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Testing MFLUX integration...")
    print("=" * 50)
    
    # Test model loading
    if test_model_loading():
        print("\n✅ Model loading test passed")
    else:
        print("\n❌ Model loading test failed")
        sys.exit(1)
    
    # Test image generation
    if test_image_generation():
        print("\n✅ Image generation test passed")
    else:
        print("\n❌ Image generation test failed")
        sys.exit(1)
    
    print("\n🎉 All tests passed! MFLUX integration is working correctly.") 
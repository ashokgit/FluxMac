#!/usr/bin/env python3
"""
MFLUX Wrapper for FluxMac - Clean Version
Integrates real MFLUX AI image generation with the macOS app
All progress messages go to stderr to keep stdout clean for JSON
"""

import sys
import os
import json
import base64
import asyncio
from io import BytesIO
from typing import Dict, Any, Optional, Tuple, Callable
from pathlib import Path

def log(message: str):
    """Log messages to stderr to keep stdout clean"""
    print(message, file=sys.stderr, flush=True)

# Try to import real MFLUX first
try:
    from mflux.generate import Flux1, Config
    MFLUX_AVAILABLE = True
    log("✅ Real MFLUX library loaded successfully")
except ImportError as e:
    MFLUX_AVAILABLE = False
    log(f"⚠️  MFLUX library not available: {e}")

# Standard imports
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    log("📦 Installing Pillow...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow>=10.0.0"])
    from PIL import Image, ImageDraw, ImageFont

try:
    import numpy as np
except ImportError:
    log("📦 Installing numpy...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "numpy>=1.24.0"])
    import numpy as np


class MFLUXWrapper:
    """
    Wrapper class for MFLUX AI image generation
    Provides a clean interface for the FluxMac app
    """
    
    def __init__(self):
        """Initialize the MFLUX wrapper"""
        self.flux_model = None
        self.current_model = None
        self.available_models = {
            "schnell": "FLUX.1-schnell",
            "dev": "FLUX.1-dev"
        }
        
        log("🎨 MFLUX Wrapper initialized")
        if MFLUX_AVAILABLE:
            log("✅ Real AI generation available")
        else:
            log("⚠️  Real AI generation not available - please install MFLUX")

    def get_model_info(self) -> Dict[str, Any]:
        """Get information about available models and MFLUX status"""
        return {
            "mflux_available": MFLUX_AVAILABLE,
            "available_models": self.available_models,
            "current_model": self.current_model
        }

    def list_available_models(self) -> Dict[str, str]:
        """List all available models"""
        return self.available_models.copy()

    def load_model(self, model_name: str, quantize: int = 8) -> bool:
        """
        Load a specific MFLUX model
        
        Args:
            model_name: Name of model to load ('schnell' or 'dev')
            quantize: Quantization level (4, 8, or None)
            
        Returns:
            bool: True if model loaded successfully
        """
        if not MFLUX_AVAILABLE:
            log(f"❌ Cannot load model '{model_name}' - MFLUX not available")
            return False
            
        if model_name not in self.available_models:
            log(f"❌ Unknown model: {model_name}")
            return False
            
        try:
            log(f"📦 Loading MFLUX model: {model_name}")
            if quantize:
                log(f"🗜️  Using {quantize}-bit quantization")
                
            # Load the model using real MFLUX
            self.flux_model = Flux1.from_name(
                model_name=model_name,
                quantize=quantize
            )
            
            self.current_model = model_name
            log(f"✅ Model '{model_name}' loaded successfully")
            return True
            
        except Exception as e:
            log(f"❌ Failed to load model '{model_name}': {e}")
            self.flux_model = None
            self.current_model = None
            return False

    def generate_image(
        self,
        prompt: str,
        model: str = "schnell",
        steps: int = 4,
        guidance_scale: float = 7.5,
        seed: Optional[int] = None,
        width: int = 512,
        height: int = 512,
        negative_prompt: str = "",
        progress_callback: Optional[Callable[[float], None]] = None
    ) -> Tuple[Image.Image, Dict[str, Any]]:
        """
        Generate an AI image using MFLUX
        
        Args:
            prompt: Text description of desired image
            model: Model to use ('schnell' or 'dev')
            steps: Number of generation steps
            guidance_scale: How closely to follow the prompt
            seed: Random seed (None for random)
            width: Image width
            height: Image height
            negative_prompt: Things to avoid in the image
            progress_callback: Optional callback for progress updates
            
        Returns:
            Tuple of (PIL Image, metadata dict)
        """
        if not MFLUX_AVAILABLE:
            raise RuntimeError("MFLUX not available")
            
        log(f"🎨 Generating image with prompt: '{prompt}'")
        log(f"   Model: {model}, Steps: {steps}, Size: {width}x{height}")
        
        # Load model if not loaded or different model requested
        if self.current_model != model:
            if not self.load_model(model):
                raise RuntimeError(f"Failed to load model: {model}")
        
        # Generate seed if not provided
        if seed is None:
            import random
            seed = random.randint(1, 2**31 - 1)
        
        log(f"🎲 Using seed: {seed}")
        
        # Create configuration
        config = Config(
            num_inference_steps=steps,
            height=height,
            width=width,
            guidance=guidance_scale,
        )
        
        try:
            import time
            start_time = time.time()
            
            log("🚀 Starting AI image generation...")
            
            # Generate the image using real MFLUX
            generated_image = self.flux_model.generate_image(
                seed=seed,
                prompt=prompt,
                config=config
            )
            
            # Extract PIL image from GeneratedImage object
            image = generated_image.image
            
            end_time = time.time()
            generation_time = end_time - start_time
            
            log(f"✅ Real AI image generated successfully in {generation_time:.1f}s")
            
            # Create metadata
            metadata = {
                "prompt": prompt,
                "negative_prompt": negative_prompt,
                "model": model,
                "steps": steps,
                "guidance_scale": guidance_scale,
                "seed": seed,
                "width": width,
                "height": height,
                "generation_time": generation_time,
                "timestamp": int(time.time()),
                "real_ai": True
            }
            
            return image, metadata
            
        except Exception as e:
            log(f"❌ AI generation failed: {e}")
            raise


if __name__ == "__main__":
    # Test mode - generate a sample image
    if len(sys.argv) == 1:
        log("\n📋 MFLUX Wrapper Test Mode")
        wrapper = MFLUXWrapper()
        
        # Show model info
        info = wrapper.get_model_info()
        log("\n📋 Model Information:")
        for key, value in info.items():
            log(f"   {key}: {value}")
        
        if MFLUX_AVAILABLE:
            log("\n🧪 Testing real AI generation...")
            try:
                image, metadata = wrapper.generate_image(
                    prompt="A cute cat in a garden",
                    model="schnell",
                    steps=4,
                    width=512,
                    height=512
                )
                
                # Save test image
                output_path = "test_generation.png"
                image.save(output_path)
                log(f"✅ Test image saved to: {output_path}")
                
                log("\n📊 Generation Metadata:")
                for key, value in metadata.items():
                    log(f"   {key}: {value}")
                    
            except Exception as e:
                log(f"❌ Test generation failed: {e}")
        else:
            log("\n⚠️  Real AI generation not available")
            log("📦 To install MFLUX, run: pip install mflux>=0.9.6")
    else:
        # Command line mode for Swift app integration
        try:
            # Parse arguments
            prompt = sys.argv[1] if len(sys.argv) > 1 else "A beautiful landscape"
            model = sys.argv[2] if len(sys.argv) > 2 else "schnell"
            steps = int(sys.argv[3]) if len(sys.argv) > 3 else 4
            guidance_scale = float(sys.argv[4]) if len(sys.argv) > 4 else 7.5
            seed = int(sys.argv[5]) if len(sys.argv) > 5 else None
            width = int(sys.argv[6]) if len(sys.argv) > 6 else 512
            height = int(sys.argv[7]) if len(sys.argv) > 7 else 512
            
            # Initialize wrapper
            wrapper = MFLUXWrapper()
            
            # Check if MFLUX is available
            if not wrapper.get_model_info()['mflux_available']:
                result = {
                    'success': False,
                    'error': "MFLUX library not available. Please install MFLUX to generate real AI images."
                }
                print(json.dumps(result))
                sys.exit(1)
            
            # Generate the image
            image, metadata = wrapper.generate_image(
                prompt=prompt,
                model=model,
                steps=steps,
                guidance_scale=guidance_scale,
                seed=seed,
                width=width,
                height=height
            )
            
            # Convert PIL image to base64
            buffer = BytesIO()
            image.save(buffer, format='PNG')
            image_data = base64.b64encode(buffer.getvalue()).decode('utf-8')
            
            # Return JSON result to stdout
            result = {
                'success': True,
                'image_data': image_data,
                'metadata': metadata
            }
            
            print(json.dumps(result))
            
        except Exception as e:
            # Return error as JSON
            result = {
                'success': False,
                'error': f"Image generation failed: {str(e)}"
            }
            print(json.dumps(result))
            sys.exit(1) 
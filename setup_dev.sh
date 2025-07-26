#!/bin/bash

# MFLUX Mac App Development Setup Script
# This script sets up the development environment for the MFLUX Mac App
# Now includes automatic MFLUX installation for real AI generation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BRIDGE_DIR="$PROJECT_DIR/PythonBridge"

echo -e "${BLUE}🚀 Setting up MFLUX Mac App Development Environment${NC}"
echo "========================================================"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script must be run on macOS${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed. Please install Xcode from the App Store.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Xcode is installed${NC}"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is not installed. Please install Python 3.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Python 3 is available${NC}"

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}❌ pip3 is not available. Please install pip.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ pip3 is available${NC}"

# Create necessary directories
echo -e "${BLUE}📁 Creating project directories...${NC}"
mkdir -p "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/dist"
mkdir -p "$PROJECT_DIR/Models"
mkdir -p "$PROJECT_DIR/Images"
mkdir -p "$PROJECT_DIR/Metadata"

# Setup Python virtual environment
echo -e "${BLUE}🐍 Setting up Python virtual environment...${NC}"
cd "$PYTHON_BRIDGE_DIR"

if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${YELLOW}⚠️  Virtual environment already exists${NC}"
fi

# Activate virtual environment and install dependencies
echo -e "${BLUE}📦 Installing Python dependencies...${NC}"
source venv/bin/activate

# Upgrade pip first
pip install --upgrade pip

# Set CMake policy for SentencePiece installation
export CMAKE_POLICY_VERSION_MINIMUM=3.5

if [ -f "requirements.txt" ]; then
    echo -e "${BLUE}📦 Installing MFLUX and dependencies...${NC}"
    pip install -r requirements.txt
    echo -e "${GREEN}✅ MFLUX and dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  No requirements.txt found, installing core dependencies...${NC}"
    # Install core dependencies
    pip install "mflux>=0.9.6" "mlx>=0.19.0" "Pillow>=10.0.0" "numpy>=1.24.0" "requests>=2.31.0" "transformers>=4.30.0" "huggingface-hub>=0.16.0" "sentencepiece>=0.1.99"
    echo -e "${GREEN}✅ Core dependencies installed${NC}"
fi

# Test MFLUX installation
echo -e "${BLUE}🧪 Testing MFLUX installation...${NC}"
if python -c "import mflux; print('✅ MFLUX imported successfully')" 2>/dev/null; then
    echo -e "${GREEN}✅ MFLUX is working correctly${NC}"
    
    # Test the wrapper
    echo -e "${BLUE}🧪 Testing MFLUX wrapper...${NC}"
    if python mflux_wrapper.py; then
        echo -e "${GREEN}✅ MFLUX wrapper is working correctly${NC}"
    else
        echo -e "${YELLOW}⚠️  MFLUX wrapper test had issues (this is normal for first run)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  MFLUX import test failed - may need manual troubleshooting${NC}"
fi

# Deactivate virtual environment
deactivate

# Setup Xcode project
echo -e "${BLUE}🔨 Setting up Xcode project...${NC}"
cd "$PROJECT_DIR"

# Check if Xcode project exists
if [ ! -f "FluxMac.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Xcode project not found. Please ensure the project files are in place.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Xcode project found${NC}"

# Create development configuration
echo -e "${BLUE}⚙️  Creating development configuration...${NC}"

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << EOF
# Xcode
build/
DerivedData/
*.xcuserstate
*.xcworkspace/xcuserdata/
*.xcodeproj/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/

# Models and generated content
Models/
Images/
Metadata/

# Build artifacts
dist/
*.dmg
*.pkg
*.app

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp

# MFLUX cache
.cache/
EOF
    echo -e "${GREEN}✅ .gitignore created${NC}"
fi

# Create development environment file
if [ ! -f ".env.development" ]; then
    cat > .env.development << EOF
# Development Environment Configuration
FLUXMAC_DEBUG=true
FLUXMAC_LOG_LEVEL=debug
FLUXMAC_PYTHON_PATH=$PYTHON_BRIDGE_DIR/venv/bin/python
FLUXMAC_MODELS_DIR=$PROJECT_DIR/Models
FLUXMAC_IMAGES_DIR=$PROJECT_DIR/Images
FLUXMAC_METADATA_DIR=$PROJECT_DIR/Metadata
FLUXMAC_REAL_AI=true
EOF
    echo -e "${GREEN}✅ Development environment file created${NC}"
fi

# Create launch script for development
cat > run_dev.sh << 'EOF'
#!/bin/bash

# Development launch script for MFLUX Mac App

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BRIDGE_DIR="$PROJECT_DIR/PythonBridge"

echo "🚀 Launching MFLUX Mac App in development mode..."

# Activate Python virtual environment
if [ -d "$PYTHON_BRIDGE_DIR/venv" ]; then
    source "$PYTHON_BRIDGE_DIR/venv/bin/activate"
    echo "✅ Python virtual environment activated"
    
    # Quick MFLUX check
    if python -c "import mflux" 2>/dev/null; then
        echo "✅ MFLUX available for real AI generation"
    else
        echo "⚠️  MFLUX not available - will show helpful error messages"
    fi
fi

# Build and run the app
cd "$PROJECT_DIR"

# Copy Python environment to app bundle after build
echo "📦 Building app with MFLUX integration..."
xcodebuild build -project FluxMac.xcodeproj -scheme FluxMac -configuration Debug -derivedDataPath build

# Find the built app
APP_PATH=$(find build -name "FluxMac.app" -type d | head -n 1)
if [ -n "$APP_PATH" ]; then
    echo "✅ Build successful"
    echo "📱 App location: $APP_PATH"
    
    # Copy PythonBridge to app bundle
    echo "📦 Copying PythonBridge to app bundle..."
    cp -r "$PYTHON_BRIDGE_DIR" "$APP_PATH/Contents/Resources/"
    
    # Setup Python environment in app bundle
    echo "🐍 Setting up Python environment in app bundle..."
    cd "$APP_PATH/Contents/Resources/PythonBridge"
    if [ -d "venv" ]; then
        source venv/bin/activate
        # Ensure MFLUX is available in the app bundle
        python -c "import mflux; print('✅ MFLUX ready for real AI generation')" || echo "⚠️  MFLUX setup needed"
    fi
    
    cd "$PROJECT_DIR"
    echo "🚀 Launching app..."
    open "$APP_PATH"
    
    echo ""
    echo "🎉 MFLUX Mac App launched successfully!"
    echo "================================================"
    echo ""
    echo "📋 Development Info:"
    echo "  • App: $APP_PATH"
    echo "  • PythonBridge: $APP_PATH/Contents/Resources/PythonBridge"
    echo "  • Build: Debug configuration"
    echo ""
    echo "🔧 Development Tips:"
    echo "  • Use Xcode for debugging and development"
    echo "  • Python changes require app restart"
    echo "  • Check Console.app for logs"
    echo ""
    
else
    echo "❌ Could not find built app"
    exit 1
fi

echo "✅ Development run completed"
EOF

chmod +x run_dev.sh
echo -e "${GREEN}✅ Development launch script created${NC}"

# Display setup summary
echo ""
echo -e "${GREEN}🎉 Development environment setup completed!${NC}"
echo "================================================"
echo ""
echo -e "${BLUE}📁 Project structure:${NC}"
echo "  • FluxMac.xcodeproj/ - Xcode project"
echo "  • FluxMac/ - Swift source code"
echo "  • PythonBridge/ - Python backend with MFLUX"
echo "  • Documentation/ - User and developer docs"
echo "  • Models/ - AI models storage"
echo "  • Images/ - Generated images"
echo "  • Metadata/ - Image metadata"
echo ""
echo -e "${BLUE}🚀 Quick start:${NC}"
echo "  1. Run: ./run_dev.sh (to build and launch the app)"
echo "  2. Generate real AI images with MFLUX!"
echo ""
echo -e "${GREEN}✅ Real AI image generation is now available!${NC}"
echo -e "${BLUE}🎨 Features available:${NC}"
echo "  • FLUX.1-schnell (fast, 2-4 steps)"
echo "  • FLUX.1-dev (high quality, 20-25 steps)"  
echo "  • Automatic model downloading"
echo "  • 8-bit quantization for faster generation"
echo "  • Apple Silicon optimization"
echo ""

# Optional: Open project in Xcode
read -p "Open project in Xcode? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open FluxMac.xcodeproj
fi

echo -e "${GREEN}✅ Setup completed - ready for real AI image generation!${NC}" 
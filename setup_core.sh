#!/bin/bash

# Core Setup Script for MFLUX Mac App
# This script sets up the minimal environment needed for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BRIDGE_DIR="$PROJECT_DIR/PythonBridge"

echo -e "${BLUE}🚀 Setting up Core MFLUX Mac App Environment${NC}"
echo "=================================================="

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${BLUE}📋 Python version: ${PYTHON_VERSION}${NC}"

# Remove existing virtual environment
if [ -d "$PYTHON_BRIDGE_DIR/venv" ]; then
    echo -e "${BLUE}🗑️  Removing existing virtual environment...${NC}"
    rm -rf "$PYTHON_BRIDGE_DIR/venv"
fi

# Create new virtual environment
echo -e "${BLUE}🐍 Creating new virtual environment...${NC}"
cd "$PYTHON_BRIDGE_DIR"
python3 -m venv venv

# Activate virtual environment
echo -e "${BLUE}📦 Activating virtual environment...${NC}"
source venv/bin/activate

# Upgrade pip
echo -e "${BLUE}⬆️  Upgrading pip...${NC}"
pip install --upgrade pip

# Install core requirements
echo -e "${BLUE}📦 Installing core requirements...${NC}"
if [ -f "requirements_core.txt" ]; then
    pip install -r requirements_core.txt
    echo -e "${GREEN}✅ Core requirements installed${NC}"
else
    echo -e "${YELLOW}⚠️  Core requirements file not found${NC}"
fi

# Install essential packages individually
echo -e "${BLUE}📦 Installing essential packages individually...${NC}"
pip install mlx || echo -e "${YELLOW}⚠️  MLX installation failed${NC}"
pip install Pillow || echo -e "${YELLOW}⚠️  Pillow installation failed${NC}"
pip install requests || echo -e "${YELLOW}⚠️  Requests installation failed${NC}"

# Test basic imports
echo -e "${BLUE}🧪 Testing basic imports...${NC}"
python3 -c "
try:
    import mlx
    print('✅ MLX imported successfully')
except ImportError as e:
    print(f'❌ MLX import failed: {e}')

try:
    from PIL import Image
    print('✅ Pillow imported successfully')
except ImportError as e:
    print(f'❌ Pillow import failed: {e}')

try:
    import requests
    print('✅ Requests imported successfully')
except ImportError as e:
    print(f'❌ Requests import failed: {e}')
"

# Test MFLUX wrapper
echo -e "${BLUE}🧪 Testing MFLUX wrapper...${NC}"
python3 -c "
try:
    import sys
    sys.path.append('.')
    from mflux_wrapper import MFLUXWrapper
    wrapper = MFLUXWrapper()
    print('✅ MFLUX wrapper imported successfully')
except ImportError as e:
    print(f'❌ MFLUX wrapper import failed: {e}')
except Exception as e:
    print(f'⚠️  MFLUX wrapper test failed: {e}')
"

# Deactivate virtual environment
deactivate

echo ""
echo -e "${GREEN}🎉 Core environment setup completed!${NC}"
echo "================================================"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "  • Virtual environment created: $PYTHON_BRIDGE_DIR/venv"
echo "  • Core dependencies installed"
echo "  • Ready for development"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo "  1. Run: ./run_dev.sh (to build and launch the app)"
echo "  2. Open FluxMac.xcodeproj in Xcode"
echo "  3. Start developing!"
echo ""
echo -e "${YELLOW}⚠️  Note: Some advanced features may require additional dependencies${NC}"
echo "   • MFLUX-AI integration may need Python 3.11/3.12"
echo "   • Advanced ML features may require additional packages"
echo ""

echo -e "${GREEN}✅ Core setup completed${NC}" 
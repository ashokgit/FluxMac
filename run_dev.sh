#!/bin/bash

# Development Run Script for MFLUX Mac App
# This script builds and launches the app for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="FluxMac"

echo -e "${BLUE}🚀 Building and Running MFLUX Mac App${NC}"
echo "=========================================="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script must be run on macOS${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed or not in PATH${NC}"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Check if Python environment is set up
PYTHON_BRIDGE_DIR="$PROJECT_DIR/PythonBridge"
if [ ! -d "$PYTHON_BRIDGE_DIR/venv" ]; then
    echo -e "${YELLOW}⚠️  Python environment not found. Setting up...${NC}"
    ./setup_core.sh
fi

# Clean build directory
echo -e "${BLUE}🧹 Cleaning build directory...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the project
echo -e "${BLUE}🔨 Building project...${NC}"
cd "$PROJECT_DIR"

# Build using xcodebuild
xcodebuild -project FluxMac.xcodeproj \
           -scheme FluxMac \
           -configuration Debug \
           -derivedDataPath "$BUILD_DIR" \
           build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Find the built app
APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Could not find built app${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"
echo -e "${BLUE}📱 App location: $APP_PATH${NC}"

# Copy PythonBridge files to the app bundle
echo -e "${BLUE}📦 Copying PythonBridge to app bundle...${NC}"
PYTHON_BRIDGE_DEST="$APP_PATH/Contents/Resources/PythonBridge"
mkdir -p "$PYTHON_BRIDGE_DEST"

# Copy Python files
cp -r "$PYTHON_BRIDGE_DIR"/* "$PYTHON_BRIDGE_DEST/"

# Make sure the virtual environment is accessible
if [ -d "$PYTHON_BRIDGE_DIR/venv" ]; then
    echo -e "${BLUE}🐍 Setting up Python environment in app bundle...${NC}"
    # Create a symlink to the virtual environment
    ln -sf "$PYTHON_BRIDGE_DIR/venv" "$PYTHON_BRIDGE_DEST/venv"
fi

# Launch the app
echo -e "${BLUE}🚀 Launching app...${NC}"
open "$APP_PATH"

echo ""
echo -e "${GREEN}🎉 MFLUX Mac App launched successfully!${NC}"
echo "================================================"
echo ""
echo -e "${BLUE}📋 Development Info:${NC}"
echo "  • App: $APP_PATH"
echo "  • PythonBridge: $PYTHON_BRIDGE_DEST"
echo "  • Build: Debug configuration"
echo ""
echo -e "${BLUE}🔧 Development Tips:${NC}"
echo "  • Use Xcode for debugging and development"
echo "  • Python changes require app restart"
echo "  • Check Console.app for logs"
echo ""

echo -e "${GREEN}✅ Development run completed${NC}" 
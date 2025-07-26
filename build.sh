#!/bin/bash

# MFLUX Mac App Build Script
# This script builds the MFLUX Mac App for distribution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="FluxMac"
BUNDLE_ID="com.fluxmac.app"
VERSION="1.0.0"
BUILD_NUMBER="1"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"

echo -e "${BLUE}🚀 Building MFLUX Mac App${NC}"
echo "=================================="

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

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is not installed. Please install Python 3.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ System requirements met${NC}"

# Create build directories
echo -e "${BLUE}📁 Creating build directories...${NC}"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Install Python dependencies
echo -e "${BLUE}🐍 Installing Python dependencies...${NC}"
cd "$PROJECT_DIR/PythonBridge"
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    echo -e "${GREEN}✅ Python dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  No requirements.txt found, skipping Python dependencies${NC}"
fi

# Build the Xcode project
echo -e "${BLUE}🔨 Building Xcode project...${NC}"
cd "$PROJECT_DIR"

# Clean previous builds
xcodebuild clean -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release

# Build for release
xcodebuild build \
    -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Xcode build successful${NC}"
else
    echo -e "${RED}❌ Xcode build failed${NC}"
    exit 1
fi

# Find the built app
APP_PATH=$(find "$BUILD_DIR" -name "$APP_NAME.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Could not find built app${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found built app at: $APP_PATH${NC}"

# Copy PythonBridge to app bundle
echo -e "${BLUE}🐍 Copying PythonBridge to app bundle...${NC}"
APP_RESOURCES="$APP_PATH/Contents/Resources"
mkdir -p "$APP_RESOURCES/PythonBridge"

cp -R "$PROJECT_DIR/PythonBridge/"* "$APP_RESOURCES/PythonBridge/"

# Create app bundle
echo -e "${BLUE}📦 Creating app bundle...${NC}"
BUNDLE_NAME="${APP_NAME}-${VERSION}.app"
BUNDLE_PATH="$DIST_DIR/$BUNDLE_NAME"

cp -R "$APP_PATH" "$BUNDLE_PATH"

# Create DMG
echo -e "${BLUE}💿 Creating DMG...${NC}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

# Create temporary directory for DMG
DMG_TEMP="$DIST_DIR/dmg_temp"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
cp -R "$BUNDLE_PATH" "$DMG_TEMP/"

# Create DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DMG_PATH"

# Clean up temp directory
rm -rf "$DMG_TEMP"

echo -e "${GREEN}✅ DMG created: $DMG_PATH${NC}"

# Create installer package
echo -e "${BLUE}📦 Creating installer package...${NC}"
PKG_NAME="${APP_NAME}-${VERSION}.pkg"
PKG_PATH="$DIST_DIR/$PKG_NAME"

pkgbuild \
    --component "$BUNDLE_PATH" \
    --install-location "/Applications" \
    --identifier "$BUNDLE_ID" \
    --version "$VERSION" \
    "$PKG_PATH"

echo -e "${GREEN}✅ Installer package created: $PKG_PATH${NC}"

# Create checksums
echo -e "${BLUE}🔍 Creating checksums...${NC}"
cd "$DIST_DIR"

if command -v shasum &> /dev/null; then
    shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
    shasum -a 256 "$PKG_NAME" > "$PKG_NAME.sha256"
    echo -e "${GREEN}✅ Checksums created${NC}"
else
    echo -e "${YELLOW}⚠️  shasum not available, skipping checksums${NC}"
fi

# Display build summary
echo ""
echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo "=================================="
echo -e "${BLUE}📁 Build directory:${NC} $BUILD_DIR"
echo -e "${BLUE}📦 Distribution directory:${NC} $DIST_DIR"
echo ""
echo -e "${BLUE}📱 Generated files:${NC}"
echo "  • $BUNDLE_NAME"
echo "  • $DMG_NAME"
echo "  • $PKG_NAME"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "  1. Test the app bundle: $BUNDLE_PATH"
echo "  2. Test the DMG installer: $DMG_PATH"
echo "  3. Test the package installer: $PKG_PATH"
echo "  4. Sign the app for distribution (if needed)"
echo "  5. Upload to Mac App Store (if applicable)"
echo ""

# Optional: Open distribution directory
read -p "Open distribution directory? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$DIST_DIR"
fi

echo -e "${GREEN}✅ Build script completed${NC}" 
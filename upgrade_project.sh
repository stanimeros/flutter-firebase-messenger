#!/bin/bash
# How to use:
# ./upgrade_project.sh

set -e

echo "======================================"
echo "Starting Flutter Upgrade"
echo "======================================"
echo ""

# Flutter Updates
echo "🐦 Upgrading Flutter..."
if command -v flutter &> /dev/null; then
    flutter upgrade
    flutter pub upgrade --major-versions --tighten
    echo "✅ Flutter upgraded"
else
    echo "❌ Flutter not found"
    exit 1
fi
echo ""

# Dart Updates
echo "🎯 Upgrading Dart packages..."
if command -v dart &> /dev/null; then
    dart pub upgrade
    dart pub upgrade --major-versions --tighten
    echo "✅ Dart packages upgraded"
else
    echo "⚠️  Dart not found, skipping..."
fi
echo ""

# iOS Cleanup
echo "🧹 Cleaning iOS dependencies..."
if [ -d "ios" ]; then
    # Remove .symlinks
    if [ -L "ios/.symlinks" ] || [ -d "ios/.symlinks" ]; then
        rm -rf ios/.symlinks
        echo "  ✓ Removed ios/.symlinks"
    fi
    
    # Remove Pods
    if [ -d "ios/Pods" ]; then
        rm -rf ios/Pods
        echo "  ✓ Removed ios/Pods"
    fi
    
    # Remove Podfile.lock
    if [ -f "ios/Podfile.lock" ]; then
        rm -f ios/Podfile.lock
        echo "  ✓ Removed ios/Podfile.lock"
    fi
    
    echo "✅ iOS cleanup complete"
else
    echo "⚠️  ios/ directory not found, skipping iOS cleanup..."
fi
echo ""

# Pod repo update
echo "📚 Updating CocoaPods repository..."
if command -v pod &> /dev/null; then
    pod repo update
    echo "✅ Pod repo updated"
else
    echo "⚠️  CocoaPods not found, skipping..."
fi
echo ""

# Flutter clean
echo "🧼 Running flutter clean..."
flutter clean
echo "✅ Flutter clean complete"
echo ""

# Flutter pub get
echo "📥 Running flutter pub get..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

echo "======================================"
echo "✨ All upgrades complete!"
echo "======================================"
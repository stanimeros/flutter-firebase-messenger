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

# iOS Simulator Cleanup
echo "📱 Cleaning iOS Simulators..."
if command -v xcrun &> /dev/null; then
    xcrun simctl shutdown all 2>/dev/null || true
    echo "  ✓ Shut down all simulators"
    xcrun simctl erase all 2>/dev/null || true
    echo "  ✓ Erased all simulators"
    echo "✅ Simulator cleanup complete"
else
    echo "⚠️  xcrun not found, skipping simulator cleanup..."
fi
echo ""

# Flutter clean
echo "🧼 Running flutter clean..."
flutter clean
echo "✅ Flutter clean complete"
echo ""

# iOS CocoaPods Cleanup
echo "🧹 Cleaning iOS CocoaPods dependencies..."
if [ -d "ios" ]; then
    rm -rf ios/Pods ios/.symlinks ios/Flutter/Flutter.framework
    echo "  ✓ Removed ios/Pods, ios/.symlinks, and ios/Flutter/Flutter.framework"
    echo "✅ iOS cleanup complete"
else
    echo "⚠️  ios/ directory not found, skipping iOS cleanup..."
fi
echo ""

# Flutter pub get (must run before pod install to generate Generated.xcconfig)
echo "📥 Running flutter pub get..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Pod repo update and install
echo "📚 Updating and installing CocoaPods dependencies..."
if command -v pod &> /dev/null && [ -d "ios" ]; then
    pod repo update
    echo "  ✓ Pod repo updated"
    cd ios && pod install
    echo "  ✓ Pods installed"
    cd ..
    echo "✅ CocoaPods setup complete"
else
    if command -v pod &> /dev/null; then
        pod repo update
        echo "✅ Pod repo updated"
    else
        echo "⚠️  CocoaPods not found, skipping..."
    fi
fi
echo ""

echo "======================================"
echo "✨ All upgrades complete!"
echo "======================================"
#!/bin/bash
set -e
cd /Users/jabella78/Documents/OBD2

TARGET=${1:-pro}
BUMP_ARG=${2:-}

# Se richiesto esplicitamente un incremento di versione (es. ./build.sh all patch / minor / major / 1.0.4)
if [ -n "$BUMP_ARG" ]; then
    ./bump_version.sh "$BUMP_ARG"
fi

VERSION=$(cat VERSION 2>/dev/null || echo "1.0.3")
VERSION=$(echo "$VERSION" | tr -d '[:space:]')
BUILD_NUM=$(date +'%y%m%d.%H%M%S')
DEPLOY_ID="v${VERSION} (Build ${BUILD_NUM})"
echo "🚀 Nuovo Deployment: $DEPLOY_ID - iOS Target: $TARGET"

mkdir -p YaDiagPro.swiftpm/Resources YaDiagFree.swiftpm/Resources YamahaOBD2.swiftpm/Resources YaDiag.app/Contents/Resources
echo "$DEPLOY_ID" > YaDiagPro.swiftpm/Resources/deployment_id.txt
echo "$DEPLOY_ID" > YaDiagFree.swiftpm/Resources/deployment_id.txt
echo "$DEPLOY_ID" > YamahaOBD2.swiftpm/Resources/deployment_id.txt
echo "$DEPLOY_ID" > YaDiag.app/Contents/Resources/deployment_id.txt

# Aggiorna Info.plist di macOS
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUM}" YaDiag.app/Contents/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${BUILD_NUM}" YaDiag.app/Contents/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" YaDiag.app/Contents/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string ${VERSION}" YaDiag.app/Contents/Info.plist 2>/dev/null || true

# Aggiorna Package.swift per iOS (displayVersion e bundleVersion per Xcode / App Store Connect)
sed -i '' "s/displayVersion: .*/displayVersion: \"${VERSION}\",/" YaDiagPro.swiftpm/Package.swift
sed -i '' "s/bundleVersion: .*/bundleVersion: \"${BUILD_NUM}\",/" YaDiagPro.swiftpm/Package.swift

sed -i '' "s/displayVersion: .*/displayVersion: \"${VERSION}\",/" YaDiagFree.swiftpm/Package.swift
sed -i '' "s/bundleVersion: .*/bundleVersion: \"${BUILD_NUM}\",/" YaDiagFree.swiftpm/Package.swift

if [ -f YamahaOBD2.swiftpm/Package.swift ]; then
    sed -i '' "s/displayVersion: .*/displayVersion: \"${VERSION}\",/" YamahaOBD2.swiftpm/Package.swift
    sed -i '' "s/bundleVersion: .*/bundleVersion: \"${BUILD_NUM}\",/" YamahaOBD2.swiftpm/Package.swift
fi

echo "=== 1/3 Sincronizzazione sorgenti macOS (YaDiag unificata completa) ==="
rm -rf src/*
cp YaDiagPro.swiftpm/*.swift src/
rm -f src/Package.swift
cp YaDiagPro.swiftpm/Resources/* YaDiag.app/Contents/Resources/ 2>/dev/null || true

echo "=== 2/3 Compilazione macOS (YaDiag unificata in /Applications) ==="
swiftc src/*.swift -o YaDiag.app/Contents/MacOS/YaDiag
chmod +x YaDiag.app/Contents/MacOS/YaDiag
rm -rf /Applications/YaDiag.app /Applications/YamahaOBD2.app
cp -R YaDiag.app /Applications/YaDiag.app
echo "✅ macOS App unificata (tutte le funzioni attive) pronta in /Applications/YaDiag.app"

echo "=== 3/3 Compilazione iOS per App Store ($TARGET) ==="
DEVICE_CONNECTED=$(xcrun devicectl list devices 2>/dev/null | grep "iPhone Privato" | grep -E "(connected|available)" || true)

if [ "$TARGET" = "pro" ] || [ "$TARGET" = "all" ]; then
    echo "📦 Compilazione iOS YaDiag Pro..."
    cd /Users/jabella78/Documents/OBD2/YaDiagPro.swiftpm
    xcodebuild -scheme YaDiagPro -destination 'generic/platform=iOS' -derivedDataPath /tmp/YaDiagPro_DerivedData -allowProvisioningUpdates build -quiet
    echo "✅ YaDiag Pro compilata."
    if [ -n "$DEVICE_CONNECTED" ]; then
        echo "📱 Installazione YaDiag Pro su iPhone Privato..."
        xcrun devicectl device install app --device "CE3783A8-3365-5FEA-850B-019E0888CD20" "/tmp/YaDiagPro_DerivedData/Build/Products/Debug-iphoneos/YaDiag Pro.app" || true
        echo "✅ YaDiag Pro installata su iPhone Privato!"
    fi
fi

if [ "$TARGET" = "free" ] || [ "$TARGET" = "all" ]; then
    echo "📦 Compilazione iOS YaDiag Free..."
    cd /Users/jabella78/Documents/OBD2/YaDiagFree.swiftpm
    xcodebuild -scheme "YaDiag Free" -destination 'generic/platform=iOS' -derivedDataPath /tmp/YaDiagFree_DerivedData -allowProvisioningUpdates build -quiet
    echo "✅ YaDiag Free compilata con successo."
    if [ -n "$DEVICE_CONNECTED" ]; then
        echo "📱 Installazione YaDiag Free su iPhone Privato..."
        xcrun devicectl device install app --device "CE3783A8-3365-5FEA-850B-019E0888CD20" "/tmp/YaDiagFree_DerivedData/Build/Products/Debug-iphoneos/YaDiag Free.app" || true
        echo "✅ YaDiag Free installata su iPhone Privato!"
    fi
fi

echo "=== Build e Deployment completati! ==="

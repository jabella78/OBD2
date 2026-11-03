#!/bin/bash
set -e
cd /Users/jabella78/Documents/OBD2

# Genera identificatore univoco di build/deployment (timestamp al secondo)
BUILD_NUM=$(date +'%y%m%d.%H%M%S')
DEPLOY_ID="v1.0.2 (Build ${BUILD_NUM})"
echo "🚀 Nuovo Deployment: $DEPLOY_ID"

mkdir -p YamahaOBD2.swiftpm/Resources YaDiag.app/Contents/Resources
echo "$DEPLOY_ID" > YamahaOBD2.swiftpm/Resources/deployment_id.txt
echo "$DEPLOY_ID" > YaDiag.app/Contents/Resources/deployment_id.txt

# Aggiorna Info.plist di macOS
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUM}" YaDiag.app/Contents/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${BUILD_NUM}" YaDiag.app/Contents/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0.2" YaDiag.app/Contents/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0.2" YaDiag.app/Contents/Info.plist 2>/dev/null || true

# Aggiorna Package.swift per iOS
sed -i '' "s/displayVersion: .*/displayVersion: \"1.0.2\",/" YamahaOBD2.swiftpm/Package.swift
sed -i '' "s/bundleVersion: .*/bundleVersion: \"${BUILD_NUM}\",/" YamahaOBD2.swiftpm/Package.swift

echo "=== 1/3 Sincronizzazione sorgenti ==="
cp YamahaOBD2.swiftpm/*.swift src/
rm -f src/Package.swift
cp YamahaOBD2.swiftpm/Resources/* YaDiag.app/Contents/Resources/ 2>/dev/null || true

echo "=== 2/3 Compilazione macOS (Workspace & /Applications) ==="
swiftc src/*.swift -o YaDiag.app/Contents/MacOS/YaDiag
chmod +x YaDiag.app/Contents/MacOS/YaDiag
rm -rf /Applications/YaDiag.app /Applications/YamahaOBD2.app
cp -R YaDiag.app /Applications/YaDiag.app
echo "✅ macOS App pronta in /Applications/YaDiag.app"

echo "=== 3/3 Compilazione iOS (YaDiag) ==="
cd /Users/jabella78/Documents/OBD2/YamahaOBD2.swiftpm
xcodebuild -scheme YaDiag -destination 'generic/platform=iOS' -derivedDataPath /tmp/YamahaOBD2_DerivedData -allowProvisioningUpdates build -quiet

# Verifica se iPhone Privato è connesso per installazione automatica
DEVICE_CONNECTED=$(xcrun devicectl list devices 2>/dev/null | grep "iPhone Privato" | grep -E "(connected|available)" || true)
if [ -n "$DEVICE_CONNECTED" ]; then
    echo "📱 iPhone Privato rilevato connesso: installazione automatica in corso..."
    xcrun devicectl device install app --device "CE3783A8-3365-5FEA-850B-019E0888CD20" /tmp/YamahaOBD2_DerivedData/Build/Products/Debug-iphoneos/YaDiag.app
    echo "✅ iOS App aggiornata e installata con successo su iPhone Privato!"
else
    echo "ℹ️ iOS App compilata. (iPhone non collegato via cavo: installazione pronta al collegamento)."
fi

echo "=== Sincronizzazione e Build completate per iOS e macOS! ==="

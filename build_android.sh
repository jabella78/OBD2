#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANDROID_DIR="$SCRIPT_DIR/YaDiagAndroid"
ASSETS_DIR="$ANDROID_DIR/app/src/main/assets"
STORE_DIR="$SCRIPT_DIR/play_store_assets"

export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"

echo "==================================================="
echo "🤖 Sincronizzazione & Build YaDiag Android (Free & Pro)"
echo "==================================================="

mkdir -p "$ASSETS_DIR"
mkdir -p "$STORE_DIR"
echo "sdk.dir=$ANDROID_HOME" > "$ANDROID_DIR/local.properties"

# 1. Copia dtc_database.json, deployment_id.txt e yadiag_logo.png da YaDiagPro.swiftpm/Resources
RES_SRC="$SCRIPT_DIR/YaDiagPro.swiftpm/Resources"
if [ -f "$RES_SRC/dtc_database.json" ]; then
    cp "$RES_SRC/dtc_database.json" "$ASSETS_DIR/dtc_database.json"
    echo "✅ Copiato dtc_database.json in Android assets"
fi

if [ -f "$RES_SRC/deployment_id.txt" ]; then
    cp "$RES_SRC/deployment_id.txt" "$ASSETS_DIR/deployment_id.txt"
    echo "✅ Copiato deployment_id.txt in Android assets"
fi

if [ -f "$RES_SRC/yadiag_logo.png" ]; then
    cp "$RES_SRC/yadiag_logo.png" "$ASSETS_DIR/yadiag_logo.png"
    echo "✅ Copiato yadiag_logo.png in Android assets"
fi

# 2. Allinea versionName e versionCode in app/build.gradle.kts da VERSION
APP_VER=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "1.2.0")
IFS='.' read -r V_MAJ V_MIN V_PAT <<< "$APP_VER"
V_CODE=$(( ${V_MAJ:-1} * 10000 + ${V_MIN:-0} * 100 + ${V_PAT:-0} ))

if [ -f "$ANDROID_DIR/app/build.gradle.kts" ]; then
    sed -i '' "s/versionCode = [0-9]*/versionCode = $V_CODE/g" "$ANDROID_DIR/app/build.gradle.kts"
    sed -i '' "s/versionName = \"[^\"]*\"/versionName = \"$APP_VER\"/g" "$ANDROID_DIR/app/build.gradle.kts"
    echo "✅ Aggiornato app/build.gradle.kts -> versionName=$APP_VER (versionCode=$V_CODE)"
fi

# 3. Compilazione con Gradle (Debug APK + Release AAB firmati per Play Store)
if command -v gradle >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
    echo "🔨 Compilazione pacchetti Android Debug APK & Play Store Release AAB (Free & Pro)..."
    cd "$ANDROID_DIR"
    gradle assembleFreeDebug assembleProDebug bundleFreeRelease bundleProRelease -q
    echo "✅ APK Debug e Bundle AAB Release compilati con successo!"

    cp "$ANDROID_DIR/app/build/outputs/bundle/freeRelease/app-free-release.aab" "$STORE_DIR/YaDiag-Free-v${APP_VER}.aab"
    cp "$ANDROID_DIR/app/build/outputs/bundle/proRelease/app-pro-release.aab" "$STORE_DIR/YaDiag-Pro-v${APP_VER}.aab"
    echo "📦 Bundle Play Store copiati in: $STORE_DIR/"

    ANDROID_DEV=$(adb devices 2>/dev/null | grep -w "device" | head -n 1 | awk '{print $1}' || true)
    if [ -n "$ANDROID_DEV" ]; then
        echo "📱 Dispositivo Android rilevato ($ANDROID_DEV): installazione di YaDiag Free e YaDiag Pro..."
        adb -s "$ANDROID_DEV" install -r "$ANDROID_DIR/app/build/outputs/apk/free/debug/app-free-debug.apk"
        adb -s "$ANDROID_DEV" install -r "$ANDROID_DIR/app/build/outputs/apk/pro/debug/app-pro-debug.apk"
        echo "✅ YaDiag Free e YaDiag Pro installate sul dispositivo Android!"
    fi
fi

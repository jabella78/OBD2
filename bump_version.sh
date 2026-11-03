#!/bin/bash
set -e
cd /Users/jabella78/Documents/OBD2

BUMP_TYPE=${1:-patch} # patch, minor, major, o versione esplicita (es. 1.0.4)

CURRENT_VERSION=$(cat VERSION 2>/dev/null || echo "1.0.2")
CURRENT_VERSION=$(echo "$CURRENT_VERSION" | tr -d '[:space:]')

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
MAJOR=${MAJOR:-1}
MINOR=${MINOR:-0}
PATCH=${PATCH:-0}

case "$BUMP_TYPE" in
    patch)
        PATCH=$((PATCH + 1))
        NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
        ;;
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
        ;;
    *)
        if [[ "$BUMP_TYPE" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            NEW_VERSION="$BUMP_TYPE"
        else
            echo "Uso: ./bump_version.sh [patch|minor|major|<versione_esplicita>]"
            exit 1
        fi
        ;;
esac

echo "$NEW_VERSION" > VERSION
echo "✅ Versione aggiornata: $CURRENT_VERSION -> $NEW_VERSION"

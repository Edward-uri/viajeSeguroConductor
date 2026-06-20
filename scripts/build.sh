#!/usr/bin/env bash
set -euo pipefail

APP_NAME="viajeseguroconductor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEBUG_INFO_DIR="$PROJECT_DIR/build/debug-info"

echo "============================================"
echo "  $APP_NAME - Build Script"
echo "============================================"
echo ""

build_normal() {
    echo ">>> [1/2] Limpiando build anterior..."
    flutter clean
    echo ""

    echo ">>> [2/2] Compilando versión NORMAL (sin ofuscación)..."
    flutter build apk --release
    echo ""
    echo "✓ APK normal generado en: build/app/outputs/flutter-apk/app-release.apk"
}

build_obfuscated() {
    echo ">>> [1/3] Limpiando build anterior..."
    flutter clean
    echo ""

    echo ">>> [2/3] Creando directorio para debug-info..."
    mkdir -p "$DEBUG_INFO_DIR"
    echo ""

    echo ">>> [3/3] Compilando versión OFUSCADA (R8 + Flutter obfuscate)..."
    flutter build apk --release \
        --obfuscate \
        --split-debug-info="$DEBUG_INFO_DIR"
    echo ""
    echo "✓ APK ofuscado generado en: build/app/outputs/flutter-apk/app-release.apk"
    echo "✓ Mapa de símbolos guardado en: $DEBUG_INFO_DIR"
    echo ""
    echo "  Para desofuscar un stack trace:"
    echo "  flutter symbolize --input=<stacktrace.txt> \\"
    echo "    --debug-info=$DEBUG_INFO_DIR/app.android.symbols"
}

build_appbundle_normal() {
    echo ">>> Compilando AAB normal..."
    flutter clean
    flutter build appbundle --release
    echo "✓ AAB normal generado en: build/app/outputs/bundle/release/app-release.aab"
}

build_appbundle_obfuscated() {
    echo ">>> Compilando AAB ofuscado..."
    flutter clean
    flutter build appbundle --release \
        --obfuscate \
        --split-debug-info="$DEBUG_INFO_DIR"
    echo "✓ AAB ofuscado generado en: build/app/outputs/bundle/release/app-release.aab"
}

print_usage() {
    echo "Uso: $0 {normal|obfuscated|aab-normal|aab-obfuscated|all}"
    echo ""
    echo "  normal           APK release sin ofuscación"
    echo "  obfuscated       APK release con R8 + Flutter obfuscation"
    echo "  aab-normal       Android App Bundle sin ofuscación"
    echo "  aab-obfuscated   Android App Bundle con ofuscación"
    echo "  all              Compila las 4 variantes"
}

case "${1:-}" in
    normal)
        build_normal
        ;;
    obfuscated)
        build_obfuscated
        ;;
    aab-normal)
        build_appbundle_normal
        ;;
    aab-obfuscated)
        build_appbundle_obfuscated
        ;;
    all)
        build_normal
        build_obfuscated
        build_appbundle_normal
        build_appbundle_obfuscated
        ;;
    *)
        print_usage
        exit 1
        ;;
esac

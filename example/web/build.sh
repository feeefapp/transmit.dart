#!/bin/bash
# Build script for web test page

cd "$(dirname "$0")/.."
echo "Compiling Dart to JavaScript..."
dart compile js web/main.dart -o web/main.dart.js
echo "✅ Build complete! Open web/index.html in a browser"
echo "Or serve it with: python3 -m http.server 8080"


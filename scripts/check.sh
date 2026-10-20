#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
if ! command -v flutter >/dev/null; then export PATH="${FLUTTER_SDK:-$HOME/develop/flutter}/bin:$PATH"; fi
flutter pub get
flutter analyze
flutter test --coverage
flutter build web --release

#!/usr/bin/env bash
# Repair/generate native scaffolding using the installed SDK, preserving our code.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v flutter >/dev/null; then
  flutter_sdk="${FLUTTER_SDK:-$HOME/develop/flutter}"
  export PATH="$flutter_sdk/bin:$PATH"
fi
command -v flutter >/dev/null || { echo 'Run bash scripts/setup.sh first.' >&2; exit 1; }
export FLUTTER_SUPPRESS_ANALYTICS=true
staging_dir="$(mktemp -d)"
trap 'rm -rf -- "$staging_dir"' EXIT
flutter create --no-pub --platforms=android,web --org=com.example \
  --project-name=tvmaze_discovery "$staging_dir/tvmaze_discovery"
# Generated Gradle versions stay consistent with the installed Flutter SDK.
# Existing custom files (manifest, activity, colors, web entry point) are retained.
python3 - "$staging_dir/tvmaze_discovery" "$project_dir" <<'PYTHON'
import shutil, sys
from pathlib import Path
source, target = map(Path, sys.argv[1:])
for platform in ['android', 'web']:
    for item in (source / platform).rglob('*'):
        destination = target / item.relative_to(source)
        if item.is_file() and not destination.exists():
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, destination)
metadata = source / '.metadata'
if metadata.exists() and not (target / '.metadata').exists():
    shutil.copy2(metadata, target / '.metadata')
PYTHON
cd "$project_dir"
flutter config --enable-web
flutter pub get
dart format lib test integration_test test_driver
flutter analyze
flutter test
flutter build web --release
printf '\nProject prepared and web build verified. Android additionally needs JDK 17 and Android SDK.\n'

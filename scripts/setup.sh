#!/usr/bin/env bash
# Install the official Flutter SDK locally; no sudo or shell config edits.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_sdk="${FLUTTER_SDK:-$HOME/develop/flutter}"
flutter_version="${FLUTTER_VERSION:-3.35.7}"
export FLUTTER_SUPPRESS_ANALYTICS=true
for tool in git curl python3 tar xz unzip; do
  command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool" >&2; exit 1; }
done
if [[ ! -x "$flutter_sdk/bin/flutter" ]]; then
  if [[ -e "$flutter_sdk" ]]; then
    echo "An incomplete installation already exists at $flutter_sdk. Move it aside or set FLUTTER_SDK to a new location." >&2
    exit 1
  fi
  [[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || {
    echo "This installer targets Linux x86_64. Install Flutter manually on other systems, then run scripts/prepare.sh." >&2
    exit 1
  }
  mkdir -p "$(dirname -- "$flutter_sdk")"
  staging_dir="$(mktemp -d "$(dirname -- "$flutter_sdk")/.flutter-install.XXXXXX")"
  trap 'rm -rf -- "$staging_dir"' EXIT
  metadata_url='https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json'
  echo "Downloading official Flutter $flutter_version release metadata…"
  if ! curl --fail --location --retry 2 --connect-timeout 15 "$metadata_url" -o "$staging_dir/releases.json"; then
    echo "Could not fetch Flutter release metadata from $metadata_url. See the curl error above for the cause." >&2
    exit 1
  fi
  python3 - "$staging_dir/releases.json" "$flutter_version" "$staging_dir/release.txt" <<'PYTHON'
import json, sys
from pathlib import Path
metadata = json.loads(Path(sys.argv[1]).read_text())
release = next((r for r in metadata['releases'] if r.get('version') == sys.argv[2]
                and r.get('channel') == 'stable' and r.get('dart_sdk_arch', 'x64') == 'x64'), None)
if release is None:
    raise SystemExit('Requested stable Flutter version is absent from the official release index.')
Path(sys.argv[3]).write_text(metadata['base_url'] + '/' + release['archive'] + '\n' + release['sha256'] + '\n')
PYTHON
  mapfile -t release_info < "$staging_dir/release.txt"
  curl --fail --location --retry 2 --connect-timeout 15 "${release_info[0]}" -o "$staging_dir/flutter.tar.xz"
  python3 - "$staging_dir/flutter.tar.xz" "${release_info[1]}" <<'PYTHON'
import hashlib, sys
with open(sys.argv[1], 'rb') as archive:
    digest = hashlib.file_digest(archive, 'sha256').hexdigest()
if digest != sys.argv[2]:
    raise SystemExit('SDK checksum mismatch. Installation stopped.')
print('Official SDK SHA-256 verified.')
PYTHON
  tar -xf "$staging_dir/flutter.tar.xz" -C "$staging_dir"
  mv -- "$staging_dir/flutter" "$flutter_sdk"
fi
export PATH="$flutter_sdk/bin:$PATH"
flutter --disable-analytics
flutter --version
bash "$project_dir/scripts/prepare.sh"
flutter doctor -v
if command -v code >/dev/null; then
  if ! code --install-extension Dart-Code.flutter; then
    echo 'The Flutter VS Code extension could not be installed automatically. Install the recommended extension in VS Code.' >&2
  fi
fi
printf '\nFlutter is installed at %s\nOpen this project in VS Code, install the recommended Flutter extension, and press F5.\n' "$flutter_sdk"

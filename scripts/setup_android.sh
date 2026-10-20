#!/usr/bin/env bash
# Optional Android toolchain setup for Linux x86_64. No sudo required.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_sdk="${FLUTTER_SDK:-$HOME/develop/flutter}"
android_sdk="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
java_dir="${TVMAZE_JDK_DIR:-$HOME/develop/jdk-17}"
export PATH="$flutter_sdk/bin:$PATH"
command -v flutter >/dev/null || { echo 'Run bash scripts/setup.sh first.' >&2; exit 1; }
[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || { echo 'Use Android Studio on other systems.' >&2; exit 1; }
staging_dir="$(mktemp -d)"
trap 'rm -rf -- "$staging_dir"' EXIT
if [[ ! -x "$java_dir/bin/java" ]]; then
  [[ ! -e "$java_dir" ]] || { echo "Move incomplete Java installation aside: $java_dir" >&2; exit 1; }
  curl --fail --location --retry 2 'https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=linux&vendor=eclipse' -o "$staging_dir/java.json"
  python3 - "$staging_dir/java.json" "$staging_dir/java-release.txt" <<'PYTHON'
import json, sys
from pathlib import Path
package = json.loads(Path(sys.argv[1]).read_text())[0]['binary']['package']
Path(sys.argv[2]).write_text(package['link'] + '\n' + package['checksum'] + '\n')
PYTHON
  mapfile -t java_info < "$staging_dir/java-release.txt"
  curl --fail --location --retry 2 "${java_info[0]}" -o "$staging_dir/java.tar.gz"
  python3 - "$staging_dir/java.tar.gz" "${java_info[1]}" <<'PYTHON'
import hashlib, sys
with open(sys.argv[1], 'rb') as archive:
    if hashlib.file_digest(archive, 'sha256').hexdigest() != sys.argv[2]:
        raise SystemExit('Java checksum mismatch.')
PYTHON
  mkdir -p "$staging_dir/jdk" "$(dirname -- "$java_dir")"
  tar -xzf "$staging_dir/java.tar.gz" --strip-components=1 -C "$staging_dir/jdk"
  mv -- "$staging_dir/jdk" "$java_dir"
fi
export JAVA_HOME="$java_dir"
export ANDROID_HOME="$android_sdk"
export PATH="$java_dir/bin:$android_sdk/cmdline-tools/latest/bin:$android_sdk/platform-tools:$PATH"
if [[ ! -x "$android_sdk/cmdline-tools/latest/bin/sdkmanager" ]]; then
  [[ ! -e "$android_sdk/cmdline-tools/latest" ]] || { echo 'Move the incomplete command-line tools directory aside first.' >&2; exit 1; }
  curl --fail --location --retry 2 'https://dl.google.com/android/repository/repository2-1.xml' -o "$staging_dir/android.xml"
  python3 - "$staging_dir/android.xml" "$staging_dir/android-release.txt" <<'PYTHON'
import sys, xml.etree.ElementTree as ET
from pathlib import Path
root = ET.parse(sys.argv[1]).getroot()
package = next(e for e in root.iter() if e.tag.split('}')[-1] == 'remotePackage' and e.get('path') == 'cmdline-tools;latest')
for archive in package.iter():
    if archive.tag.split('}')[-1] != 'archive': continue
    values = {e.tag.split('}')[-1]: e.text for e in archive.iter()}
    if values.get('host-os') == 'linux':
        Path(sys.argv[2]).write_text('https://dl.google.com/android/repository/' + values['url'] + '\n' + values['checksum'] + '\n')
        break
else:
    raise SystemExit('Linux command-line tools are absent from the official index.')
PYTHON
  mapfile -t android_info < "$staging_dir/android-release.txt"
  curl --fail --location --retry 2 "${android_info[0]}" -o "$staging_dir/tools.zip"
  python3 - "$staging_dir/tools.zip" "${android_info[1]}" <<'PYTHON'
import hashlib, sys, zipfile
from pathlib import Path
archive = Path(sys.argv[1])
with archive.open('rb') as stream:
    algorithm = 'sha256' if len(sys.argv[2]) == 64 else 'sha1'
    if hashlib.file_digest(stream, algorithm).hexdigest() != sys.argv[2]:
        raise SystemExit('Android tools checksum mismatch.')
with zipfile.ZipFile(archive) as bundle:
    bundle.extractall(archive.parent / 'tools')
PYTHON
  mkdir -p "$android_sdk/cmdline-tools"
  mv -- "$staging_dir/tools/cmdline-tools" "$android_sdk/cmdline-tools/latest"
  chmod +x "$android_sdk/cmdline-tools/latest/bin/"*
fi
flutter config --jdk-dir "$java_dir" --android-sdk "$android_sdk"
echo 'Review and accept the Android SDK licenses below to proceed.'
sdkmanager --sdk_root="$android_sdk" --licenses
sdkmanager --sdk_root="$android_sdk" 'platform-tools' 'platforms;android-36' 'build-tools;35.0.0' 'ndk;27.0.12077973'
cd "$project_dir"
flutter doctor -v
flutter build apk --debug
printf '\nAPK: %s/build/app/outputs/flutter-apk/app-debug.apk\n' "$project_dir"
echo 'Connect an Android phone with USB debugging enabled, select it in VS Code, and press F5.'

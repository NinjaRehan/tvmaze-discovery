#!/usr/bin/env bash
# Locate a usable SDK or install the official command-line tools for CI.
set -euo pipefail
: "${JAVA_HOME:?Set JAVA_HOME to JDK 17 before running this script.}"
: "${RUNNER_TEMP:?This script requires a GitHub Actions RUNNER_TEMP directory.}"

work_dir="$(mktemp -d "$RUNNER_TEMP/android-setup.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
sdk_manager=''
android_sdk=''
for candidate in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "${TVMAZE_ANDROID_SDK_HINT-/usr/local/lib/android/sdk}"; do
  [[ -n "$candidate" ]] || continue
  for manager in "$candidate/cmdline-tools/latest/bin/sdkmanager" "$candidate"/cmdline-tools/*/bin/sdkmanager; do
    if [[ -x "$manager" ]] && "$manager" --version > "$work_dir/version.log" 2>&1; then
      android_sdk="$candidate"
      sdk_manager="$manager"
      break 2
    fi
  done
done

if [[ -z "$sdk_manager" ]]; then
  android_sdk="$RUNNER_TEMP/tvmaze-android-sdk"
  cli_archive='commandlinetools-linux-13114758_latest.zip'
  echo 'No usable Android SDK was found. Downloading official command-line tools.'
  curl --fail --location --retry 3 --connect-timeout 30 \
    https://dl.google.com/android/repository/repository2-1.xml -o "$work_dir/repository.xml"
  python3 - "$work_dir/repository.xml" "$cli_archive" "$work_dir/archive.txt" <<'PYTHON'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path, PurePosixPath
root = ET.parse(sys.argv[1]).getroot()
for entry in root.iter():
    if entry.tag.rsplit('}', 1)[-1] != 'complete':
        continue
    fields = {child.tag.rsplit('}', 1)[-1]: child for child in entry}
    url = fields.get('url')
    checksum = fields.get('checksum')
    if url is None or checksum is None:
        continue
    relative = (url.text or '').strip()
    if PurePosixPath(relative).name != sys.argv[2]:
        continue
    algorithm = checksum.get('type', 'sha1').lower().replace('-', '')
    if algorithm not in ('sha1', 'sha256'):
        raise SystemExit('Unsupported Android archive checksum algorithm.')
    Path(sys.argv[3]).write_text('\n'.join([
        'https://dl.google.com/android/repository/' + relative,
        algorithm, (checksum.text or '').strip(),
    ]) + '\n')
    break
else:
    raise SystemExit('Pinned Android command-line tools were not found in the official repository index.')
PYTHON
  mapfile -t archive_info < "$work_dir/archive.txt"
  curl --fail --location --retry 3 --connect-timeout 30 \
    "${archive_info[0]}" -o "$work_dir/tools.zip"
  python3 - "$work_dir/tools.zip" "${archive_info[1]}" "${archive_info[2]}" <<'PYTHON'
import hashlib, sys
checksum = hashlib.new(sys.argv[2])
with open(sys.argv[1], 'rb') as stream:
    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
        checksum.update(chunk)
if checksum.hexdigest() != sys.argv[3]:
    raise SystemExit('Android command-line tools checksum mismatch.')
print('Official Android command-line tools checksum verified.')
PYTHON
  unzip -q "$work_dir/tools.zip" -d "$work_dir/unpacked"
  mkdir -p "$android_sdk/cmdline-tools"
  if [[ -e "$android_sdk/cmdline-tools/latest" ]]; then
    echo "An incomplete SDK already exists at $android_sdk/cmdline-tools/latest." >&2
    exit 1
  fi
  mv "$work_dir/unpacked/cmdline-tools" "$android_sdk/cmdline-tools/latest"
  chmod +x "$android_sdk/cmdline-tools/latest/bin/"*
  sdk_manager="$android_sdk/cmdline-tools/latest/bin/sdkmanager"
fi

export ANDROID_HOME="$android_sdk"
export ANDROID_SDK_ROOT="$android_sdk"
export PATH="$(dirname -- "$sdk_manager"):$android_sdk/platform-tools:$PATH"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'ANDROID_HOME=%s\nANDROID_SDK_ROOT=%s\n' "$android_sdk" "$android_sdk" >> "$GITHUB_ENV"
fi
if [[ -n "${GITHUB_PATH:-}" ]]; then
  printf '%s\n' "$(dirname -- "$sdk_manager")" "$android_sdk/platform-tools" >> "$GITHUB_PATH"
fi
printf 'Using Android SDK: %s\n' "$android_sdk"
"$sdk_manager" --version
flutter config --jdk-dir "$JAVA_HOME" --android-sdk "$android_sdk"
printf 'y\n%.0s' {1..200} > "$work_dir/licenses.txt"
"$sdk_manager" --sdk_root="$android_sdk" --licenses < "$work_dir/licenses.txt"
"$sdk_manager" --sdk_root="$android_sdk" --install \
  'platform-tools' 'platforms;android-36' 'build-tools;35.0.0' 'ndk;27.0.12077973'

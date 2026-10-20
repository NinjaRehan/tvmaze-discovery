#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
if ! command -v flutter >/dev/null; then export PATH="${FLUTTER_SDK:-$HOME/develop/flutter}/bin:$PATH"; fi
if [[ $# -ne 1 ]]; then echo 'Usage: bash scripts/screenshots.sh chrome|<android-device-id>'; flutter devices; exit 1; fi
if [[ "$1" == chrome ]]; then
  command -v chromedriver >/dev/null || { echo 'Chrome capture requires chromedriver matching your Chromium version.' >&2; exit 1; }
  export CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/usr/bin/chromium}"
  capture_dir="$(mktemp -d)"
  driver_pid=''
  cleanup() {
    if [[ -n "$driver_pid" ]]; then kill "$driver_pid" 2>/dev/null || true; wait "$driver_pid" 2>/dev/null || true; fi
    rm -rf -- "$capture_dir"
  }
  trap cleanup EXIT
  chromedriver --port=4444 > "$capture_dir/chromedriver.log" 2>&1 &
  driver_pid=$!
  python3 - "$driver_pid" <<'PYTHON'
import json, os, sys, time, urllib.request
for attempt in range(100):
    try:
        os.kill(int(sys.argv[1]), 0)
        with urllib.request.urlopen('http://127.0.0.1:4444/status', timeout=1) as response:
            if json.load(response)['value']['ready']: break
    except (OSError, ValueError): pass
    time.sleep(.1)
else: raise SystemExit('ChromeDriver did not start. Check whether port 4444 is already occupied.')
PYTHON
  flutter drive --driver=test_driver/screenshots.dart --target=integration_test/screenshots_test.dart \
    -d chrome --headless --browser-dimension=430x932@1 --driver-port=4444
else
  flutter drive --driver=test_driver/screenshots.dart --target=integration_test/screenshots_test.dart -d "$1"
fi
python3 scripts/update_screenshot_gallery.py

#!/usr/bin/env bash
# Complete browser-based submission audit from a normal terminal.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
export PATH="${FLUTTER_SDK:-$HOME/develop/flutter}/bin:$PATH"
export CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/usr/bin/chromium}"
mkdir -p docs/audit
set -o pipefail
bash scripts/check.sh 2>&1 | tee docs/audit/checks.log
bash scripts/screenshots.sh chrome 2>&1 | tee docs/audit/live-flow.log
printf '\nAnalysis, tests, web build, live API flow, persistence restoration and screenshot capture passed.\n'
printf 'Review docs/screenshots and README.md. Android APK verification is a separate check.\n'

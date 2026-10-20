# Runtime screenshots

This folder intentionally contains no fabricated screenshots.

After Flutter and the Android toolchain are installed, use Chromium/ChromeDriver or connect an Android device and run:

```bash
bash scripts/screenshots.sh chrome
# Or:
# bash scripts/screenshots.sh <device-id>
```

The integration test captures live API content, including:

1. `01-discover.png`
2. `02-search.png`
3. `03-details.png`
4. `04-episodes.png`
5. `05-cast.png`
6. `06-watchlist.png`
7. `07-empty-watchlist.png`

The capture test uses real SharedPreferences storage under a unique audit key to avoid changing your personal saved shows. It disposes the widget tree and creates fresh BLoCs to verify restoration, then removes the saved show and cleans up the audit key. This is not an OS-level force-stop test; that remains on the manual acceptance checklist. It does not replace TVMaze with hardcoded show data. A working internet connection is required. API outages or failed live data assertions should fail the capture rather than produce misleading images.

The script inserts these images into the main README only after all seven exist. Review and commit them before submission. For manual capture, navigate to each screen on the device and use `flutter screenshot -d <device-id> -o docs/screenshots/<name>.png`, then run `python3 scripts/update_screenshot_gallery.py`.

"""Exercise SDK discovery/bootstrap without downloading or changing a real SDK."""
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).resolve().parents[1] / 'setup_android_ci.sh'
ARCHIVE = 'commandlinetools-linux-13114758_latest.zip'
MANAGER = '''#!/usr/bin/env bash
set -eu
printf '%s\\n' "$*" >> "$SDK_CALL_LOG"
if [[ "$*" == --version ]]; then echo '19.0'; fi
if [[ "$*" == *--licenses* ]]; then read -r answer; test "$answer" = y; fi
if [[ "$*" == *--install* && "${TEST_INSTALL_FAILURE:-0}" == 1 ]]; then exit 7; fi
'''


class AndroidSetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.runner = self.root / 'runner'
        self.runner.mkdir()
        self.env = os.environ.copy()
        self.env.update({
            'PATH': str(self.bin) + os.pathsep + self.env['PATH'],
            'JAVA_HOME': str(self.root / 'jdk-17'),
            'RUNNER_TEMP': str(self.runner),
            'ANDROID_HOME': '',
            'ANDROID_SDK_ROOT': '',
            'TVMAZE_ANDROID_SDK_HINT': '',
            'GITHUB_ENV': str(self.root / 'github-env'),
            'GITHUB_PATH': str(self.root / 'github-path'),
            'SDK_CALL_LOG': str(self.root / 'sdk-calls'),
            'FLUTTER_CALL_LOG': str(self.root / 'flutter-calls'),
            'TEST_INSTALL_FAILURE': '0',
        })
        self.executable(self.bin / 'flutter', '''#!/usr/bin/env bash
printf '%s\\n' "$*" >> "$FLUTTER_CALL_LOG"
''')
        # A curl stub permits only the two official download paths used here.
        self.executable(self.bin / 'curl', '''#!/usr/bin/env python3
import os, shutil, sys
url = next(arg for arg in sys.argv[1:] if arg.startswith('https://'))
target = sys.argv[sys.argv.index('-o') + 1]
if url == 'https://dl.google.com/android/repository/repository2-1.xml':
    source = os.environ['TEST_REPOSITORY_XML']
elif url == 'https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip':
    source = os.environ['TEST_ARCHIVE_ZIP']
else:
    raise SystemExit('Unexpected network request: ' + url)
shutil.copyfile(source, target)
''')

    @staticmethod
    def executable(path, content):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        path.chmod(0o755)

    def repository(self, *, corrupt_checksum=False):
        archive = self.root / 'tools.zip'
        with zipfile.ZipFile(archive, 'w') as bundle:
            bundle.writestr('cmdline-tools/bin/sdkmanager', MANAGER)
        checksum = hashlib.sha1(archive.read_bytes()).hexdigest()
        if corrupt_checksum:
            checksum = '0' * 40
        xml = self.root / 'repository.xml'
        xml.write_text(f'''<sdk-repository xmlns="urn:android:test">
          <remotePackage path="cmdline-tools;19.0"><archives><archive>
            <host-os>linux</host-os><complete>
              <url>{ARCHIVE}</url><checksum type="sha1">{checksum}</checksum>
            </complete>
          </archive></archives></remotePackage>
        </sdk-repository>''')
        self.env['TEST_REPOSITORY_XML'] = str(xml)
        self.env['TEST_ARCHIVE_ZIP'] = str(archive)

    def run_setup(self):
        return subprocess.run(['bash', str(SCRIPT)], env=self.env,
                              text=True, capture_output=True, timeout=15)

    def assert_configured(self, result, sdk):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        environment = Path(self.env['GITHUB_ENV']).read_text()
        self.assertIn(f'ANDROID_HOME={sdk}\n', environment)
        self.assertIn(f'ANDROID_SDK_ROOT={sdk}\n', environment)
        calls = Path(self.env['SDK_CALL_LOG']).read_text()
        self.assertIn(f'--sdk_root={sdk} --install platform-tools platforms;android-36', calls)
        self.assertIn('build-tools;35.0.0 ndk;27.0.12077973', calls)
        self.assertIn(f'--android-sdk {sdk}', Path(self.env['FLUTTER_CALL_LOG']).read_text())

    def test_uses_android_home_even_when_sdkmanager_is_not_on_path(self):
        sdk = self.root / 'existing-sdk'
        self.executable(sdk / 'cmdline-tools/latest/bin/sdkmanager', MANAGER)
        self.env['ANDROID_HOME'] = str(sdk)
        self.assert_configured(self.run_setup(), sdk)

    def test_uses_sdk_root_and_versioned_command_line_tools(self):
        sdk = self.root / 'sdk-root'
        self.executable(sdk / 'cmdline-tools/19.0/bin/sdkmanager', MANAGER)
        self.env['ANDROID_SDK_ROOT'] = str(sdk)
        self.assert_configured(self.run_setup(), sdk)

    def test_bootstraps_verified_tools_when_sdk_variables_are_empty(self):
        self.repository()
        sdk = self.runner / 'tvmaze-android-sdk'
        self.assert_configured(self.run_setup(), sdk)
        self.assertTrue(os.access(sdk / 'cmdline-tools/latest/bin/sdkmanager', os.X_OK))

    def test_bad_checksum_stops_before_sdk_activation(self):
        self.repository(corrupt_checksum=True)
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('checksum mismatch', result.stderr)
        self.assertFalse(Path(self.env['GITHUB_ENV']).exists())
        self.assertFalse(Path(self.env['FLUTTER_CALL_LOG']).exists())

    def test_broken_existing_manager_falls_back_to_official_tools(self):
        sdk = self.root / 'broken-sdk'
        self.executable(sdk / 'cmdline-tools/latest/bin/sdkmanager', '#!/bin/sh\nexit 9\n')
        self.env['ANDROID_HOME'] = str(sdk)
        self.repository()
        self.assert_configured(self.run_setup(), self.runner / 'tvmaze-android-sdk')

    def test_package_install_failure_is_not_hidden(self):
        sdk = self.root / 'existing-sdk'
        self.executable(sdk / 'cmdline-tools/latest/bin/sdkmanager', MANAGER)
        self.env['ANDROID_HOME'] = str(sdk)
        self.env['TEST_INSTALL_FAILURE'] = '1'
        self.assertEqual(self.run_setup().returncode, 7)


if __name__ == '__main__':
    unittest.main()

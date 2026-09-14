"""Validate installer inputs without executing provisioning or any host writes."""
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'install_pi.sh').read_text()
DEFAULTS = SOURCE[SOURCE.index('TESSAVISION_FLOOR=3'):SOURCE.index('exec >')]
VALIDATION = SOURCE[SOURCE.index('case "$TESSAVISION_FLOOR"'):SOURCE.index('systemctl disable')]


def validate(*assignments, example=None):
    # Fixed shell code plus positional arguments; values never become shell code.
    code = DEFAULTS + '\n'
    if example:
        code += 'source "$1"; shift\n'
    code += 'for assignment in "$@"; do export "$assignment"; done\n' + VALIDATION
    args = [str(example)] if example else []
    return subprocess.run(['bash', '-c', code, 'test', *args, *assignments],
                          capture_output=True, text=True)


class InstallerConfigTests(unittest.TestCase):
    def test_defaults(self):
        self.assertEqual(validate().returncode, 0)

    def test_floor_examples(self):
        for example in ('1f.conf.example', '3f.conf.example'):
            result = validate(example=ROOT / 'config' / example)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_connection_names_with_spaces(self):
        self.assertEqual(validate('TESSAVISION_WIFI_CONNECTION=Mox external radio').returncode, 0)

    def test_invalid_input_rejected(self):
        for assignment in (
            'TESSAVISION_FLOOR=5', 'TESSAVISION_HOSTNAME=bad host',
            'TESSAVISION_FOREGROUND=purple', 'TESSAVISION_BACKGROUND=orange',
            'TESSAVISION_WIFI_DEVICE=', 'TESSAVISION_WIFI_DEVICE=too-long-interface',
            'TESSAVISION_WIFI_CONNECTION=', 'TESSAVISION_WIFI_CONNECTION=bad"quote',
            'TESSAVISION_WIFI_CONNECTION=bad%specifier',
            'TESSAVISION_WIFI_CONNECTION=bad\nnewline',
        ):
            with self.subTest(assignment=assignment):
                result = validate(assignment)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Invalid TESSAVISION_', result.stdout)


if __name__ == '__main__':
    unittest.main()

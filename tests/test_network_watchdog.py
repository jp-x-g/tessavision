"""Check recovery decisions without touching real network interfaces."""
import pathlib
import subprocess
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / 'network_watchdog.sh'
HARNESS = r'''
NM_STATE="$2"
TESSAVISION_WIFI_DEVICE="$3"
TESSAVISION_WIFI_CONNECTION=Mox-dongle
nmcli() {
    if [[ "$1" == -g ]]; then
        printf '%s' "$NM_STATE"
    else
        printf 'nmcli %s\n' "$*"
    fi
}
rfkill() { printf 'rfkill %s\n' "$*"; }
source "$1"
'''


def run(state, device='wlan1'):
    return subprocess.run(
        ['bash', '-c', HARNESS, 'test', str(SCRIPT), state, device],
        check=True, capture_output=True, text=True,
    ).stdout


class WatchdogTests(unittest.TestCase):
    def test_preserves_connected_and_connecting_states(self):
        for state in (40, 50, 60, 70, 80, 90, 100):
            self.assertEqual(run(f'{state} (state description)'), '')

    def test_reconnects_selected_external_device(self):
        output = run('30 (disconnected)')
        self.assertIn('rfkill unblock wifi', output)
        self.assertIn('nmcli device set wlan1 managed yes', output)
        self.assertIn('nmcli --wait 45 connection up Mox-dongle ifname wlan1', output)

    def test_default_still_uses_onboard_device(self):
        self.assertIn('ifname wlan0', run('30 (disconnected)', ''))

    def test_absent_dongle_leaves_fallback_alone(self):
        output = run('')
        self.assertIn('unavailable', output)
        self.assertNotIn('nmcli ', output)
        self.assertNotIn('rfkill ', output)


if __name__ == '__main__':
    unittest.main()

# TessaVision — Mox displays

Mox display software developed from Jake's original
[`jp-x-g/tessavision`](https://github.com/jp-x-g/tessavision).
The September 24, 2026 handover brings the multi-floor reliability and recovery
work back to that repository. Earlier versions remain in Git history.
Publishing this source does not update either running TV.

## Current deployments

- Raspberry Pi Zero-family displays
- Per-Pi floor, hostname, and console colors are configured through
  `/boot/firmware/tessavision.conf`; see `tessavision.conf.example`
- Time zone: `America/Los_Angeles`
- HDMI framebuffer: 1920×1080 at 60 Hz
- Terminal grid: 120 columns × 33 rows
- Renderer: Linux kernel console using
  `Lat15-TerminusBold32x16.psf.gz`
- Console blanking and power-down disabled
- `tessavision-display.service` runs `compose.sh` directly on tty1

`install_pi.sh` recreates the Pi services, display configuration, dedicated
SSH service account, and Tailscale package installation. Runtime credentials in
`auth/` and generated files in `temp/` are intentionally ignored by Git.

For a new Pi or replacement card, follow
[`PROVISIONING.md`](PROVISIONING.md). It starts by establishing a
Wi-Fi-independent USB SSH route and ends with a real reboot plus USB, LAN, and
Tailscale acceptance tests.

## Shared baseline and deliberate updates

`main` is the shared software baseline for every floor. Use the same app and
recovery scripts on both TVs at the next approved rollout; express differences
through configuration, not floor-specific source branches.

The installer takes floor, hostname, colors, Wi-Fi device and profile from
`/boot/firmware/tessavision.conf`. Start with
[`config/1f.conf.example`](config/1f.conf.example) or
[`config/3f.conf.example`](config/3f.conf.example). Credentials and Tailscale
identities remain private and unique where appropriate. The installer generates
the watchdog device override and installs bounded persistent logging.

Publishing Git commits does not deploy them. The live TVs are intentionally
left at their working versions until a separate rollout is requested. See
[`OPERATIONS.md`](OPERATIONS.md) for verified deployment differences and the
future update procedure. `install_pi.sh` replaces the app and schedules a reboot;
it is a provisioning program, not an unattended update command.

Run local regression checks without network access or Pi access:

```sh
python3 -m unittest discover -s tests -v
for script in compose.sh events.sh ticker.sh network_watchdog.sh install_pi.sh; do
  bash -n "$script" || exit
done
```

## Working from another computer

Clone this repository on each development computer and use normal Git
pull/commit/push workflows. Do not synchronize the repository's `.git` directory
with Syncthing; simultaneous filesystem synchronization can corrupt repository
state or create conflict copies.

Syncthing may be used for a separate credentials or shared-assets directory when
needed. Keep API keys and other secrets out of Git.

Remote administration of the deployed Pi is available over Tailscale:

```sh
ssh tessavision
```

Configure the same SSH host alias and a dedicated SSH key on each authorized
administration computer.

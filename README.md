# TessaVision — Mox displays

Private Mox deployment derived from
[`jp-x-g/tessavision`](https://github.com/jp-x-g/tessavision).

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

## Working from another computer

Clone this private repository on each development computer and use normal Git
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

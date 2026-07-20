# TessaVision — Mox 3F

Private Mox deployment derived from
[`jp-x-g/tessavision`](https://github.com/jp-x-g/tessavision).

## Current deployment

- Raspberry Pi Zero 2 W
- Floor selector: `3`
- Time zone: `America/Los_Angeles`
- HDMI framebuffer: 1920×1080 at 60 Hz
- Terminal grid: 120 columns × 33 rows
- Renderer: Linux kernel console using
  `Lat15-TerminusBold32x16.psf.gz`
- Console blanking and power-down disabled
- `tessavision-display.service` runs `compose.sh` directly on tty1

`install_pi.sh` recreates the Pi services and display configuration. Runtime
credentials in `auth/` and generated files in `temp/` are intentionally ignored
by Git.

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

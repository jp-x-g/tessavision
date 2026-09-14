# Provisioning a new TessaVision Pi

This is the repeatable path for floors 1–4. It incorporates the failures found
while building the first-floor Pi on 2026-07-26. Budget about 30–45 minutes,
mostly for package downloads and two boot tests. Do not begin with an unknown
old card or depend on Wi-Fi for first access.

Expected timing:

- Flash and offline recovery setup: 10–15 minutes.
- First boot and direct USB SSH: about 2 minutes.
- Application/package installation: 10–20 minutes.
- Tailscale plus reboot acceptance: 10 minutes.

If direct USB SSH is not available within five minutes, stop and inspect the
card's boot log/configuration. If installation exceeds 20 minutes, inspect
`tessavision-install.service` and `/boot/firmware/tessavision-install.log`.
Do not start changing unrelated display behavior while an access prerequisite
is still unverified.

## Non-negotiable rules

1. Establish direct USB SSH before installing the display.
2. Identify the SD card by model, size, serial, and partition UUIDs before any
   destructive operation. Never assume it is `/dev/sdb`.
3. Use a fresh Tailscale identity for every Pi. Never copy `/var/lib/tailscale`
   or a full unsanitized image from another deployed Pi.
4. Preserve runtime credentials under `auth/`; never print or commit them.
5. Do not take the Pi to its floor until key SSH, passwordless sudo, the display,
   all timers, and a full reboot have been tested.

## Floor settings

Choose these before touching the card. Provisioning installs software and
reboots the target; publishing a Git commit is a separate operation and does
not authorize provisioning either working TV.

| Floor | Hostname | Normal Tailscale alias | Background |
| --- | --- | --- | --- |
| 1 | `tessavision-1f` | `tessavision-1f` | green |
| 2 | `tessavision-2f` | `tessavision-2f` | black unless requested |
| 3 | `tessavision` | `tessavision` | black |
| 4 | `tessavision-4f` | `tessavision-4f` | black unless requested |

All displays use yellow foreground text. Start from
[`tessavision.conf.example`](tessavision.conf.example), or the floor-specific
examples in `config/`. Set floor, hostname, colors, and the Wi-Fi device/profile
to match the hardware. These values configure one shared software build.

## 1. Prepare the hardware and source material

Have all of this on the bench:

- Pi Zero 2 W, dedicated power supply, HDMI monitor, and USB data cable.
- A spare microSD in a reader. Keep any working/original card untouched as the
  rollback.
- Optional external Wi-Fi dongle. Prefer one for unattended displays if the
  onboard radio is marginal.
- Local source checkout: `/home/x/tessavision`.
- Dedicated admin key:
  `/home/x/.ssh/id_ed25519_tessavision_pi`.

The known-good base image retained on Hatsune is:

```text
/home/x/tessavision-images/2026-06-18-raspios-trixie-arm64-lite.img.xz
SHA-256 acff736ca7945e3b305f07cda4abdb870910e12634991da69783611756e381b3
```

Verify it before use:

```sh
sha256sum \
  /home/x/tessavision-images/2026-06-18-raspios-trixie-arm64-lite.img.xz
```

Flash with Raspberry Pi Imager or a reviewed, target-guarded script. In Imager
customization, create user `tessavision`, install the public half of the
dedicated key, enable SSH, set hostname/time zone/country, and configure the
Mox Wi-Fi profile. Password login may remain disabled.

Before and after flashing, run:

```sh
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS,TRAN,HOTPLUG
```

Write down the exact new boot/root UUIDs. Stop if the target identity changes.

## 2. Install the recovery routes before first boot

Mount the flashed boot and root partitions. In the examples below, replace
`BOOT_MOUNT` and `ROOT_MOUNT` with the resolved mount paths.

On the boot partition:

1. Add this under `[all]` in `config.txt`:

   ```text
   dtoverlay=dwc2
   ```

2. Keep `cmdline.txt` on one line and append:

   ```text
   cfg80211.ieee80211_regdom=US modules-load=dwc2,g_ether g_ether.dev_addr=02:54:56:31:46:01 g_ether.host_addr=02:54:56:31:46:02
   ```

On the root partition, install the reviewed recovery assets:

```sh
sudo install -m 755 provision/tessavision-usb-recovery \
  ROOT_MOUNT/usr/local/sbin/tessavision-usb-recovery
sudo install -m 644 provision/tessavision-usb-recovery.service \
  ROOT_MOUNT/etc/systemd/system/tessavision-usb-recovery.service
sudo ln -s ../tessavision-usb-recovery.service \
  ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/tessavision-usb-recovery.service

sudo install -m 755 provision/tessavision-wifi-recovery \
  ROOT_MOUNT/usr/local/sbin/tessavision-wifi-recovery
sudo install -m 644 provision/tessavision-wifi-recovery.service \
  ROOT_MOUNT/etc/systemd/system/tessavision-wifi-recovery.service
sudo ln -s ../tessavision-wifi-recovery.service \
  ROOT_MOUNT/etc/systemd/system/multi-user.target.wants/tessavision-wifi-recovery.service
```

The literal `ROOT_MOUNT` is a placeholder, not a shell variable. Resolve and
validate the actual path before running these commands. If either symlink
already exists, inspect it instead of forcing replacement.

Install a known-good NetworkManager Mox profile from a deployed Pi or a secure
credential store. Do not commit it. Requirements:

- Owner/mode: `root:root`, `0600`.
- `connection.interface-name=wlan0` for the onboard radio.
- Use `wlan1` only when deliberately targeting an external dongle.
- `connection.autoconnect=true`.
- `connection.autoconnect-retries=0`.
- `802-11-wireless.powersave=2`.

An older 3F dongle profile was bound to `wlan1`; copying it unchanged to an
onboard-radio Pi caused an early provisioning failure. As verified on
2026-09-14, 3F currently uses `preconfigured` on `wlan0`. Inspect actual device
state before copying profiles; their names alone do not identify the radio.

When deliberately using an external adapter, match its actual interface and
MAC from `ip -brief link`. On 1F, the 2026-09-14 offline repair selected its
TP-Link adapter as `wlan1` for `Mox-dongle`, retaining the separate
`preconfigured` profile on `wlan0` as fallback. Match the watchdog to the chosen
profile/device using a service drop-in at
`/etc/systemd/system/tessavision-network-watchdog.service.d/device.conf`:

```ini
[Service]
Environment=TESSAVISION_WIFI_DEVICE=wlan1
Environment=TESSAVISION_WIFI_CONNECTION=Mox-dongle
```

The shared watchdog defaults to onboard `wlan0` if no override is installed.
The current installer generates this override from `TESSAVISION_WIFI_DEVICE`
and `TESSAVISION_WIFI_CONNECTION` in the per-Pi config. It does not create or
rebind secret NetworkManager profiles; prepare those to match as described
above. Validate connectivity and recovery during the live acceptance test.

Clear any persisted Wi-Fi software block in
`ROOT_MOUNT/var/lib/systemd/rfkill/*:wlan` by storing `0`, and retain the
`cfg80211.ieee80211_regdom=US` kernel option above.

Sync and safely eject the card.

## 3. Prove direct SSH before installing anything

Insert the card, connect HDMI, and attach the Pi's port labeled `USB` to
Hatsune. The data cable can power a Pi Zero during bench work.

The host already has a shared NetworkManager profile named
`tessavision-1f-usb`, with:

- Host/Pi addresses: `10.77.0.1/24` and `10.77.0.2/24`.
- Stable host/Pi MACs: `02:54:56:31:46:02` and `02:54:56:31:46:01`.
- Internet sharing enabled for package installation.

Only one uncustomized Pi should use this bench link at a time. Verify:

```sh
nmcli connection up tessavision-1f-usb
ping -c 3 10.77.0.2
ssh -F /home/x/.ssh/config -o BatchMode=yes \
  -i /home/x/.ssh/id_ed25519_tessavision_pi \
  tessavision@10.77.0.2 \
  'hostname; id; sudo -n true && echo sudo-ok'
```

Do not continue until this succeeds. A visible login prompt is not evidence of
failure; SSH and provisioning run in the background.

If the Pi has USB SSH but lacks USB Internet/DNS, configure its NetworkManager
profile once:

```sh
sudo nmcli connection add type ethernet ifname usb0 \
  con-name tessavision-usb-recovery \
  ipv4.method manual ipv4.addresses 10.77.0.2/24 \
  ipv4.gateway 10.77.0.1 ipv4.dns 10.77.0.1 \
  ipv4.route-metric 1000 ipv6.method disabled
sudo nmcli device set usb0 managed yes
sudo nmcli connection up tessavision-usb-recovery
```

Reconnect SSH if profile activation briefly resets the interface, then verify:

```sh
getent ahostsv4 deb.debian.org
curl -fsS --max-time 10 https://pkgs.tailscale.com/ >/dev/null
```

## 4. Build and stage the application payload

Build the application from the current local fork, not from an older deployed
tree. Use a working Pi only as the credentials source. Assemble both in a
private staging directory without printing secrets:

```sh
umask 077
staging_dir="$(mktemp -d /tmp/tessavision-payload.XXXXXX)"

tar --exclude=.git --exclude=temp --exclude=auth -cf - \
  -C /home/x/tessavision . \
  | tar -xf - -C "$staging_dir"

ssh -F /home/x/.ssh/config -o BatchMode=yes tessavision-1f \
  'sudo -n tar -czf - -C /home/tessavision/tessavision auth' \
  | tar -xzf - -C "$staging_dir"

tar -czf /tmp/tessavision.tar.gz -C "$staging_dir" .
tar -tzf /tmp/tessavision.tar.gz >/dev/null
chmod 600 /tmp/tessavision.tar.gz
```

The archive must include `auth/`; keep it out of Git and chat output.
Delete the private staging directory after the new Pi passes acceptance.

Create a per-Pi config from the example and stage everything over the proven
USB route:

```sh
cp tessavision.conf.example /tmp/tessavision.conf
# Set floor, hostname, colors, Wi-Fi device, and saved connection profile.
ssh-keygen -y -f /home/x/.ssh/id_ed25519_tessavision_pi \
  > /tmp/tessavision-authorized-key.pub

scp -F /home/x/.ssh/config \
  /tmp/tessavision.tar.gz \
  /tmp/tessavision.conf \
  /tmp/tessavision-authorized-key.pub \
  install_pi.sh \
  tessavision@10.77.0.2:/tmp/
```

Move the staged payload into `/boot/firmware` with `sudo install`; keep the
archive and key mode `0600`.

```sh
sudo install -m 600 -o root -g root \
  /tmp/tessavision.tar.gz /boot/firmware/tessavision.tar.gz
sudo install -m 600 -o root -g root \
  /tmp/tessavision-authorized-key.pub \
  /boot/firmware/tessavision-authorized-key.pub
sudo install -m 644 -o root -g root \
  /tmp/tessavision.conf /boot/firmware/tessavision.conf
sudo install -m 755 -o root -g root \
  /tmp/install_pi.sh /boot/firmware/tessavision-install.sh
```

Run installation as an unlimited transient systemd job so an SSH disconnect or
the normal 90-second service timeout cannot kill it:

```sh
sudo systemd-run \
  --unit=tessavision-install \
  --property=Type=oneshot \
  --property=TimeoutStartSec=infinity \
  /bin/bash /boot/firmware/tessavision-install.sh

sudo journalctl -fu tessavision-install.service
```

The installer validates the per-floor settings, installs packages/Tailscale,
creates the service account and sudo policy, deploys the app atomically,
installs display/refresh/watchdog units, and schedules a reboot.

## 5. Give the Pi a unique Tailscale identity

After reboot:

```sh
sudo tailscale status
sudo tailscale login --timeout=5m
```

Open the printed URL while the login command is still running. Confirm status
is `Running`, record the unique Tailscale DNS name/IP, and add a host block to
`/home/x/.ssh/config`.

Never copy another Pi's Tailscale state. If starting from any cloned image, run
`sudo tailscale logout`, remove the old node from the admin console, and
authenticate this Pi as a new node before accepting it.

## 6. Acceptance checklist

Run every check before carrying the Pi away:

```sh
# Direct USB
ssh -F /home/x/.ssh/config -o BatchMode=yes TARGET-USB-ALIAS \
  'hostname; sudo -n true; systemctl is-active ssh'

# Local Wi-Fi/mDNS
ssh -F /home/x/.ssh/config -o BatchMode=yes TARGET-LAN-ALIAS \
  'systemctl is-active tessavision-display.service'

# Tailscale
tailscale ping --c 3 TARGET-TAILSCALE-IP
ssh -F /home/x/.ssh/config -o BatchMode=yes TARGET-ALIAS \
  'sudo -n true; systemctl is-active tessavision-display.service'
```

On the Pi, confirm:

```sh
cat /home/tessavision/tessavision/current_floor
systemctl is-enabled \
  tessavision-display.service \
  tessavision-events.timer \
  tessavision-ticker.timer \
  tessavision-network-watchdog.timer
systemctl is-active \
  tessavision-display.service \
  tessavision-events.timer \
  tessavision-ticker.timer \
  tessavision-network-watchdog.timer
```

Visually verify the correct floor and colors. Green requires
`setterm ... --store`; without `--store`, renderer reset codes return the
background to black.

Then perform one real reboot and repeat all three SSH checks. To prove Tailscale
does not merely use the bench USB link, temporarily deactivate only the host's
USB NetworkManager profile, test Tailscale SSH, and restore it immediately.

Finally:

1. Attach dedicated power before removing the USB data cable.
2. Place the Pi on its floor.
3. Test Tailscale SSH again from Hatsune.
4. Record hostname, aliases, Tailscale IP, floor/color, and recovery notes in
   `AGENTS.md`.

## Lessons encoded in this procedure

- Blank default `network-config` does not provision Wi-Fi.
- Raspberry Pi OS may persist a Wi-Fi soft block until country/rfkill setup is
  correct.
- A 3F dongle profile bound to `wlan1` cannot drive 1F onboard `wlan0`.
- NetworkManager may classify gadget `usb0` as unmanaged; the direct recovery
  service therefore configures its address without depending on NetworkManager.
- Provisioning must have an unlimited start timeout and durable logs.
- Tailscale authorization must remain active while its one-time URL is opened.
- Terminal colors require a stored default, not only a one-time color escape.
- Kernel-console tab characters move the cursor without erasing skipped cells.
  Convert header tabs to spaces and pad every header row to the full 120
  columns, or old ASCII characters can bleed through at gaps and the right
  edge.
- API output must be validated and atomically published so an outage never
  truncates the visible cache.
- A minute watchdog may reconnect a disconnected radio, but it must be a no-op
  while an association is already in progress.

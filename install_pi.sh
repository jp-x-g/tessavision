#!/usr/bin/env bash
set -Eeuo pipefail

BOOT_DIR=/boot/firmware
ARCHIVE="$BOOT_DIR/tessavision.tar.gz"
CONFIG="$BOOT_DIR/tessavision.conf"
AUTHORIZED_KEY="$BOOT_DIR/tessavision-authorized-key.pub"
APP_USER=tessavision
APP_HOME=/home/tessavision
APP_DIR="$APP_HOME/tessavision"
STAGING_DIR="$APP_HOME/tessavision.new"
LOG="$BOOT_DIR/tessavision-install.log"

TESSAVISION_FLOOR=3
TESSAVISION_HOSTNAME=tessavision
TESSAVISION_FOREGROUND=yellow
TESSAVISION_BACKGROUND=black
TESSAVISION_WIFI_DEVICE=wlan0
TESSAVISION_WIFI_CONNECTION=Mox-dongle

exec > >(tee -a "$LOG") 2>&1
trap 'status=$?; echo "Install failed with status $status at $(date -Is)"; exit "$status"' ERR

echo "TessaVision install started: $(date -Is)"

if [[ -f "$CONFIG" ]]; then
    # This file lives on the physical boot partition and is intentionally
    # administrator-controlled shell syntax.
    # shellcheck source=/dev/null
    source "$CONFIG"
fi

case "$TESSAVISION_FLOOR" in
    1|2|3|4) ;;
    *) echo "Invalid TESSAVISION_FLOOR: $TESSAVISION_FLOOR"; exit 1 ;;
esac

case "$TESSAVISION_FOREGROUND" in
    black|blue|cyan|green|grey|magenta|red|white|yellow) ;;
    *) echo "Invalid TESSAVISION_FOREGROUND: $TESSAVISION_FOREGROUND"; exit 1 ;;
esac

case "$TESSAVISION_BACKGROUND" in
    black|blue|cyan|green|grey|magenta|red|white|yellow) ;;
    *) echo "Invalid TESSAVISION_BACKGROUND: $TESSAVISION_BACKGROUND"; exit 1 ;;
esac

if [[ ! "$TESSAVISION_HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]]; then
    echo "Invalid TESSAVISION_HOSTNAME: $TESSAVISION_HOSTNAME"
    exit 1
fi

if [[ ! "$TESSAVISION_WIFI_DEVICE" =~ ^[a-zA-Z0-9_.-]{1,15}$ ]]; then
    echo "Invalid TESSAVISION_WIFI_DEVICE: $TESSAVISION_WIFI_DEVICE"
    exit 1
fi

# Values enter a quoted systemd Environment= directive. Exclude quoting,
# newlines, and percent-specifier expansion from profile names.
if [[ ! "$TESSAVISION_WIFI_CONNECTION" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.\ -]*$ ]]; then
    echo "Invalid TESSAVISION_WIFI_CONNECTION: $TESSAVISION_WIFI_CONNECTION"
    exit 1
fi

systemctl disable --now tessavision-management-ip.service 2>/dev/null || true
rm -f /etc/systemd/system/tessavision-management-ip.service
/usr/sbin/ip address del 10.103.254.253/16 dev wlan0 2>/dev/null || true
systemctl daemon-reload

if ! id -u "$APP_USER" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash "$APP_USER"
fi

if [[ ! -s "$ARCHIVE" ]]; then
    echo "Application archive is missing: $ARCHIVE"
    exit 1
fi

retry() {
    local attempt
    for attempt in {1..20}; do
        if "$@"; then
            return 0
        fi
        echo "Attempt $attempt failed; retrying in 15 seconds"
        sleep 15
    done
    return 1
}

export DEBIAN_FRONTEND=noninteractive
retry apt-get update
retry apt-get install -y --no-install-recommends curl figlet jq kbd console-setup

timedatectl set-timezone America/Los_Angeles
hostnamectl set-hostname "$TESSAVISION_HOSTNAME"

install -d -m 700 -o "$APP_USER" -g "$APP_USER" "$APP_HOME/.ssh"
if [[ -s "$AUTHORIZED_KEY" ]]; then
    if ! grep -Eq '^ssh-(ed25519|rsa) ' "$AUTHORIZED_KEY"; then
        echo "Invalid SSH public key: $AUTHORIZED_KEY"
        exit 1
    fi
    install -m 600 -o "$APP_USER" -g "$APP_USER" \
        "$AUTHORIZED_KEY" "$APP_HOME/.ssh/authorized_keys"
fi

printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$APP_USER" \
    > /etc/sudoers.d/90-tessavision
chmod 440 /etc/sudoers.d/90-tessavision
visudo -cf /etc/sudoers.d/90-tessavision

systemctl disable --now tessavision-display.service 2>/dev/null || true

rm -rf "$STAGING_DIR"
install -d -m 755 -o "$APP_USER" -g "$APP_USER" "$STAGING_DIR"
tar -xzf "$ARCHIVE" -C "$STAGING_DIR"
printf '%s\n' "$TESSAVISION_FLOOR" > "$STAGING_DIR/current_floor"
chown -R "$APP_USER:$APP_USER" "$STAGING_DIR"
find "$STAGING_DIR" -type d -exec chmod 755 {} +
find "$STAGING_DIR" -type f -name '*.sh' -exec chmod 755 {} +

if [[ -d "$STAGING_DIR/auth" ]]; then
    chmod 700 "$STAGING_DIR/auth"
    find "$STAGING_DIR/auth" -type f -exec chmod 600 {} +
fi

install -d -m 755 -o "$APP_USER" -g "$APP_USER" "$STAGING_DIR/temp"
for file in SPY.txt QQQ.txt DIA.txt BTC.txt BZUSD.txt; do
    install -m 644 -o "$APP_USER" -g "$APP_USER" /dev/null "$STAGING_DIR/temp/$file"
done

rm -rf "$APP_DIR.previous"
if [[ -d "$APP_DIR" ]]; then
    mv "$APP_DIR" "$APP_DIR.previous"
fi
mv "$STAGING_DIR" "$APP_DIR"
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

cat > /etc/systemd/system/tessavision-display.service <<'EOF'
[Unit]
Description=TessaVision display
Wants=network-online.target
After=network-online.target
Conflicts=getty@tty1.service
Before=getty@tty1.service

[Service]
Type=simple
User=tessavision
Group=tessavision
WorkingDirectory=/home/tessavision/tessavision
Environment=TERM=linux
Environment=LANG=C.UTF-8
Environment=LC_ALL=C.UTF-8
ExecStartPre=+/usr/bin/setfont -C /dev/tty1 /usr/share/consolefonts/Lat15-TerminusBold32x16.psf.gz
ExecStart=/bin/bash ./compose.sh
Restart=always
RestartSec=2
StandardInput=tty
StandardOutput=tty
StandardError=journal
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes

[Install]
WantedBy=multi-user.target
EOF

install -d -m 755 /etc/systemd/system/tessavision-display.service.d
cat > /etc/systemd/system/tessavision-display.service.d/no-blank.conf <<EOF
[Service]
ExecStartPre=+/usr/bin/setterm --term linux --foreground $TESSAVISION_FOREGROUND --background $TESSAVISION_BACKGROUND --bold on --store --blank 0 --powerdown 0
EOF

cat > /etc/systemd/system/tessavision-events.service <<'EOF'
[Unit]
Description=Refresh TessaVision events
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=tessavision
Group=tessavision
WorkingDirectory=/home/tessavision/tessavision
ExecStart=/bin/bash ./events.sh
EOF

cat > /etc/systemd/system/tessavision-events.timer <<'EOF'
[Unit]
Description=Refresh TessaVision events every minute

[Timer]
OnBootSec=20s
OnUnitActiveSec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/tessavision-ticker.service <<'EOF'
[Unit]
Description=Refresh TessaVision market ticker
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=oneshot
User=tessavision
Group=tessavision
WorkingDirectory=/home/tessavision/tessavision
ExecStart=/bin/bash ./ticker.sh
Restart=on-failure
RestartSec=60
EOF

cat > /etc/systemd/system/tessavision-ticker.timer <<'EOF'
[Unit]
Description=Refresh TessaVision market ticker hourly

[Timer]
OnBootSec=30s
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/tessavision-network-watchdog.service <<'EOF'
[Unit]
Description=Reconnect TessaVision Wi-Fi when disconnected
After=NetworkManager.service
Wants=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/bin/bash /home/tessavision/tessavision/network_watchdog.sh
EOF

cat > /etc/systemd/system/tessavision-network-watchdog.timer <<'EOF'
[Unit]
Description=Check TessaVision Wi-Fi every minute

[Timer]
OnBootSec=1min
OnUnitInactiveSec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOF

install -d -m 755 /etc/systemd/system/tessavision-network-watchdog.service.d
cat > /etc/systemd/system/tessavision-network-watchdog.service.d/device.conf <<EOF
[Service]
Environment="TESSAVISION_WIFI_DEVICE=$TESSAVISION_WIFI_DEVICE"
Environment="TESSAVISION_WIFI_CONNECTION=$TESSAVISION_WIFI_CONNECTION"
EOF

install -d -m 755 /etc/systemd/journald.conf.d
install -m 644 "$APP_DIR/provision/tessavision-journald.conf" \
    /etc/systemd/journald.conf.d/tessavision.conf

systemctl daemon-reload
systemctl mask getty@tty1.service
systemctl enable tessavision-display.service
systemctl enable tessavision-events.timer
systemctl enable tessavision-ticker.timer
systemctl enable tessavision-network-watchdog.timer

if ! command -v tailscale >/dev/null 2>&1; then
    install -d -m 755 /usr/share/keyrings
    retry curl -fsSL -o /usr/share/keyrings/tailscale-archive-keyring.gpg \
        https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg
    retry curl -fsSL -o /etc/apt/sources.list.d/tailscale.list \
        https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list
    retry apt-get update
    retry apt-get install -y --no-install-recommends tailscale
fi
systemctl enable --now tailscaled

CMDLINE="$BOOT_DIR/cmdline.txt"
sed -i 's# systemd.run="/bin/bash /boot/firmware/tessavision-install.sh"##g; s/ systemd.run_success_action=reboot//g; s/ systemd.run_failure_action=none//g' "$CMDLINE"
if ! grep -qw consoleblank=0 "$CMDLINE"; then
    sed -i 's/$/ consoleblank=0/' "$CMDLINE"
fi
for option in quiet loglevel=3 systemd.show_status=false vt.global_cursor_default=0; do
    if ! grep -Fqw "$option" "$CMDLINE"; then
        sed -i "s/$/ $option/" "$CMDLINE"
    fi
done
if grep -q 'video=HDMI-A-1:' "$CMDLINE"; then
    sed -i 's/video=HDMI-A-1:[^ ]*/video=HDMI-A-1:1920x1080@60D/' "$CMDLINE"
else
    sed -i 's/$/ video=HDMI-A-1:1920x1080@60D/' "$CMDLINE"
fi

printf '#cloud-config\n' > "$BOOT_DIR/user-data"
rm -f "$ARCHIVE" "$AUTHORIZED_KEY" "$BOOT_DIR/userconf.txt" \
    "$BOOT_DIR/tessavision-recover.sh"
echo "TessaVision install completed: $(date -Is)"
rm -f "$BOOT_DIR/tessavision-install.sh"
sync
shutdown -r +1 "TessaVision installation completed"

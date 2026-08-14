#!/usr/bin/env bash
set -Eeuo pipefail

WIFI_DEVICE=wlan0
WIFI_CONNECTION=Mox-dongle

state="$(nmcli -g GENERAL.STATE device show "$WIFI_DEVICE" 2>/dev/null || true)"
if [[ "$state" == 100* ]]; then
  exit 0
fi

echo "$WIFI_DEVICE is not connected (state: ${state:-unknown}); reconnecting"
rfkill unblock wifi
nmcli radio wifi on
nmcli device set "$WIFI_DEVICE" managed yes
nmcli --wait 45 connection up "$WIFI_CONNECTION" ifname "$WIFI_DEVICE"

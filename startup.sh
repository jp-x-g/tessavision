#!/usr/bin/env bash
mkdir -p auth blocks temp
sudo setterm --foreground yellow --bold on --background green --store
sudo setfont Lat15-TerminusBold32x16.psf.gz
clear

echo "Updating apt-get."
sudo apt-get -y update

echo "Setting timezone."
sudo timedatectl set-timezone America/Los_Angeles

echo "Installing chrony."
sudo apt-get -y install chrony

echo "Disabling systemd-timesyncd, enabling chrony."
sudo systemctl disable --now systemd-timesyncd || true
sudo systemctl enable --now chrony

echo "Forcing time step."
sudo chronyc -a makestep || true

echo "Time status:"
timedatectl
chronyc tracking || true
chronyc sources -v || true

echo "Installing dependencies."
sudo apt-get -y install figlet
sudo apt-get -y install fbi
sudo apt-get -y install jq

chmod +x events.sh ticker.sh compose.sh

rm ../tessavision/temp/*
touch temp/SPY.txt temp/BTC.txt temp/BZUSD.txt

bash events.sh
#bash ticker.sh
bash compose.sh
#!/usr/bin/env bash

sudo setterm --foreground yellow --bold on --background green --store
sudo setfont Lat15-TerminusBold32x16.psf.gz
clear
sudo timedatectl set-timezone America/Los_Angeles
echo "Updating apt-get."
sudo apt-get -y update
echo "Installing figlet."
sudo apt-get -y install figlet
sudo apt-get -y install fbi
bash compose.sh
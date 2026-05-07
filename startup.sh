#!/usr/bin/env bash

sudo setterm --foreground yellow --bold on --background green --store
sudo setfont Lat15-TerminusBold32x16.psf.gz
clear
echo "Installing figlet."
sudo apt-get -y update
sudo apt-get -y install figlet
sudo apt-get -y install fbi
#!/usr/bin/env bash

mkdir auth
mkdir blocks
mkdir temp

# date '+%A,%n%Y %b %d' | figlet -r -w 57 -f mini > blocks/0date.txt
# printf "Wednesday,\n2026 Www 30" | figlet -r -w 57 -f mini > blocks/0date.txt
# logo3.txt is 63 wide as of now. display is 120
# paste blocks/logo3.txt blocks/3x11.txt blocks/3x11.txt blocks/0date.txt > blocks/header.txt
date '+%A,%n%Y %b %d' | figlet -r -w 56 -f smslant > temp/0date.txt

date '+%H:%M %Z' > temp/0time.txt
printf "  %s | SPY $%s | BTC $%s | BRENT $%s/BBL" "$(cat temp/0time.txt)" "$(cat temp/SPY.txt)" "$(cat temp/BTC.txt)" "$(cat temp/BZUSD.txt)" > temp/ticker.txt


cat temp/0date.txt temp/ticker.txt > temp/0right.txt
#paste blocks/logo3.txt blocks/1x11.txt blocks/barx11.txt blocks/0date.txt > blocks/header.txt
paste blocks/logo3.txt temp/0right.txt > temp/header.txt
# 69 plus date = 51 for it
clear
cat temp/header.txt
printf '%*s\n' 120 '' | tr ' ' '_'

#sleep 15




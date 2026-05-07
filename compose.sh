#!/usr/bin/env bash

# date '+%A,%n%Y %b %d' | figlet -r -w 57 -f mini > blocks/0date.txt
# printf "Wednesday,\n2026 Www 30" | figlet -r -w 57 -f mini > blocks/0date.txt
# logo3.txt is 63 wide as of now. display is 120
# paste blocks/logo3.txt blocks/3x11.txt blocks/3x11.txt blocks/0date.txt > blocks/header.txt
date '+%A,%n%Y %b %d' | figlet -r -w 57 -f big > blocks/0date.txt
paste blocks/logo3.txt blocks/0date.txt > blocks/header.txt
# 69 plus date = 51 for it
clear
cat blocks/header.txt
#sleep 15




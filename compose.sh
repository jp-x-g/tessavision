#!/usr/bin/env bash

date '+%A,%n%Y %b %d' | figlet -f mini > blocks/0date.txt
printf "Wednesday,\n2026 Www 30" | figlet -f mini > blocks/0date.txt
paste blocks/logo3.txt blocks/3x11.txt blocks/3x11.txt blocks/0date.txt > blocks/header.txt
clear
cat blocks/header.txt
sleep 15
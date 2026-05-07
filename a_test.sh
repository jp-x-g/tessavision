#!/usr/bin/env bash

date '+%A,%n%Y %b %d' | figlet -r -w 57 -f mini > blocks/0date.txt
cat blocks/0date.txt

echo "big"
date '+%A%n%Y %b %d' | figlet -r -w 57 -f big
echo "slant"
date '+%A,%n%Y %b %d' | figlet -r -w 57 -f slant
echo "small"
date '+%A,%n%Y %b %d' | figlet -r -w 57 -f small
echo "smshadow"
date '+%A,%n%Y %b %d' | figlet -r -w 57 -f smshadow
echo "smslant"
date '+%A,%n%Y %b %d' | figlet -r -w 57 -f smslant
echo "standard"
date '+%A%n%Y %b %d' | figlet -r -w 57 -f standard




# 69 plus date = 51 for it
#clear
cat blocks/header.txt
sleep 15




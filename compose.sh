#!/usr/bin/env bash

date '+%A,%n%Y %b %d' | figlet -f mini > blocks/0date.txt
paste blocks/logo3.txt blocks/0date.txt > blocks/header.txt
cat blocks/header.txt
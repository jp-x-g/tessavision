#!/usr/bin/env bash

date '+%A,%n%Y %b %d' > blocks/rawdate.txt
figlet -f mini rawdate.txt > blocks/0date.txt
paste blocks/logo3.txt blocks/0date.txt > blocks/header.txt
cat header.txt
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

W=58
H=9

fit_block() {
  # stdin -> exactly H lines, each exactly W chars
  # folds long lines, truncates after H, pads width and height
  awk -v W="$W" -v H="$H" '
    {
      line = $0
      while (length(line) > W) {
        print substr(line, 1, W)
        n++
        if (n >= H) exit
        line = substr(line, W + 1)
      }
      print substr(line, 1, W)
      n++
      if (n >= H) exit
    }
    END {
      while (n < H) {
        print "             │                                            "
        n++
      }
    }
  ' | awk -v W="$W" '{ printf "%-*.*s\n", W, W, $0 }'
}
#       print "1234567890123456789012345678901234567890123456789012345678"

frame_block() {
  local title="$1"

  # title line: 27 ═, space title space, 27 ═ = 58 inner chars for "1F"
  # ╔══════════════╤════════════ 1F ═══════════════════════════╗
  #printf '╔%s %s %s╗\n' \
  #  "$(printf '═%.0s' {1..27})" \
  #  "$title" \
  #  "$(printf '═%.0s' {1..27})"

  printf '╔═════════════╤═════════════ %s ═══════════════════════════╗\n' \
    "$title"

  fit_block | sed 's/^/║/; s/$/║/'

  #printf '╚%s╝\n' "$(printf '═%.0s' $(seq 1 "$W"))"
  printf '╚═════════════╧════════════════════════════════════════════╝\n'
}

frame_block 1F < temp/1f.txt > temp/1f.box
frame_block 2F < temp/2f.txt > temp/2f.box
frame_block 3F < temp/3f.txt > temp/3f.box
frame_block 4F < temp/4f.txt > temp/4f.box

cat temp/header.txt > temp/display.txt
echo "" >> temp/display.txt

paste -d '' temp/1f.box temp/2f.box >> temp/display.txt
paste -d '' temp/3f.box temp/4f.box >> temp/display.txt










clear
cat temp/display.txt
# printf '%*s\n' 120 '' | tr ' ' '_'






#sleep 15




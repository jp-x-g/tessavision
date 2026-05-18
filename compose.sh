#!/usr/bin/env bash

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

mkdir -p auth blocks temp

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

date '+%A,%n%Y %b %d' | figlet -r -w 56 -f smslant > temp/0date.txt

date '+%H:%M %Z' > temp/0time.txt

printf "  %s | SPY $%s | BTC $%s | BRENT $%s/BBL" \
  "$(cat temp/0time.txt)" \
  "$(cat temp/SPY.txt)" \
  "$(cat temp/BTC.txt)" \
  "$(cat temp/BZUSD.txt)" \
  > temp/ticker.txt

cat temp/0date.txt temp/ticker.txt > temp/0right.txt

paste blocks/logo3.txt temp/0right.txt > temp/header.txt

# ------------------------------------------------------------
# Floor boxes
# ------------------------------------------------------------

H=9

print_event_row() {
  local line="$1"
  local left right

  # temp/*f.txt should use ASCII pipe:
  # 19:00 - 21:30| 90/30 ML Reading Club
  #
  # NOT Unicode │ in the file.
  left="${line%%|*}"
  right="${line#*|}"

  # If there was no pipe, treat whole thing as right-side text.
  if [ "$left" = "$right" ]; then
    left=""
    right="$line"
  fi

  # 13 left + 1 divider + 44 right = 58 inner cells
  printf '║%-13.13s│%-44.44s║\n' "$left" "$right"
}

print_blank_row() {
  printf '║%-13.13s│%-44.44s║\n' "" ""
}

make_floor_box() {
  local title="$1"
  local infile="$2"
  local outfile="$3"
  local n=0
  local line

  {
    case "$title" in
      1F) printf '╔═════════════╤═════════════ 1F ═══════════════════════════╗\n' ;;
      2F) printf '╔═════════════╤═════════════ 2F ═══════════════════════════╗\n' ;;
      3F) printf '╔═════════════╤═════════════ 3F ═══════════════════════════╗\n' ;;
      4F) printf '╔═════════════╤═════════════ 4F ═══════════════════════════╗\n' ;;
       *) printf '╔═════════════╤═════════════ %s ═══════════════════════════╗\n' "$title" ;;
    esac

    if [ -f "$infile" ]; then
      while IFS= read -r line && [ "$n" -lt "$H" ]; do
        # Skip empty lines so empty event files don't create one weird blank full-width row.
        [ -z "$line" ] && continue

        print_event_row "$line"
        n=$((n + 1))
      done < "$infile"
    fi

    while [ "$n" -lt "$H" ]; do
      print_blank_row
      n=$((n + 1))
    done

    printf '╚═════════════╧════════════════════════════════════════════╝\n'
  } > "$outfile"
}

make_floor_box 1F temp/1f.txt temp/1f.box
make_floor_box 2F temp/2f.txt temp/2f.box
make_floor_box 3F temp/3f.txt temp/3f.box
make_floor_box 4F temp/4f.txt temp/4f.box

# ------------------------------------------------------------
# Compose final display
# ------------------------------------------------------------

cat temp/header.txt > temp/display.txt
echo "" >> temp/display.txt

paste -d '' temp/1f.box temp/2f.box >> temp/display.txt
paste -d '' temp/3f.box temp/4f.box >> temp/display.txt

clear
cat temp/display.txt

# printf '%*s\n' 120 '' | tr ' ' '_'
# sleep 15
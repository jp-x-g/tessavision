#!/usr/bin/env bash

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

tput civis
trap 'tput cnorm; exit' INT TERM EXIT
# Hides terminal cursor until we unhide it.

mkdir -p auth blocks temp

# ------------------------------------------------------------
# ANSI colors
# ------------------------------------------------------------

RED=$'\033[31m'
RESET=$'\033[0m'

# Read current floor from either temp/current_floor.txt or ./current_floor.txt
CURRENT_FLOOR=""

if [ -f temp/current_floor.txt ]; then
  CURRENT_FLOOR="$(tr -d '[:space:]' < temp/current_floor.txt)"
elif [ -f current_floor.txt ]; then
  CURRENT_FLOOR="$(tr -d '[:space:]' < current_floor.txt)"
fi

# Normalize e.g. "4", "4f", "4F" -> "4F"
case "$CURRENT_FLOOR" in
  1|1f|1F) CURRENT_FLOOR="1F" ;;
  2|2f|2F) CURRENT_FLOOR="2F" ;;
  3|3f|3F) CURRENT_FLOOR="3F" ;;
  4|4f|4F) CURRENT_FLOOR="4F" ;;
esac

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
LEFT_W=13
RIGHT_W=44

colorize_if_current() {
  local title="$1"
  local text="$2"

  if [ "$title" = "$CURRENT_FLOOR" ]; then
    printf '%s%s%s' "$RED" "$text" "$RESET"
  else
    printf '%s' "$text"
  fi
}

print_top_border() {
  local title="$1"
  local s

  case "$title" in
    1F) s='╔═════════════╤═════════════ 1F ═══════════════════════════╗' ;;
    2F) s='╔═════════════╤═════════════ 2F ═══════════════════════════╗' ;;
    3F) s='╔═════════════╤═════════════ 3F ═══════════════════════════╗' ;;
    4F) s='╔═════════════╤═════════════ 4F ═══════════════════════════╗' ;;
     *) s="╔═════════════╤═════════════ $title ═══════════════════════════╗" ;;
  esac

  colorize_if_current "$title" "$s"
  printf '\n'
}

print_bottom_border() {
  local title="$1"
  local s='╚═════════════╧════════════════════════════════════════════╝'

  colorize_if_current "$title" "$s"
  printf '\n'
}

print_event_row_parts() {
  local title="$1"
  local left="$2"
  local right="$3"
  local lborder rborder divider

  if [ "$title" = "$CURRENT_FLOOR" ]; then
    lborder="${RED}║${RESET}"
    rborder="${RED}║${RESET}"
    divider="${RED}│${RESET}"
  else
    lborder="║"
    rborder="║"
    divider="│"
  fi

  printf '%s%-13.13s%s%-44.44s%s\n' \
    "$lborder" "$left" "$divider" "$right" "$rborder"
}

print_blank_row() {
  local title="$1"
  print_event_row_parts "$title" "" ""
}

print_wrapped_event() {
  local title="$1"
  local line="$2"
  local left right chunk

  # Expected input:
  # 19:00 - 21:30| 90/30 ML Reading Club
  #
  # Plain ASCII pipe in file, pretty Unicode divider only rendered here.
  left="${line%%|*}"
  right="${line#*|}"

  # If no pipe exists, shove whole line into right column.
  if [ "$left" = "$right" ]; then
    left=""
    right="$line"
  fi

  # First row: time/date left column + first title chunk.
  chunk="${right:0:$RIGHT_W}"
  right="${right:$RIGHT_W}"

  print_event_row_parts "$title" "$left" "$chunk"
  ROWS_PRINTED=$((ROWS_PRINTED + 1))

  # Continuation rows: blank left column + next title chunks.
  while [ -n "$right" ] && [ "$ROWS_PRINTED" -lt "$H" ]; do
    chunk="${right:0:$RIGHT_W}"
    right="${right:$RIGHT_W}"

    print_event_row_parts "$title" "" "$chunk"
    ROWS_PRINTED=$((ROWS_PRINTED + 1))
  done
}

make_floor_box() {
  local title="$1"
  local infile="$2"
  local outfile="$3"
  local line

  ROWS_PRINTED=0

  {
    print_top_border "$title"

    if [ -f "$infile" ]; then
      while IFS= read -r line && [ "$ROWS_PRINTED" -lt "$H" ]; do
        # Skip empty lines so empty event files don't create one weird blank row.
        [ -z "$line" ] && continue

        print_wrapped_event "$title" "$line"
      done < "$infile"
    fi

    while [ "$ROWS_PRINTED" -lt "$H" ]; do
      print_blank_row "$title"
      ROWS_PRINTED=$((ROWS_PRINTED + 1))
    done

    print_bottom_border "$title"
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
#echo "" >> temp/display.txt

paste -d '' temp/1f.box temp/2f.box >> temp/display.txt
paste -d '' temp/3f.box temp/4f.box >> temp/display.txt

clear
cat temp/display.txt

# printf '%*s\n' 120 '' | tr ' ' '_'
sleep 15

tput cnorm
trap - INT TERM EXIT
# Restore cursor
#!/usr/bin/env bash

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

tput civis
trap 'tput cnorm; exit' INT TERM EXIT
# Hides terminal cursor until we unhide it.

clear

while true; do
	mkdir -p auth blocks temp

	# ------------------------------------------------------------
	# ANSI colors
	# ------------------------------------------------------------

	RED=$'\033[31m'
	RESET=$'\033[0m'

	# Read current floor from either temp/current_floor.txt or ./current_floor.txt
	CURRENT_FLOOR=""

	if [ -f temp/current_floor ]; then
	  CURRENT_FLOOR="$(tr -d '[:space:]' < temp/current_floor)"
	elif [ -f current_floor ]; then
	  CURRENT_FLOOR="$(tr -d '[:space:]' < current_floor)"
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

	# Keep redraws locked to clock-second boundaries instead of adding a
	# full second after however long this iteration takes.
	NEXT_TICK_MS=$(( ( $(date +%s) + 1 ) * 1000 + 50 ))

	date '+%A,%n%Y %b %d' | figlet -r -w 56 -f smslant > temp/0date.txt

	date '+%H:%M:%S %Z' > temp/0time.txt

	read_fresh_quote() {
	  local path="$1"
	  local max_age=7200
	  local now modified value

	  [ -s "$path" ] || return 1
	  value="$(tr -d '[:space:]' < "$path")"
	  [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1

	  now="$(date +%s)"
	  modified="$(stat -c %Y "$path")"
	  [ $((now - modified)) -le "$max_age" ] || return 1
	  printf '%s' "$value"
	}

	SPY_VALUE="$(read_fresh_quote temp/SPY.txt 2>/dev/null || true)"
	BTC_VALUE="$(read_fresh_quote temp/BTC.txt 2>/dev/null || true)"
	BRENT_VALUE="$(read_fresh_quote temp/BZUSD.txt 2>/dev/null || true)"

	if [ -n "$SPY_VALUE" ] && [ -n "$BTC_VALUE" ] && [ -n "$BRENT_VALUE" ]; then
	  printf "  %s | SPY $%s | BTC $%s | BRENT $%s/BBL" \
	    "$(cat temp/0time.txt)" \
	    "$SPY_VALUE" \
	    "$BTC_VALUE" \
	    "$BRENT_VALUE" \
	    > temp/ticker.txt
	else
	  # Never advertise a conspicuous partial ticker. Keep the clock clean
	  # until all displayed quotes have fresh, validated cache entries.
	  printf "  %s" "$(cat temp/0time.txt)" > temp/ticker.txt
	fi

	cat temp/0date.txt temp/ticker.txt > temp/0right.txt 2>/dev/null

	# A literal tab advances the tty cursor without overwriting skipped cells,
	# and short lines leave old right-edge characters behind. Convert the
	# separator to spaces and publish a complete 120-column header every frame.
	paste blocks/logo3.txt temp/0right.txt \
	  | expand -t 8 \
	  | awk '{printf "%-120s\n", substr($0, 1, 120)}' \
	  > temp/header.txt

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

	wrap_event_title() {
	  local text="$1"
	  local word line=""
	  local -a words

	  # Reading into an array removes leading/trailing whitespace and collapses
	  # repeated whitespace between words. Event names are plain display text.
	  read -r -a words <<< "$text"
	  WRAPPED_LINES=()

	  for word in "${words[@]}"; do
	    # A pathological unbroken token must still fit the pane. Flush any
	    # pending normal line, then hard-split only the oversized token.
	    if [ "${#word}" -gt "$RIGHT_W" ]; then
	      if [ -n "$line" ]; then
	        WRAPPED_LINES+=("$line")
	        line=""
	      fi
	      while [ "${#word}" -gt "$RIGHT_W" ]; do
	        WRAPPED_LINES+=("${word:0:$RIGHT_W}")
	        word="${word:$RIGHT_W}"
	      done
	      line="$word"
	    elif [ -z "$line" ]; then
	      line="$word"
	    elif [ $(( ${#line} + 1 + ${#word} )) -le "$RIGHT_W" ]; then
	      line+=" $word"
	    else
	      WRAPPED_LINES+=("$line")
	      line="$word"
	    fi
	  done

	  if [ -n "$line" ]; then
	    WRAPPED_LINES+=("$line")
	  fi
	  if [ "${#WRAPPED_LINES[@]}" -eq 0 ]; then
	    WRAPPED_LINES+=("")
	  fi
	}

	print_wrapped_event() {
	  local title="$1"
	  local line="$2"
	  local left right chunk row_left index

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

	  wrap_event_title "$right"
	  for index in "${!WRAPPED_LINES[@]}"; do
	    [ "$ROWS_PRINTED" -lt "$H" ] || break
	    chunk="${WRAPPED_LINES[$index]}"
	    if [ "$index" -eq 0 ]; then
	      row_left="$left"
	    else
	      row_left=""
	    fi

	    print_event_row_parts "$title" "$row_left" "$chunk"
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

	#clear
	tput cup 0 0
	printf '%s' "$(<temp/display.txt)"

	# printf '%*s\n' 120 '' | tr ' ' '_'
	NOW_MS="$(date +%s%3N)"
	SLEEP_MS=$((NEXT_TICK_MS - NOW_MS))
	if [ "$SLEEP_MS" -gt 0 ]; then
	  printf -v SLEEP_SECONDS '%d.%03d' $((SLEEP_MS / 1000)) $((SLEEP_MS % 1000))
	  sleep "$SLEEP_SECONDS"
	fi
done

	tput cnorm
	trap - INT TERM EXIT
	# Restore cursor

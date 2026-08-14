#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

CURL_OPTIONS=(
  -fsS
  --connect-timeout 10
  --max-time 30
  --retry 2
  --retry-delay 2
  --retry-all-errors
)

mkdir -p temp

if [[ ! -s auth/airtable.com.txt ]]; then
  echo "Missing Airtable API key" >&2
  exit 1
fi
APIKEY="$(tr -d '\n' < auth/airtable.com.txt)"

events_staging="$(mktemp temp/.events.XXXXXX)"
floor_staging=()
cleanup() {
  rm -f "$events_staging" "${floor_staging[@]}"
}
trap cleanup EXIT

curl "${CURL_OPTIONS[@]}" \
  "https://api.airtable.com/v0/appkHZ2UvU6SouT5y/Events" \
  -H "Authorization: Bearer $APIKEY" \
  -G \
  --data-urlencode "view=Upcoming Events" \
  --data-urlencode "filterByFormula=IS_AFTER({Start Date}, TODAY())" \
  --data-urlencode "sort[0][field]=Start Date" \
  --data-urlencode "sort[0][direction]=asc" \
  > "$events_staging"

jq -e '.records | arrays' "$events_staging" >/dev/null

TODAY="$(date +%F)"

for floor in 1 2 3 4; do
  output="$(mktemp "temp/.${floor}f.XXXXXX")"
  floor_staging+=("$output")

  jq -r --arg floor "Floor $floor" --arg today "$TODAY" '
    def airtime:
      sub("\\.[0-9]{3}Z$"; "Z")
      | fromdateiso8601
      | strflocaltime("%H:%M");

    def airdate:
      sub("\\.[0-9]{3}Z$"; "Z")
      | fromdateiso8601
      | strflocaltime("%Y-%m-%d");

    [
      .records[]
      | select((.fields["Start Date"] | airdate) == $today)
      | select(
          (.fields["Floor Rollup (from Assigned Rooms)"] // [])
          | join(" ")
          | contains($floor)
        )
      | {
          start: .fields["Start Date"],
          end: .fields["End Date"],
          name: .fields.Name
        }
    ]
    | sort_by(.start)
    | if length == 0 then
        [""]
      else
        map("\(.start | airtime) - \(.end | airtime)|\(.name)")
      end
    | .[]
  ' "$events_staging" > "$output"
done

# Publish only after the API response and all four floor renderings validate.
install -m 644 "$events_staging" temp/events.json
for index in 0 1 2 3; do
  floor=$((index + 1))
  install -m 644 "${floor_staging[$index]}" "temp/${floor}f.txt"
done

echo "Updated events for all floors"

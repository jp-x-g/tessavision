#!/usr/bin/env bash

APIKEY="$(tr -d '\n' < auth/airtable.com.txt)"

echo "CURLing events"
# curl "https://api.airtable.com/v0/appkHZ2UvU6SouT5y/Events?maxRecords=3&view=Featured%20past%20events%20%28for%20website%29" \
#  -H "Authorization: Bearer $APIKEY" > test.txt

curl "https://api.airtable.com/v0/appkHZ2UvU6SouT5y/Events?maxRecords=3&view=Featured%20past%20events%20%28for%20website%29" \
  -H "Authorization: Bearer $APIKEY" > test.txt

# jq . test.txt

curl -sS "https://api.airtable.com/v0/appkHZ2UvU6SouT5y/Events" \
  -H "Authorization: Bearer $APIKEY" \
  -G \
  --data-urlencode "view=Upcoming Events" \
  --data-urlencode "filterByFormula=IS_AFTER({Start Date}, TODAY())" \
  --data-urlencode "sort[0][field]=Start Date" \
  --data-urlencode "sort[0][direction]=asc" \
  > temp/events.json

  #cat temp/events.json
  #jq . temp/events.json

TODAY="$(date +%F)"

for f in 1 2 3 4; do
  jq -r --arg floor "Floor $f" --arg today "$TODAY" '
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
        map("\(.start | airtime) - \(.end | airtime)│ \(.name)")
      end
    | .[]
  ' temp/events.json > "temp/${f}f.txt"
  echo "${f}: "
  cat temp/${f}f.txt
done
# Note that the "│" between the start-end and the event name is a box-drawing Unicode char, not a pipe

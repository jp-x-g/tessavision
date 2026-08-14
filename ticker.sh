#!/usr/bin/env bash
set -uo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

CACHE_MAX_AGE_SECONDS=7200
CURL_OPTIONS=(
  -fsS
  --connect-timeout 10
  --max-time 25
  --retry 2
  --retry-delay 2
  --retry-all-errors
)

mkdir -p temp

if [[ ! -s auth/financialmodelingprep.com.txt ]]; then
  echo "Missing Financial Modeling Prep API key" >&2
  exit 1
fi
APIKEY="$(tr -d '\n' < auth/financialmodelingprep.com.txt)"

fetch_fmp_quote() {
  local symbol="$1"
  local destination="temp/${symbol}.txt"
  local staging

  staging="$(mktemp "temp/.${symbol}.XXXXXX")"
  if curl "${CURL_OPTIONS[@]}" \
      -A 'Mozilla/5.0 (X11; Linux x86_64) TessaVision/1.0' \
      -H 'Accept: application/json,text/plain,*/*' \
      "https://financialmodelingprep.com/stable/quote-short?symbol=${symbol}&apikey=${APIKEY}" \
      | jq -er '.[0].price | numbers | floor' > "$staging"; then
    chmod 644 "$staging"
    mv -f "$staging" "$destination"
    echo "Updated $symbol"
  else
    rm -f "$staging"
    echo "Could not refresh $symbol; preserving its last-known value" >&2
    return 1
  fi
}

fetch_btc_quote() {
  local destination="temp/BTC.txt"
  local staging

  staging="$(mktemp temp/.BTC.XXXXXX)"
  if curl "${CURL_OPTIONS[@]}" \
      'https://api.exchange.coinbase.com/products/BTC-USD/ticker' \
      | jq -er '.price | tonumber | floor' > "$staging"; then
    chmod 644 "$staging"
    mv -f "$staging" "$destination"
    echo "Updated BTC"
  else
    rm -f "$staging"
    echo "Could not refresh BTC; preserving its last-known value" >&2
    return 1
  fi
}

refresh_failures=0
for symbol in SPY BZUSD; do
  fetch_fmp_quote "$symbol" || refresh_failures=$((refresh_failures + 1))
done
fetch_btc_quote || refresh_failures=$((refresh_failures + 1))

cache_is_fresh() {
  local path="$1"
  local now modified value

  [[ -s "$path" ]] || return 1
  value="$(tr -d '[:space:]' < "$path")"
  [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1

  now="$(date +%s)"
  modified="$(stat -c %Y "$path")"
  (( now - modified <= CACHE_MAX_AGE_SECONDS ))
}

# Only the three displayed quotes gate success. When any displayed cache is
# missing or more than two hours old, systemd retries this service every minute.
for required in temp/SPY.txt temp/BTC.txt temp/BZUSD.txt; do
  if ! cache_is_fresh "$required"; then
    echo "Displayed quote cache is missing or stale: $required" >&2
    exit 1
  fi
done

if (( refresh_failures > 0 )); then
  echo "$refresh_failures refreshes failed; fresh cached values remain usable" >&2
fi

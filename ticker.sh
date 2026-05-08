#!/usr/bin/env bash

APIKEY="$(tr -d '\n' < auth/financialmodelingprep.com.txt)"

echo "CURLing SPY"
curl -fsS \
  -A 'Mozilla/5.0 (X11; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0' \
  -H 'Accept: application/json,text/plain,*/*' \
  "https://financialmodelingprep.com/stable/quote-short?symbol=SPY&apikey=$APIKEY" \
  | jq -r '.[0].price | floor' > temp/SPY.txt

echo "CURLing QQQ"
curl -fsS \
  -A 'Mozilla/5.0 (X11; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0' \
  -H 'Accept: application/json,text/plain,*/*' \
  "https://financialmodelingprep.com/stable/quote-short?symbol=QQQ&apikey=$APIKEY" \
  | jq -r '.[0].price | floor' > temp/QQQ.txt

echo "CURLing DIA"
curl -fsS \
  -A 'Mozilla/5.0 (X11; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0' \
  -H 'Accept: application/json,text/plain,*/*' \
  "https://financialmodelingprep.com/stable/quote-short?symbol=DIA&apikey=$APIKEY" \
  | jq -r '.[0].price | floor' > temp/DIA.txt

echo "CURLing BZUSD"
curl -fsS \
  -A 'Mozilla/5.0 (X11; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0' \
  -H 'Accept: application/json,text/plain,*/*' \
  "https://financialmodelingprep.com/stable/quote-short?symbol=BZUSD&apikey=$APIKEY" \
  | jq -r '.[0].price | floor' > temp/BZUSD.txt

 # qqq nasdaq
 # dia dow
 # iwm russell

# curl -fsS "https://financialmodelingprep.com/stable/quote-short?symbol=SPY&apikey=$APIKEY" \
  # | jq -r '.[0].price | floor' > temp/SP500.txt
# 
# curl -fsS "https://financialmodelingprep.com/stable/quote-short?symbol=QQQ&apikey=$APIKEY" \
  # | jq -r '.[0].price | floor' > temp/NASDAQ.txt
# 
# curl -fsS "https://financialmodelingprep.com/stable/quote-short?symbol=DIA&apikey=$APIKEY" \
  # | jq -r '.[0].price | floor' > temp/DOW.txt
# 
# curl -fsS "https://financialmodelingprep.com/stable/quote-short?symbol=IWM&apikey=$APIKEY" \
  # | jq -r '.[0].price | floor' > temp/RUSSELL.txt

curl -fsS 'https://api.exchange.coinbase.com/products/BTC-USD/ticker' \
  | jq -r '.price | tonumber | floor' > temp/BTC.txt

# printf "NASDAQ: $%s | SPY: $%s | BTC: $%s" "$(cat temp/QQQ.txt)" "$(cat temp/SPY.txt)" "$(cat temp/BTC.txt)" > temp/ticker.txt


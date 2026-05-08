#!/usr/bin/env bash

APIKEY="$(tr -d '\n' < auth/financialmodelingprep.com.txt)"
curl -fsS \
  -A 'Mozilla/5.0 (X11; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0' \
  -H 'Accept: application/json,text/plain,*/*' \
  "https://financialmodelingprep.com/stable/quote-short?symbol=SPY&apikey=$APIKEY" \
  | jq -r '.[0].price | floor' > temp/SP500.txt

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
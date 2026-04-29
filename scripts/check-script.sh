#!/usr/bin/env bash
URL="http://192.168.1.165:7900/SendToKindle/Script"
echo "===== HTTP status ====="
curl -s -o /dev/null -w "%{http_code}\n" "$URL"
echo
echo "===== First 30 lines of served JS ====="
curl -s "$URL" | head -30
echo
echo "===== Total bytes served ====="
curl -s "$URL" | wc -c

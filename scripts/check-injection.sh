#!/usr/bin/env bash
# Check whether the Send-to-Kindle script tag was injected into index.html.
set -u

URL="http://192.168.1.165:7900/web/index.html"
HTML=$(curl -s "$URL")

echo "===== Marker count (expected: 1 if injected) ====="
echo "$HTML" | grep -c "SendToKindle-Injected"

echo
echo "===== Script tag (if present) ====="
echo "$HTML" | grep -i "SendToKindle"

echo
echo "===== Tail of body (last 500 chars) ====="
echo "$HTML" | tail -c 500

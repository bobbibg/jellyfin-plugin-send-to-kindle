#!/usr/bin/env bash
# POST the updated branding (ElegantFin + Cypherflix tweaks) to Jellyfin.
set -u
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
PAYLOAD="$HOME/Code/branding-update.json"

if [ ! -f "$PAYLOAD" ]; then
    echo "ERROR: $PAYLOAD not found. Build it first."
    exit 1
fi

echo "===== Posting branding update ====="
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: MediaBrowser Token=\"${API_KEY}\"" \
    --data-binary "@$PAYLOAD" \
    "${JF_URL}/System/Configuration/branding"

echo
echo "===== Verifying ====="
curl -s -H "Authorization: MediaBrowser Token=\"${API_KEY}\"" \
    "${JF_URL}/System/Configuration/branding" \
    | tr ',' '\n' \
    | head -20

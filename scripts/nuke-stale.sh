#!/usr/bin/env bash
set -u
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== Disable IMVDb plugin ====="
curl -s -o /dev/null -w "Disable: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Plugins/a4967b3515b346f0bc7e0b7d90623a85/Disable"

echo
echo "===== Look for global ScanLibrary task ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr '}' '\n' \
    | grep -E '"Name":"(Scan Media Library|Refresh Guide|Library)' \
    | sed -E 's/.*"Name":"([^"]+)".*"Id":"([a-f0-9-]+)".*/\2 -- \1/' \
    | head -10

echo
echo "===== Trigger global Scan Media Library (removes missing items) ====="
# Find ID by name then POST to Running endpoint
SCAN_ID=$(curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr '}' '\n' \
    | grep '"Name":"Scan Media Library"' \
    | grep -oE '"Id":"[a-f0-9-]+"' \
    | head -1 \
    | cut -d'"' -f4)
echo "Scan task ID: $SCAN_ID"
if [ -n "$SCAN_ID" ]; then
    curl -s -o /dev/null -w "Trigger Scan: HTTP %{http_code}\n" \
        -X POST -H "$AUTH_HDR" \
        "${JF_URL}/ScheduledTasks/Running/${SCAN_ID}"
fi

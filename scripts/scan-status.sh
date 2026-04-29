#!/usr/bin/env bash
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

# Show running tasks with name + progress
curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr '}' '\n' \
    | grep -E '"State":"(Running|Cancelling)"' \
    | sed -E 's/.*"Name":"([^"]+)".*"State":"([^"]+)".*"CurrentProgressPercentage":([0-9.]+).*/\1 -- \2 -- \3%/' \
    | head -10

echo
echo "(empty means no running tasks)"

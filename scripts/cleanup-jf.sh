#!/usr/bin/env bash
# Cleanup pass on Jellyfin: trigger missing-items cleanup, retry comics, disable IMVDb noise.
set -u
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

BOOKS_ID="4e985111ed7f570b595204d82adb02f3"
COMICS_ID="2912d51b5fccd138129c54cce1e8bbc6"
MUSIC_ID="7e64e319657a9516ec78490da03edccb"
AUDIOBOOKS_ID="c0c1444b416777d3fa55d5f13da1ce58"

echo "===== Step 1: List scheduled tasks (looking for a cleanup task) ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr '}' '\n' \
    | grep -E '"Name":' \
    | grep -iE 'clean|prune|maintain|garbage' \
    | sed -E 's/.*"Name":"([^"]+)".*"Id":"([a-f0-9-]+)".*/\2 -- \1/' \
    | head -10

echo
echo "===== Step 2: Find IMVDb plugin info ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Plugins" \
    | tr '{' '\n' \
    | grep -i 'imvdb' \
    | sed -E 's/.*"Name":"([^"]+)".*"Version":"([^"]+)".*"Id":"([a-f0-9-]+)".*"Status":"([^"]+)".*/\3 -- \1 v\2 (\4)/'

echo
echo "===== Step 3: Trigger comics-only refresh (rate limit should be reset) ====="
curl -s -o /dev/null -w "Comics refresh: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Items/${COMICS_ID}/Refresh?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh&ReplaceAllMetadata=true&ReplaceAllImages=false"

echo
echo "===== Step 4: Trigger books library refresh (NewlyAdded mode = remove missing, scan new) ====="
curl -s -o /dev/null -w "Books refresh: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Items/${BOOKS_ID}/Refresh?Recursive=true&MetadataRefreshMode=Default&ImageRefreshMode=Default&ReplaceAllMetadata=false"

echo
echo "===== Tasks running now ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr '}' '\n' \
    | grep '"State":"Running"' \
    | sed -E 's/.*"Name":"([^"]+)".*"State":"([^"]+)".*"CurrentProgressPercentage":([0-9.]+).*/\1 -- \3%/'

#!/usr/bin/env bash
# Trigger a full Jellyfin metadata refresh on the Books library.
set -u
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== Currently running scheduled tasks ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr ',' '\n' | grep -E '"State":' | sort -u

echo
echo "===== Books library ID ====="
LIBS=$(curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders")
# Find ItemId where CollectionType=books — pull as a single line, then grep
BOOKS_ID=$(echo "$LIBS" | tr ',' '\n' | grep -B1 '"CollectionType":"books"' | grep -oE '"ItemId":"[^"]+"' | head -1 | cut -d'"' -f4)
# Fallback: look at the Books name
if [ -z "$BOOKS_ID" ]; then
    BOOKS_ID=$(echo "$LIBS" | grep -oE '"Name":"Books"[^}]*"ItemId":"[a-f0-9-]+"' | head -1 | grep -oE '"ItemId":"[a-f0-9-]+"' | cut -d'"' -f4)
fi
echo "Books library ItemId: $BOOKS_ID"

echo
echo "===== Trigger FULL refresh (replace metadata) ====="
if [ -n "$BOOKS_ID" ]; then
    curl -s -o /dev/null -w "Refresh HTTP %{http_code}\n" \
        -X POST -H "$AUTH_HDR" \
        "${JF_URL}/Items/${BOOKS_ID}/Refresh?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh&ReplaceAllMetadata=true&ReplaceAllImages=false"
else
    echo "Could not resolve Books library ID — falling back to library-wide refresh"
    curl -s -o /dev/null -w "Refresh HTTP %{http_code}\n" \
        -X POST -H "$AUTH_HDR" \
        "${JF_URL}/Library/Refresh"
fi

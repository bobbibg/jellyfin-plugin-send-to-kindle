#!/usr/bin/env bash
# Delete the orphaned Books and Comics libraries and re-add them with the correct
# /library paths. Files on disk are not touched.
set -u
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== Stop the running scan first (it's chasing dead paths) ====="
curl -s -o /dev/null -w "Stop scan: HTTP %{http_code}\n" \
    -X DELETE -H "$AUTH_HDR" \
    "${JF_URL}/ScheduledTasks/Running/7738148ffcd07979c7ceb148e06b3aed"

echo
echo "===== Remove Books library (DB only, files preserved) ====="
curl -s -o /dev/null -w "Delete Books: HTTP %{http_code}\n" \
    -X DELETE -H "$AUTH_HDR" \
    "${JF_URL}/Library/VirtualFolders?name=Books&refreshLibrary=false"

echo
echo "===== Remove Comics library ====="
curl -s -o /dev/null -w "Delete Comics: HTTP %{http_code}\n" \
    -X DELETE -H "$AUTH_HDR" \
    "${JF_URL}/Library/VirtualFolders?name=Comics&refreshLibrary=false"

echo
echo "===== Re-add Books with /library/books path ====="
curl -s -o /dev/null -w "Add Books: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" -H "Content-Type: application/json" \
    "${JF_URL}/Library/VirtualFolders?name=Books&collectionType=books&refreshLibrary=true&paths=%2Flibrary%2Fbooks"

echo
echo "===== Re-add Comics with /library/comics path ====="
curl -s -o /dev/null -w "Add Comics: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" -H "Content-Type: application/json" \
    "${JF_URL}/Library/VirtualFolders?name=Comics&collectionType=books&refreshLibrary=true&paths=%2Flibrary%2Fcomics"

echo
echo "===== Verify new VirtualFolders ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" \
    | tr ',' '\n' \
    | grep -E '"(Name|Locations|CollectionType)":' | head -25

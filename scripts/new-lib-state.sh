#!/usr/bin/env bash
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== Get NEW Books library ID ====="
LIBS=$(curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders")
BOOKS_ID=$(echo "$LIBS" | tr ',' '\n' | grep -B5 '/library/books' | grep -oE '"ItemId":"[a-f0-9-]+"' | head -1 | cut -d'"' -f4)
COMICS_ID=$(echo "$LIBS" | tr ',' '\n' | grep -B5 '/library/comics' | grep -oE '"ItemId":"[a-f0-9-]+"' | head -1 | cut -d'"' -f4)
echo "Books ID: $BOOKS_ID"
echo "Comics ID: $COMICS_ID"

echo
echo "===== Books items count ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Items?ParentId=${BOOKS_ID}&Recursive=true&IncludeItemTypes=Book&Limit=1" \
    | grep -oE '"TotalRecordCount":[0-9]+'

echo
echo "===== Comics items count ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Items?ParentId=${COMICS_ID}&Recursive=true&Limit=1" \
    | grep -oE '"TotalRecordCount":[0-9]+'

echo
echo "===== 3 sample Book paths ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Items?ParentId=${BOOKS_ID}&Recursive=true&IncludeItemTypes=Book&Limit=3&Fields=Path" \
    | tr '{' '\n' | grep -oE '"Path":"[^"]+"' | head -3

echo
echo "===== Currently running scan ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr '}' '\n' \
    | grep '"State":"Running"' \
    | sed -E 's/.*"Name":"([^"]+)".*"CurrentProgressPercentage":([0-9.]+).*/\1 -- \2%/'

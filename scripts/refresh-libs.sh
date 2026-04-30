#!/usr/bin/env bash
# Trigger full metadata refresh for the Books and Comics libraries.
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

BOOKS_ID="4e985111ed7f570b595204d82adb02f3"
COMICS_ID="2912d51b5fccd138129c54cce1e8bbc6"

echo "===== Refreshing Books library ====="
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Items/${BOOKS_ID}/Refresh?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh&ReplaceAllMetadata=true&ReplaceAllImages=false"

echo
echo "===== Refreshing Comics library ====="
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Items/${COMICS_ID}/Refresh?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh&ReplaceAllMetadata=true&ReplaceAllImages=false"

echo
echo "Both refreshes queued. Watch progress at $JF_URL/web/index.html#/dashboard"

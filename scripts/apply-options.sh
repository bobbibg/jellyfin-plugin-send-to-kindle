#!/usr/bin/env bash
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== Apply Books library options ====="
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" -H "Content-Type: application/json" \
    --data-binary "@$HOME/Code/books-opts.json" \
    "${JF_URL}/Library/VirtualFolders/LibraryOptions"

echo
echo "===== Apply Comics library options ====="
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" -H "Content-Type: application/json" \
    --data-binary "@$HOME/Code/comics-opts.json" \
    "${JF_URL}/Library/VirtualFolders/LibraryOptions"

echo
echo "===== Trigger fresh full scan with metadata replace on both ====="
curl -s -o /dev/null -w "Books refresh: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Items/4e985111ed7f570b595204d82adb02f3/Refresh?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh&ReplaceAllMetadata=true"

curl -s -o /dev/null -w "Comics refresh: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Items/2912d51b5fccd138129c54cce1e8bbc6/Refresh?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh&ReplaceAllMetadata=true"

echo
echo "===== Verify options stuck ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" \
    | tr '{' '\n' \
    | grep -E '"(Name|EnableInternetProviders|MetadataFetchers)":' \
    | grep -v 'TV\|Movies\|Music\|Collections\|Audiobooks' \
    | head -10

#!/usr/bin/env bash
# Wipe the Books library's DB items in Jellyfin and rescan from scratch.
# Files on disk are untouched. Other libraries (TV/Movies/Music/Comics) are not affected.
set -u
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""
PATH_NEW="/library/books"

echo "===== Saving current Books library options ====="
# Snapshot the existing options so we can restore them after re-add
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" > /tmp/jf-folders-before.json
echo "Saved snapshot to /tmp/jf-folders-before.json ($(wc -c < /tmp/jf-folders-before.json) bytes)"

echo
echo "===== Deleting Books library (DB only — files preserved) ====="
curl -s -o /dev/null -w "Delete: HTTP %{http_code}\n" \
    -X DELETE -H "$AUTH_HDR" \
    "${JF_URL}/Library/VirtualFolders?name=Books&refreshLibrary=false"

echo
echo "===== Re-adding Books library at ${PATH_NEW} ====="
curl -s -o /dev/null -w "Add: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Library/VirtualFolders?name=Books&collectionType=books&refreshLibrary=false&paths=$(printf '%s' "$PATH_NEW" | sed 's|/|%2F|g')"

echo
echo "===== Applying library options (metadata fetchers, internet providers) ====="
# Get the new library's ItemId
sleep 1
NEW_ID=$(curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
for v in data:
    if v.get('Name') == 'Books':
        print(v.get('ItemId',''))
        break
")
echo "New Books ItemId: $NEW_ID"

# POST library options with proper metadata fetcher config
cat > /tmp/books-opts.json <<EOF
{
  "Id": "$NEW_ID",
  "LibraryOptions": {
    "Enabled": true,
    "EnablePhotos": true,
    "EnableRealtimeMonitor": true,
    "PathInfos": [{"Path": "$PATH_NEW", "NetworkPath": ""}],
    "SaveLocalMetadata": true,
    "EnableInternetProviders": true,
    "EnableAutomaticSeriesGrouping": false,
    "EnableEmbeddedTitles": true,
    "AutomaticRefreshIntervalDays": 0,
    "PreferredMetadataLanguage": "en",
    "MetadataCountryCode": "GB",
    "SeasonZeroDisplayName": "Specials",
    "MetadataSavers": [],
    "DisabledLocalMetadataReaders": [],
    "LocalMetadataReaderOrder": ["Epub Metadata", "Open Packaging Format"],
    "DisabledSubtitleFetchers": [],
    "SubtitleFetcherOrder": [],
    "TypeOptions": [
      {
        "Type": "Book",
        "MetadataFetchers": ["Google Books"],
        "MetadataFetcherOrder": ["Google Books"],
        "ImageFetchers": ["Google Books", "Epub Metadata"],
        "ImageFetcherOrder": ["Google Books", "Epub Metadata"],
        "ImageOptions": []
      }
    ]
  }
}
EOF

curl -s -o /dev/null -w "LibraryOptions: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" -H "Content-Type: application/json" \
    --data-binary "@/tmp/books-opts.json" \
    "${JF_URL}/Library/VirtualFolders/LibraryOptions"

echo
echo "===== Triggering full metadata refresh on the new library ====="
curl -s -o /dev/null -w "Refresh: HTTP %{http_code}\n" \
    -X POST -H "$AUTH_HDR" \
    "${JF_URL}/Items/${NEW_ID}/Refresh?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh&ReplaceAllMetadata=true"

echo
echo "===== Verify ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" \
    | python3 -c "
import json, sys
for v in json.load(sys.stdin):
    if v['Name'] == 'Books':
        print(f\"  Name: {v['Name']}\")
        print(f\"  Path: {v['Locations']}\")
        print(f\"  ItemId: {v['ItemId']}\")
        opts = v.get('LibraryOptions', {})
        print(f\"  EnableInternetProviders: {opts.get('EnableInternetProviders')}\")
        types = opts.get('TypeOptions', [])
        for t in types:
            print(f\"  {t.get('Type')}: fetchers={t.get('MetadataFetchers')}\")
"

echo
echo "Books library reset. Watch the scan progress at:"
echo "  $JF_URL/web/index.html#/dashboard"

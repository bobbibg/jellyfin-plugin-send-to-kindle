#!/usr/bin/env bash
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== All plugin Status ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Plugins" \
    | tr '{' '\n' \
    | grep -iE 'comic|vine|bookshelf' \
    | sed -E 's/.*"Name":"([^"]+)".*"Version":"([^"]+)".*"Status":"([^"]+)".*/\1 -- v\2 -- \3/'

echo
echo "===== Most-recent Comic Vine log lines (any state) ====="
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 '
LOG=$(ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1)
[ -n "$LOG" ] && grep -iE "comicvine|comic.vine|comic_vine|Plugin.*Comic" "$LOG" | tail -15
'

echo
echo "===== Comics library metadata fetcher config ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" \
    | tr ',' '\n' \
    | awk '/Comics/,/ItemId/' \
    | grep -E '(Name|CollectionType|MetadataFetchers|MetadataFetcherOrder|MetadataReaders|MetadataReaderOrder|EnabledMetadataReaders)' \
    | head -25

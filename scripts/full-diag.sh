#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== ACTIVE STREAMS ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Sessions" \
    | tr ',' '\n' \
    | grep -E '(UserName|NowPlayingItem|DeviceName)' \
    | head -15

echo
echo "===== Music library config ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" \
    | tr ',' '\n' \
    | awk '/"Music"/,/ItemId/' \
    | grep -E '(Name|CollectionType|MetadataFetchers|MetadataFetcherOrder|EnabledMetadataReaders|LocalMetadataReaderOrder|Locations)' \
    | head -25

echo
echo "===== Currently running tasks ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr '}' '\n' \
    | grep '"State":"Running"' \
    | sed -E 's/.*"Name":"([^"]+)".*"State":"([^"]+)".*"CurrentProgressPercentage":([0-9.]+).*/\1 -- \3%/' \
    | head -5

echo
echo "===== NAS-side diagnostics ====="
ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" 'bash -s' <<'REMOTE'
LOG=$(ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1)
echo "Log: $LOG"
echo
echo "--- Total stale-path errors today ---"
grep -c 'Could not find file' "$LOG"
echo
echo "--- Sample stale paths (first 15 unique) ---"
grep 'Could not find file' "$LOG" | grep -oE "/data/(books|comics|music)[^']+" | sort -u | head -15
echo
echo "--- MUSIC tree (top level) ---"
ls /volume2/Library/music 2>/dev/null
echo
echo "--- Music subfolders structure (top 3 levels, sample) ---"
find /volume2/Library/music -maxdepth 3 -mindepth 1 -type d 2>/dev/null | head -20
echo
echo "--- Music file extension counts ---"
find /volume2/Library/music -type f 2>/dev/null | sed -E 's/.*\.//' | sort | uniq -c | sort -rn | head -10
echo
echo "--- Music-related errors in log (last 25) ---"
grep -iE "(ERR|WRN).*(music|audio|metaaudio|musicbrainz|audiodb|discogs)" "$LOG" | tail -25
echo
echo "--- Comics-related errors today (last 10) ---"
grep -iE "(ERR|WRN).*(comic|cbz)" "$LOG" | tail -10
REMOTE

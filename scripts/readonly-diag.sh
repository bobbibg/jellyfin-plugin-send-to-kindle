#!/usr/bin/env bash
# READ-ONLY diagnosis: scan progress, Comic Vine activity, slow-book signs.
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== Active sessions (so we don't bother streaming users) ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Sessions" \
    | tr ',' '\n' \
    | grep -E '"(UserName|NowPlayingItem|DeviceName|Client)":' \
    | head -15

echo
echo "===== Currently running scheduled tasks ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/ScheduledTasks" \
    | tr '}' '\n' \
    | grep -E '"State":"(Running|Cancelling)"' \
    | sed -E 's/.*"Name":"([^"]+)".*"State":"([^"]+)".*"CurrentProgressPercentage":([0-9.]+).*/\1 -- \2 -- \3%/'

echo
echo "===== Comic Vine activity in JF log ====="
ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" '
LOG=$(ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1)
if [ -n "$LOG" ]; then
    echo "Log file: $LOG"
    echo
    echo "--- last 30 ComicVine-related lines ---"
    grep -iE "comicvine|comic.vine|comic_vine" "$LOG" | tail -30
    echo
    echo "--- last 10 errors mentioning Comic ---"
    grep -iE "ERR.*comic|FAIL.*comic|exception.*comic" "$LOG" | tail -10
fi
'

echo
echo "===== Books library load timing ====="
ssh -o BatchMode=yes "$NAS" '
LOG=$(ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1)
if [ -n "$LOG" ]; then
    echo "--- Bookshelf / EPUB activity (last 20) ---"
    grep -iE "bookshelf|epub|book.*scan|book.*refresh" "$LOG" | tail -20
    echo
    echo "--- Slow-request warnings (last 10) ---"
    grep -iE "slow|timeout|deadline" "$LOG" | tail -10
fi
'

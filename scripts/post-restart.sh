#!/usr/bin/env bash
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
LOG=$(ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1)
echo "Log file: $LOG"
echo
echo "===== Latest 25 lines of any kind ====="
tail -25 "$LOG"
echo
echo "===== Plugin folder still on disk? ====="
ls -la /volume3/Docker/cypherflix/config/jellyfin/plugins/ | grep -i comic
echo
echo "===== Disabled plugin marker? ====="
find /volume3/Docker/cypherflix/config/jellyfin/plugins/ -name 'meta.json' -path '*Comic*' -exec cat {} \; 2>/dev/null
echo
echo "===== Most recent Comic Vine plugin load ====="
grep -E "Comic Vine|ComicVine" "$LOG" | tail -10
REMOTE

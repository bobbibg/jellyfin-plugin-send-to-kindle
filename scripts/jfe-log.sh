#!/usr/bin/env bash
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
LOG=$(ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1)
echo "Log: $LOG"
echo
echo "===== Most recent JF Enhanced / Seerr lines (last 40) ====="
tail -3000 "$LOG" | grep -iE "JellyfinEnhanced|seerr|jellyseerr" | tail -40
REMOTE

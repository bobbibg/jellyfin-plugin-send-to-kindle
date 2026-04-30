#!/usr/bin/env bash
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
LOG=$(ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1)
echo "Comic Vine since 23:30 (latest activity):"
awk '/^\[2026-04-29 23:3/,EOF' "$LOG" | grep -iE "comicvine|comic.vine" | tail -25
echo
echo "--- Comic Vine error counts since 23:30 ---"
awk '/^\[2026-04-29 23:3/,EOF' "$LOG" | grep -ciE "Rate limit"
echo "Rate-limit hits"
awk '/^\[2026-04-29 23:3/,EOF' "$LOG" | grep -ciE "comicvine.*error"
echo "Other CV errors"
echo
echo "--- Books 'Could not find' since the scan started ---"
awk '/^\[2026-04-29 23:[3-5]/,EOF' "$LOG" | grep -c 'Could not find file'
REMOTE

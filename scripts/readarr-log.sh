#!/usr/bin/env bash
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
echo "===== config.xml metadata setting ====="
grep -iE "metadata|bookinfo|servarr" /volume3/Docker/cypherflix/config/readarr/config.xml 2>/dev/null

echo
echo "===== Recent Readarr metadata-related log lines ====="
LOG=$(ls -t /volume3/Docker/cypherflix/config/readarr/logs/readarr*.txt 2>/dev/null | head -1)
echo "Log: $LOG"
if [ -n "$LOG" ]; then
    echo "--- HTTP request URLs from log ---"
    tail -2000 "$LOG" | grep -iE "Url:|http.*api\.bookinfo|http.*readarr\.servarr|Sending request" | tail -10
    echo
    echo "--- Full error context ---"
    tail -2000 "$LOG" | grep -B2 -A5 "Invalid response received" | tail -30
fi
REMOTE

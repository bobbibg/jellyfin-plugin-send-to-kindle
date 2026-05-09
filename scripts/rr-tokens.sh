#!/usr/bin/env bash
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
echo "===== FileNameBuilder.cs token list (from Readarr binary) ====="
sudo strings /volume3/Docker/cypherflix/config/readarr/Readarr.dll 2>/dev/null \
    | grep -oE '\{[A-Z][^{}]{2,40}\}' | sort -u | grep -iE "book|series|isbn|asin|author|title|year|part" | head -40
echo
echo "===== Or look in the UI bundle (likely shows tokens in tooltips) ====="
ls /volume3/Docker/cypherflix/config/readarr/ 2>/dev/null
REMOTE

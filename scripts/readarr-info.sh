#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
echo "===== Readarr API key from config.xml ====="
grep -oE '<ApiKey>[a-f0-9]+</ApiKey>' /volume3/Docker/cypherflix/config/readarr/config.xml 2>/dev/null \
    | head -1 | sed 's|<[^>]*>||g'

echo
echo "===== Readarr URL inside container ====="
grep -oE '<Port>[0-9]+</Port>|<UrlBase>[^<]*</UrlBase>' /volume3/Docker/cypherflix/config/readarr/config.xml 2>/dev/null
REMOTE

#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes bobbi@192.168.1.165 'bash -s' <<'REMOTE'
echo "=== Murakami, Haruki (legacy folder) ==="
ls -la "/volume2/Library/books/Murakami, Haruki/"
echo
echo "=== Haruki Murakami (target folder) ==="
ls -la "/volume2/Library/books/Haruki Murakami/"
REMOTE

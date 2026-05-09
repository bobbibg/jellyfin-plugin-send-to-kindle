#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
set +e
SRC="/volume2/Library/books/Don Norman"
DST="/volume2/Library/books/Donald A. Norman"

if [ -d "$SRC" ]; then
    mkdir -p "$DST"
    for f in "$SRC"/*; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        if [ -e "$DST/$base" ]; then
            echo "SKIP (target exists): $DST/$base"
        else
            mv "$f" "$DST/$base" && echo "MOVED: $f -> $DST/$base"
        fi
    done
    rmdir "$SRC" 2>/dev/null && echo "RMDIR: $SRC"
else
    echo "Source folder not found"
fi

echo
echo "Final state:"
ls -la "$DST"
REMOTE

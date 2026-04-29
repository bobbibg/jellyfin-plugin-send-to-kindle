#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

ssh -o BatchMode=yes "$NAS" 'bash -s' <<'REMOTE'
for d in \
    "/volume2/Library/books/Terry Pratchett/Mort" \
    "/volume2/Library/books/Terry Pratchett/Guards! Guards!" \
    "/volume2/Library/books/M. C. Beaton/Agatha Raisin and the Quiche of Death" \
    "/volume2/Library/books/Mary Pope Osborne/Magic Tree House 1" \
    "/volume2/Library/books/M. C. Beaton/Agatha Raisin"
do
    echo "=== $d ==="
    ls -la "$d" 2>/dev/null | head -10
    echo
done

echo "=== File extension counts in no-epub folders ==="
for d in /volume2/Library/books/M.\ C.\ Beaton/* /volume2/Library/books/Terry\ Pratchett/* /volume2/Library/books/Mary\ Pope\ Osborne/*; do
    [ -d "$d" ] || continue
    if ! find "$d" -maxdepth 1 -name '*.epub' | grep -q .; then
        find "$d" -maxdepth 1 -type f -printf "%f\n" 2>/dev/null | head -5
    fi
done | awk -F. 'NF>1 {print $NF}' | sort | uniq -c | sort -rn
REMOTE

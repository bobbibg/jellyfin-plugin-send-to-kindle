#!/usr/bin/env bash
# Books library cleanup: delete leftover Calibre DB files, merge duplicates, delete JKR.
# Default: DRY RUN. Pass --execute to actually delete/move.
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

EXECUTE="false"
[ "${1:-}" = "--execute" ] && EXECUTE="true"

echo "Mode: $([ "$EXECUTE" = "true" ] && echo EXECUTE || echo DRY-RUN)"
echo

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" \
     "EXECUTE=$EXECUTE bash -s" <<'REMOTE'
set +e
BOOKS=/volume2/Library/books
COMICS=/volume2/Library/comics

if [ "$EXECUTE" = "true" ]; then
    DO() { "$@"; }
else
    DO() { echo "WOULD: $*"; }
fi

echo "===== 1. Delete Calibre DB leftovers at books root ====="
for f in "$BOOKS/metadata.db" "$BOOKS/metadata_db_prefs_backup.json" "$BOOKS/metadata_pre_restore.db"; do
    if [ -e "$f" ]; then
        DO rm -f "$f"
    fi
done

echo
echo "===== 2. Delete Calibre DB at comics root ====="
if [ -e "$COMICS/metadata.db" ]; then
    DO rm -f "$COMICS/metadata.db"
fi

echo
echo "===== 3. Delete J. K. Rowling folder (per request) ====="
if [ -d "$BOOKS/J. K. Rowling" ]; then
    DO rm -rf "$BOOKS/J. K. Rowling"
fi

echo
echo "===== 4. Delete 'Murakami, Haruki' (exact dupes already in 'Haruki Murakami') ====="
if [ -d "$BOOKS/Murakami, Haruki" ]; then
    DO rm -rf "$BOOKS/Murakami, Haruki"
fi

echo
echo "===== 5. Merge 'Jim Butcher; Mark Powers_' into 'Jim Butcher' ====="
SRC="$BOOKS/Jim Butcher; Mark Powers_"
DST="$BOOKS/Jim Butcher"
if [ -d "$SRC" ]; then
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        base=$(basename "$f")
        if [ -e "$DST/$base" ]; then
            echo "  CONFLICT (skipping): $DST/$base already exists"
        else
            DO mv "$f" "$DST/$base"
        fi
    done < <(find "$SRC" -mindepth 1 -maxdepth 1)
    DO rmdir "$SRC" 2>/dev/null
fi

echo
echo "===== 6. Final author folder list ====="
ls "$BOOKS"
REMOTE

#!/usr/bin/env bash
# De-dupe comic-format .epubs in /library/books:
#   - Delete if a .cbz already exists in /library/comics
#   - Move to /library/comics/<Series>/ if no .cbz match
# Default: DRY RUN. Pass --execute to actually move/delete.
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
B=/volume2/Library/books
C=/volume2/Library/comics

if [ "$EXECUTE" = "true" ]; then
    DEL() { rm -f "$1" && echo "DELETED: $1"; }
    DEL_DIR() { rmdir "$1" 2>/dev/null && echo "DELETED-DIR: $1"; }
    MV() { mv "$1" "$2" && echo "MOVED: $1 -> $2"; }
else
    DEL() { echo "WOULD-DELETE: $1"; }
    DEL_DIR() { echo "WOULD-DELETE-DIR (if empty): $1"; }
    MV() { echo "WOULD-MOVE: $1 -> $2"; }
fi

# Helper: delete .epub + companion .jpg
del_with_cover() {
    local f="$1"
    [ -f "$f" ] && DEL "$f"
    local jpg="${f%.epub}.jpg"
    [ -f "$jpg" ] && DEL "$jpg"
}

# Helper: move .epub + companion .jpg to a target folder
mv_with_cover() {
    local src="$1"
    local target_dir="$2"
    local name=$(basename "$src")
    local base="${name%.epub}"
    [ -d "$target_dir" ] || { echo "MKDIR: $target_dir"; [ "$EXECUTE" = "true" ] && mkdir -p "$target_dir"; }
    if [ -f "$src" ]; then
        if [ -e "$target_dir/$name" ]; then
            echo "SKIP (target exists): $target_dir/$name"
        else
            MV "$src" "$target_dir/$name"
        fi
    fi
    if [ -f "${src%.epub}.jpg" ]; then
        if [ -e "$target_dir/${base}.jpg" ]; then
            echo "SKIP (jpg target exists): $target_dir/${base}.jpg"
        else
            MV "${src%.epub}.jpg" "$target_dir/${base}.jpg"
        fi
    fi
}

echo "===== DELETE: items with matching .cbz in comics ====="

# Alias #18 and #24 — comics has .cbz
del_with_cover "$B/Brian Michael Bendis/Alias (2001-2003) #18.epub"
del_with_cover "$B/Brian Michael Bendis/Alias (2001-2003) #24.epub"

# Han Solo all 5 — comics has all 5 .cbz
for i in 1 2 3 4 5; do
    del_with_cover "$B/Marjorie Liu/Han Solo (2016) #${i}.epub"
done

# Expanse Origins #1, #2 — comics has both
del_with_cover "$B/James S. A. Corey/The Expanse Origins #1.epub"
del_with_cover "$B/James S. A. Corey/The Expanse Origins #2.epub"

# White Sand Omnibus
del_with_cover "$B/Brandon Sanderson/White Sand Omnibus.epub"

echo
echo "===== MOVE: items NOT in comics (12 Alias issues) ====="
for i in 10 16 17 19 20 21 22 23 25 26 27 28; do
    mv_with_cover "$B/Brian Michael Bendis/Alias (2001-2003) #${i}.epub" "$C/Alias"
done

echo
echo "===== Remove now-empty author folders in books ====="
for d in "Brian Michael Bendis" "Marjorie Liu"; do
    full="$B/$d"
    if [ -d "$full" ]; then
        if [ -z "$(ls -A "$full" 2>/dev/null)" ]; then
            DEL_DIR "$full"
        else
            echo "SKIP (not empty): $full — has: $(ls "$full")"
        fi
    fi
done

echo
echo "===== Final stats ====="
echo "books .epub : $(find "$B" -name '*.epub' -type f | wc -l)"
echo "comics .cbz : $(find "$C" -name '*.cbz' -type f | wc -l)"
echo "comics .epub: $(find "$C" -name '*.epub' -type f | wc -l)"
echo "books authors: $(ls "$B" | wc -l)"
REMOTE

#!/usr/bin/env bash
# Restructure /volume2/Library/books from Calibre's
#     Author/Title/Title.epub  (+ Author/Title/cover.jpg)
# to the simpler Bookshelf-friendly
#     Author/Title.epub        (+ Author/Title.jpg)
#
# Why: Jellyfin treats each "Title/" subfolder as a containing folder, which
# is why the Books library still shows folder cards instead of book cards.
# Removing the intermediate level lets the Bookshelf plugin index each .epub
# as an individual Book item.
#
# Default: DRY RUN. Pass --execute to actually move.
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

EXECUTE="false"
[ "${1:-}" = "--execute" ] && EXECUTE="true"

echo "Mode: $([ "$EXECUTE" = "true" ] && echo EXECUTE || echo DRY-RUN)"
echo

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" \
     "EXECUTE=$EXECUTE bash -s" > "$HOME/flatten-output.txt" 2>&1 <<'REMOTE'
set +e
ROOT=/volume2/Library/books

if [ "$EXECUTE" = "true" ]; then
    DO() { "$@"; }
else
    DO() { echo "WOULD: $*"; }
fi

moved=0
skipped_multi=0
skipped_noepub=0
skipped_conflict=0
deleted_dirs=0

# Walk Author dirs
while IFS= read -r author_dir; do
    [ -z "$author_dir" ] && continue
    [ -d "$author_dir" ] || continue
    base=$(basename "$author_dir")
    [ "$base" = ".calnotes" ] && continue
    [ "$base" = "#recycle" ] && continue

    # Walk Title dirs inside Author
    while IFS= read -r title_dir; do
        [ -z "$title_dir" ] && continue
        [ -d "$title_dir" ] || continue

        # Find the single .epub (skip if 0 or >1)
        mapfile -t epubs < <(find "$title_dir" -maxdepth 1 -name '*.epub' -type f)
        if [ "${#epubs[@]}" -eq 0 ]; then
            # If empty dir, just remove it; otherwise leave with a warning
            if [ -z "$(ls -A "$title_dir")" ]; then
                DO rmdir "$title_dir"
                deleted_dirs=$((deleted_dirs+1))
            else
                echo "SKIP no-epub : $title_dir (has other files)"
                skipped_noepub=$((skipped_noepub+1))
            fi
            continue
        fi
        if [ "${#epubs[@]}" -gt 1 ]; then
            echo "SKIP multi-epub : $title_dir (${#epubs[@]} files)"
            skipped_multi=$((skipped_multi+1))
            continue
        fi

        epub="${epubs[0]}"
        epub_base=$(basename "$epub" .epub)
        new_epub="$author_dir/$(basename "$epub")"

        if [ -e "$new_epub" ]; then
            echo "SKIP conflict : $new_epub already exists"
            skipped_conflict=$((skipped_conflict+1))
            continue
        fi

        # Move .epub up
        DO mv "$epub" "$new_epub"

        # Move cover.jpg up, renaming to match .epub base name (Bookshelf convention)
        if [ -f "$title_dir/cover.jpg" ]; then
            new_cover="$author_dir/${epub_base}.jpg"
            if [ -e "$new_cover" ]; then
                echo "  cover-conflict : $new_cover already exists, leaving cover.jpg behind"
            else
                DO mv "$title_dir/cover.jpg" "$new_cover"
            fi
        fi

        # Remove the now-empty Title dir (only if empty after the moves)
        DO rmdir "$title_dir" 2>/dev/null
        if [ "$EXECUTE" = "true" ] && [ -d "$title_dir" ]; then
            # Not empty — list what's left
            remaining=$(ls -A "$title_dir")
            if [ -n "$remaining" ]; then
                echo "  leftover in $title_dir : $remaining"
            fi
        fi

        moved=$((moved+1))
    done < <(find "$author_dir" -maxdepth 1 -mindepth 1 -type d)
done < <(find "$ROOT" -maxdepth 1 -mindepth 1 -type d)

echo
echo "===== SUMMARY ====="
echo "Moved books         : $moved"
echo "Removed empty dirs  : $deleted_dirs"
echo "Skipped no-epub     : $skipped_noepub"
echo "Skipped multi       : $skipped_multi"
echo "Skipped conflict    : $skipped_conflict"
REMOTE

# Show summary at the end
tail -10 "$HOME/flatten-output.txt"
echo
echo "(Full per-file log in $HOME/flatten-output.txt — about $(wc -l < "$HOME/flatten-output.txt") lines)"

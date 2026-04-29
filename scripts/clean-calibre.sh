#!/usr/bin/env bash
# Clean Calibre / Calibre-Web artifacts from /volume2/Library/books on the NAS.
#
# Default: DRY RUN. Pass --execute to actually delete.
#
# What we delete:
#   - metadata.opf                    (Calibre primary metadata)
#   - *.opf  (non-metadata.opf)       (Calibre-Web export duplicates)
#   - .calnotes/                      (Calibre notes database)
#   - *.md                            (Calibre-Web note exports)
#   - folder.jpg                      (Calibre folder thumbnail)
#   - *-poster.jpg                    (Calibre poster image)
#   - *.mbp                           (Mobipocket bookmark file)
#
# What we KEEP:
#   - *.epub                          (the actual books)
#   - cover.jpg                       (cover image — used by Jellyfin Bookshelf)
#
# Usage:
#   bash scripts/clean-calibre.sh           # dry run
#   bash scripts/clean-calibre.sh --execute # actually delete

set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

EXECUTE="false"
[ "${1:-}" = "--execute" ] && EXECUTE="true"

echo "Mode: $([ "$EXECUTE" = "true" ] && echo EXECUTE || echo DRY-RUN)"
echo

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" \
     "EXECUTE=$EXECUTE bash -s" > "$HOME/clean-output.txt" 2>&1 <<'REMOTE'
set +e
ROOT=/volume2/Library/books

if [ "$EXECUTE" = "true" ]; then
    DEL="rm -f"
    DEL_DIR="rm -rf"
else
    DEL="echo WOULD-DELETE:"
    DEL_DIR="echo WOULD-DELETE-DIR:"
fi

count_metadata_opf=0
count_other_opf=0
count_md=0
count_folder_jpg=0
count_poster_jpg=0
count_mbp=0

# 1. metadata.opf
while IFS= read -r f; do
    [ -z "$f" ] && continue
    $DEL "$f"
    count_metadata_opf=$((count_metadata_opf+1))
done < <(find "$ROOT" -name 'metadata.opf' -type f)

# 2. other .opf
while IFS= read -r f; do
    [ -z "$f" ] && continue
    $DEL "$f"
    count_other_opf=$((count_other_opf+1))
done < <(find "$ROOT" -name '*.opf' -type f -not -name 'metadata.opf')

# 3. .md note files
while IFS= read -r f; do
    [ -z "$f" ] && continue
    $DEL "$f"
    count_md=$((count_md+1))
done < <(find "$ROOT" -name '*.md' -type f)

# 4. folder.jpg
while IFS= read -r f; do
    [ -z "$f" ] && continue
    $DEL "$f"
    count_folder_jpg=$((count_folder_jpg+1))
done < <(find "$ROOT" -name 'folder.jpg' -type f)

# 5. *-poster.jpg
while IFS= read -r f; do
    [ -z "$f" ] && continue
    $DEL "$f"
    count_poster_jpg=$((count_poster_jpg+1))
done < <(find "$ROOT" -name '*-poster.jpg' -type f)

# 6. *.mbp
while IFS= read -r f; do
    [ -z "$f" ] && continue
    $DEL "$f"
    count_mbp=$((count_mbp+1))
done < <(find "$ROOT" -name '*.mbp' -type f)

# 7. .calnotes directory (only at the root)
if [ -d "$ROOT/.calnotes" ]; then
    $DEL_DIR "$ROOT/.calnotes"
    calnotes_dir="removed"
else
    calnotes_dir="(none)"
fi

echo
echo "===== SUMMARY ====="
echo "metadata.opf  : $count_metadata_opf"
echo "other .opf    : $count_other_opf"
echo "*.md          : $count_md"
echo "folder.jpg    : $count_folder_jpg"
echo "*-poster.jpg  : $count_poster_jpg"
echo "*.mbp         : $count_mbp"
echo ".calnotes/    : $calnotes_dir"
REMOTE

# Show summary at the end of stdout, full output captured
tail -15 "$HOME/clean-output.txt"
echo
echo "(Full per-file list in $HOME/clean-output.txt)"

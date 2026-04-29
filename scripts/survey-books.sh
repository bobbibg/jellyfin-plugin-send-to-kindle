#!/usr/bin/env bash
# Survey the books library on the NAS — count Calibre/Calibre-Web artifacts.
# Read-only. No deletion.
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" 'bash -s' > "$HOME/books-survey.txt" 2>&1 <<'REMOTE'
set +e
ROOT=/volume2/Library/books

echo "===== Total counts ====="
echo "Total .epub files     : $(find "$ROOT" -name '*.epub' -type f | wc -l)"
echo "Total cover.jpg       : $(find "$ROOT" -name 'cover.jpg' -type f | wc -l)"
echo "Total metadata.opf    : $(find "$ROOT" -name 'metadata.opf' -type f | wc -l)"
echo "Total OTHER .opf      : $(find "$ROOT" -name '*.opf' -type f -not -name 'metadata.opf' | wc -l)"
echo "Total .jpg (non-cover): $(find "$ROOT" -name '*.jpg' -type f -not -name 'cover.jpg' | wc -l)"

echo
echo "===== Sample of OTHER .opf filenames (first 5) ====="
find "$ROOT" -name '*.opf' -type f -not -name 'metadata.opf' | head -5

echo
echo "===== Other unexpected file types (first 20) ====="
find "$ROOT" -type f -not -name '*.epub' -not -name 'cover.jpg' -not -name 'metadata.opf' -not -name '*.opf' | head -20

echo
echo "===== Sample metadata.opf head (first one found) ====="
SAMPLE=$(find "$ROOT" -name 'metadata.opf' -type f | head -1)
echo "File: $SAMPLE"
head -30 "$SAMPLE"

echo
echo "===== Total disk usage of metadata files ====="
echo "metadata.opf   : $(find "$ROOT" -name 'metadata.opf' -type f -exec du -bc {} + 2>/dev/null | tail -1 | cut -f1) bytes"
echo "other .opf     : $(find "$ROOT" -name '*.opf' -type f -not -name 'metadata.opf' -exec du -bc {} + 2>/dev/null | tail -1 | cut -f1) bytes"
echo "cover.jpg      : $(find "$ROOT" -name 'cover.jpg' -type f -exec du -bc {} + 2>/dev/null | tail -1 | cut -f1) bytes"
REMOTE

cat "$HOME/books-survey.txt"

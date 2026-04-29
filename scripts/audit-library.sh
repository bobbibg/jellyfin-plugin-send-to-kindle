#!/usr/bin/env bash
# Comprehensive read-only audit of the books + comics libraries.
# Pulls metadata from every EPUB (title, author, ISBN, ASIN) and writes a CSV.
# Surfaces anomalies, duplicates, missing ISBNs, comic structure issues.
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" 'bash -s' > "$HOME/audit.txt" 2>&1 <<'REMOTE'
set +e
BOOKS=/volume2/Library/books
COMICS=/volume2/Library/comics

echo "=========================================="
echo "BOOKS AUDIT"
echo "=========================================="
echo
echo "Total .epub files     : $(find "$BOOKS" -name '*.epub' | wc -l)"
echo "Total .jpg files      : $(find "$BOOKS" -name '*.jpg' | wc -l)"
echo "Total .epub WITHOUT matching .jpg sibling:"
while IFS= read -r e; do
    [ -z "$e" ] && continue
    base="${e%.epub}"
    if [ ! -f "${base}.jpg" ] && [ ! -f "$(dirname "$e")/cover.jpg" ]; then
        echo "  MISSING-COVER: $e"
    fi
done < <(find "$BOOKS" -name '*.epub' -type f)

echo
echo "Author folders count  : $(ls "$BOOKS" | wc -l)"
echo
echo "===== Author folders with only 1 book (potential mis-matches) ====="
for d in "$BOOKS"/*; do
    [ -d "$d" ] || continue
    n=$(find "$d" -name '*.epub' -type f | wc -l)
    if [ "$n" = 1 ]; then
        epub=$(find "$d" -name '*.epub' -type f | head -1)
        echo "  $(basename "$d") :: $(basename "$epub")"
    fi
done

echo
echo "===== Largest books (top 5) ====="
find "$BOOKS" -name '*.epub' -type f -printf "%s\t%p\n" | sort -rn | head -5

echo
echo "===== Smallest books (top 5 — likely placeholders) ====="
find "$BOOKS" -name '*.epub' -type f -printf "%s\t%p\n" | sort -n | head -5

echo
echo "===== EPUB metadata extraction (CSV: relative_path|title|isbn|asin) ====="
echo "RELATIVE_PATH|TITLE|ISBN|ASIN"
while IFS= read -r epub; do
    [ -z "$epub" ] && continue
    rel="${epub#$BOOKS/}"
    opf=$(unzip -p "$epub" '*.opf' 2>/dev/null | head -200)
    [ -z "$opf" ] && opf=$(unzip -p "$epub" 'OEBPS/content.opf' 2>/dev/null)
    title=$(echo "$opf" | grep -oE '<dc:title[^>]*>[^<]+</dc:title>' | head -1 | sed -E 's|<[^>]+>||g')
    isbn=$(echo "$opf" | grep -oE 'opf:scheme="ISBN"[^>]*>[0-9X-]+|isbn[":>][^"<]*[0-9X-]+' | grep -oE '[0-9]{10,13}X?' | head -1)
    asin=$(echo "$opf" | grep -oE '"MOBI-ASIN"[^>]*>[A-Z0-9]+' | grep -oE 'B[A-Z0-9]{9}' | head -1)
    echo "${rel}|${title}|${isbn}|${asin}"
done < <(find "$BOOKS" -name '*.epub' -type f | sort)

echo
echo "=========================================="
echo "COMICS AUDIT"
echo "=========================================="
echo
echo "Top-level entries:"
ls -la "$COMICS" 2>/dev/null

echo
echo "Total .cbz files: $(find "$COMICS" -name '*.cbz' | wc -l)"
echo "Total .cbr files: $(find "$COMICS" -name '*.cbr' | wc -l)"
echo "Total non-comic files at root or sub:"
find "$COMICS" -type f -not -name '*.cbz' -not -name '*.cbr' 2>/dev/null

echo
echo "===== Comic series + issue counts ====="
for d in "$COMICS"/*; do
    [ -d "$d" ] || continue
    n=$(find "$d" -name '*.cbz' -type f | wc -l)
    echo "  $(basename "$d") : $n issues"
done

echo
echo "===== Sample comic filenames (first 5 in 2 series) ====="
for d in $(ls -d "$COMICS"/*/ 2>/dev/null | head -2); do
    echo "--- $d ---"
    ls "$d" 2>/dev/null | head -5
done
REMOTE

cat "$HOME/audit.txt"

#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" 'bash -s' > "$HOME/issues-survey.txt" 2>&1 <<'REMOTE'
set +e
BOOKS=/volume2/Library/books
COMICS=/volume2/Library/comics

echo "===== ALL author folders (sorted) ====="
ls "$BOOKS" | sort

echo
echo "===== Possible duplicate authors (case-insensitive normalized) ====="
ls "$BOOKS" | sed 's/[^a-zA-Z0-9]//g' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | awk '$1 > 1'

echo
echo "===== M. C. Beaton folders ====="
ls "$BOOKS" | grep -i "beaton"
echo
echo "Files in each Beaton folder:"
for d in "$BOOKS"/*[Bb]eaton*; do
    [ -d "$d" ] || continue
    echo "  $d:"
    ls "$d/" 2>/dev/null | head -20 | sed 's/^/    /'
done

echo
echo "===== Rowling folders ====="
ls "$BOOKS" | grep -i "rowling"
echo
for d in "$BOOKS"/*[Rr]owling*; do
    [ -d "$d" ] || continue
    echo "  $d:"
    ls "$d/" 2>/dev/null | sed 's/^/    /'
done

echo
echo "===== Butcher folders ====="
ls "$BOOKS" | grep -i "butcher"
echo
for d in "$BOOKS"/*[Bb]utcher*; do
    [ -d "$d" ] || continue
    echo "  $d:"
    ls "$d/" 2>/dev/null | sed 's/^/    /'
done

echo
echo "===== Bone Season author/files ====="
find "$BOOKS" -iname "*bone*season*" -o -iname "*samantha*shannon*" 2>/dev/null
echo
echo "Samantha Shannon directory tree:"
find "$BOOKS"/Samantha* -maxdepth 2 2>/dev/null | head -20

echo
echo "===== Bone Season EPUB metadata (titles from inside the .epub) ====="
for epub in "$BOOKS"/Samantha*/*.epub; do
    [ -f "$epub" ] || continue
    echo "FILE: $epub"
    # An EPUB is a zip — content.opf has the title
    unzip -p "$epub" '*content.opf' 2>/dev/null \
        | grep -oE '<dc:title[^>]*>[^<]+</dc:title>' \
        | head -1
    echo
done

echo
echo "===== Comics structure ====="
ls "$COMICS" 2>/dev/null | head -10
echo
echo "Sample comic folder content:"
FIRST_COMIC_DIR=$(ls "$COMICS" 2>/dev/null | head -1)
if [ -n "$FIRST_COMIC_DIR" ]; then
    find "$COMICS/$FIRST_COMIC_DIR" -maxdepth 2 -type f 2>/dev/null | head -10
fi
echo
echo "Comic file extension counts:"
find "$COMICS" -type f 2>/dev/null | sed -E 's/.*\.//' | sort | uniq -c | sort -rn | head
REMOTE

cat "$HOME/issues-survey.txt"

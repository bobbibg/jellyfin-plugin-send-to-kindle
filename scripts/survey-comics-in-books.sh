#!/usr/bin/env bash
# Find comic-format .epubs in the books library and cross-reference with comics.
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" 'bash -s' > "$HOME/comics-survey.txt" 2>&1 <<'REMOTE'
set +e
B=/volume2/Library/books
C=/volume2/Library/comics

echo "===== Comic-pattern .epubs in books library ====="
echo "(matching: '#NN' issue numbers, known comic authors, year ranges, omnibuses)"
echo

# Authors who write only comics in this library (whole folder is comics)
COMIC_AUTHORS=("Brian Michael Bendis" "Marjorie Liu")

for author in "${COMIC_AUTHORS[@]}"; do
    echo "--- $B/$author ---"
    ls "$B/$author/" 2>/dev/null
    echo
done

# Specific items
echo "--- Specific known-comic .epubs ---"
ls -la "$B/Brandon Sanderson/White Sand Omnibus.epub" 2>/dev/null
ls -la "$B/Brandon Sanderson/White Sand Omnibus.jpg" 2>/dev/null
echo
ls -la "$B/James S. A. Corey/The Expanse Origins"* 2>/dev/null

echo
echo "===== ALL .epubs with #NN pattern in name (broader sweep) ====="
find "$B" -name '*.epub' | grep -E '#[0-9]+' | head -50

echo
echo "===== ALL .epubs with year-range pattern (eg 2001-2003) ====="
find "$B" -name '*.epub' | grep -E '\([0-9]{4}.*[0-9]{4}\)' | head -30

echo
echo "===== Now what's IN comics library for each known overlap ====="
echo "--- /library/comics/Alias/ ---"
ls "$C/Alias/" 2>/dev/null
echo
echo "--- /library/comics/Han Solo/ ---"
ls "$C/Han Solo/" 2>/dev/null
echo
echo "--- /library/comics/White Sand Omnibus/ ---"
ls "$C/White Sand Omnibus/" 2>/dev/null
echo
echo "--- /library/comics/The Expanse Origins/ ---"
ls "$C/The Expanse Origins/" 2>/dev/null
echo
echo "===== Top-level comics folders ====="
ls "$C"/ | head -30
REMOTE

cat "$HOME/comics-survey.txt"

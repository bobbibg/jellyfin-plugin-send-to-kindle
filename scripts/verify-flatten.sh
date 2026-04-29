#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"

ssh -o BatchMode=yes "$NAS" 'bash -s' <<'REMOTE'
ROOT=/volume2/Library/books
echo "===== Top-level (Author folders only — should be ~150) ====="
ls "$ROOT" | wc -l
echo
echo "===== Sample Author folder (post-flatten) ====="
ls "$ROOT/Adam Kay/" 2>/dev/null
echo
echo "===== Are there any leftover sub-folders inside Author/? ====="
find "$ROOT" -mindepth 2 -type d 2>/dev/null | head -20
echo "(count: $(find "$ROOT" -mindepth 2 -type d 2>/dev/null | wc -l))"
echo
echo "===== Sanity check counts ====="
echo "Total .epub : $(find "$ROOT" -name '*.epub' -type f | wc -l)"
echo "Total .jpg  : $(find "$ROOT" -name '*.jpg' -type f | wc -l)"
REMOTE

echo
echo "===== Triggering Jellyfin library refresh ====="
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
    -X POST \
    -H "Authorization: MediaBrowser Token=\"${API_KEY}\"" \
    "${JF_URL}/Library/Refresh"

#!/usr/bin/env bash
# Verify cleanup, then trigger Jellyfin library refresh.
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
NAS="bobbi@192.168.1.165"

JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"

echo "===== POST-CLEAN survey ====="
ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" 'bash -s' <<'REMOTE'
ROOT=/volume2/Library/books
echo "Total .epub files     : $(find "$ROOT" -name '*.epub' -type f | wc -l)"
echo "Total cover.jpg       : $(find "$ROOT" -name 'cover.jpg' -type f | wc -l)"
echo "Total metadata.opf    : $(find "$ROOT" -name 'metadata.opf' -type f | wc -l)"
echo "Total OTHER .opf      : $(find "$ROOT" -name '*.opf' -type f -not -name 'metadata.opf' | wc -l)"
echo "Total *.md            : $(find "$ROOT" -name '*.md' -type f | wc -l)"
echo "Total folder.jpg      : $(find "$ROOT" -name 'folder.jpg' -type f | wc -l)"
echo "Total *.mbp           : $(find "$ROOT" -name '*.mbp' -type f | wc -l)"
echo ".calnotes/ exists?    : $([ -d "$ROOT/.calnotes" ] && echo yes || echo no)"
echo
echo "===== Sample remaining files in one book folder ====="
ls -la "$(find "$ROOT" -name '*.epub' -type f | head -1 | xargs dirname)" 2>&1
REMOTE

echo
echo "===== Trigger Jellyfin library refresh ====="
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
    -X POST \
    -H "Authorization: MediaBrowser Token=\"${API_KEY}\"" \
    "${JF_URL}/Library/Refresh"

echo
echo "Library scan kicked off. Watch progress at: ${JF_URL}/web/index.html#/dashboard.html"

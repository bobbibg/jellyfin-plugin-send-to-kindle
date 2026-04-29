#!/usr/bin/env bash
# Quick diagnostic for Bobbi's homelab — runs on her PC, SSHes into NAS,
# checks plugin state in Jellyfin and the books folder structure.
set -u

if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then
    source "$HOME/.ssh/load-vault-keys.sh"
fi

NAS="bobbi@192.168.1.165"

# Run everything on the NAS in one ssh command. Capture to local file.
ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$NAS" 'bash -s' <<'REMOTE' > "$HOME/diag-output.txt" 2>&1
set +e

echo "===== JELLYFIN PLUGIN FOLDERS ====="
ls /volume3/Docker/cypherflix/config/jellyfin/plugins 2>/dev/null

echo
echo "===== SendToKindle plugin folder check ====="
find /volume3/Docker/cypherflix/config/jellyfin -maxdepth 4 -iname "*kindle*" 2>/dev/null | head -10

echo
echo "===== Books DIR top level (host filesystem) ====="
ls /volume2/Library/books/ 2>/dev/null | head -10

echo
echo "===== /volume2/Library content ====="
ls /volume2/Library/ 2>/dev/null

echo
echo "===== One Author folder example ====="
FIRST_AUTHOR=$(ls /volume2/Library/books/ 2>/dev/null | grep -v "#recycle" | head -1)
echo "Author: $FIRST_AUTHOR"
ls "/volume2/Library/books/$FIRST_AUTHOR/" 2>/dev/null | head -5

echo
echo "===== One Title folder content ====="
FIRST_TITLE=$(ls "/volume2/Library/books/$FIRST_AUTHOR/" 2>/dev/null | head -1)
echo "Title folder: $FIRST_TITLE"
ls "/volume2/Library/books/$FIRST_AUTHOR/$FIRST_TITLE/" 2>/dev/null

echo
echo "===== Docker access check ====="
groups bobbi
docker ps --format "{{.Names}}" 2>/dev/null | head -5

echo
echo "===== INDEX.HTML INJECTION CHECK (in container) ====="
docker exec Jellyfin grep -c "SendToKindle-Injected" /jellyfin/jellyfin-web/index.html 2>&1 || echo "(docker exec failed)"

echo
echo "===== JF logs on host filesystem ====="
ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1

echo
echo "===== JELLYFIN log tail (SendToKindle / MailKit) ====="
LOG=$(ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1)
if [ -n "$LOG" ]; then
    grep -iE "sendtokindle|kindle|mailkit|mimekit" "$LOG" | tail -40
fi

echo
echo "===== JELLYFIN log generic exceptions last 200 lines ====="
if [ -n "$LOG" ]; then
    tail -2000 "$LOG" | grep -iE "exception|FileNotFound|TypeLoad|Could not load" | tail -15
fi
REMOTE

echo "--- captured locally ---"
cat "$HOME/diag-output.txt"

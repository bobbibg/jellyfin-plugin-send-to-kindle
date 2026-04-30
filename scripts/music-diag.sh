#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi

ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
echo "===== Where is the music actually? ====="
for p in /volume2/Library/music /volume3/Music /volume3/Music/media /volume2/music; do
    echo "--- $p ---"
    ls "$p" 2>/dev/null | head -5
done

echo
echo "===== docker-compose container mount for music ====="
sudo cat /volume3/Docker/cypherflix/docker-compose.yaml 2>/dev/null \
    | grep -E "(music|/data/music)" | head -10

echo
echo "===== /data/music inside container (mount target) ====="
ls /volume3/Music 2>/dev/null | head -10
ls /volume3/Music/media 2>/dev/null | head -10

echo
echo "===== /library mount (audiobooks) ====="
ls /volume2/Library/audiobooks 2>/dev/null | head -5
echo "Audio extensions count if it exists:"
find /volume2/Library/audiobooks -type f 2>/dev/null | sed -E 's/.*\.//' | sort | uniq -c | sort -rn | head -5

echo
echo "===== Audiobooks library config in JF (path it expects) ====="
echo "(see jellyfin libraries via API in main report)"
REMOTE

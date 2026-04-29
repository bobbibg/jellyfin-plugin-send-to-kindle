#!/usr/bin/env bash
set -u
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
WORK=/tmp/stk-inspect
rm -rf "$WORK" && mkdir -p "$WORK"
cd "$WORK"
echo "===== Download ====="
curl -sL -o stk.zip "https://github.com/bobbibg/jellyfin-plugin-send-to-kindle/releases/download/v1.1.0/send-to-kindle_1.1.0.zip"
ls -la stk.zip
echo
echo "===== Contents ====="
unzip -l stk.zip
echo
echo "===== Embedded resources in main DLL (via Python pefile-less peek) ====="
unzip -o stk.zip Jellyfin.Plugin.SendToKindle.dll >/dev/null
python3 -c "
import re
data = open('Jellyfin.Plugin.SendToKindle.dll','rb').read()
# .NET resource names are stored as length-prefixed UTF-8 in the metadata stream
matches = re.findall(rb'[A-Za-z][A-Za-z0-9_.]+\.(?:js|html)', data)
for m in set(matches):
    print(m.decode('latin-1'))
" 2>&1
echo
echo "===== JF log on NAS for Send to Kindle errors ====="
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 \
    'ls -t /volume3/Docker/cypherflix/config/jellyfin/log/log_*.log 2>/dev/null | head -1 | xargs -I {} tail -2000 {} 2>/dev/null | grep -iE "sendtokindle|getscript|kindle" | tail -40'

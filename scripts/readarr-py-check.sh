#!/usr/bin/env bash
if [ -f "$HOME/.ssh/load-vault-keys.sh" ]; then source "$HOME/.ssh/load-vault-keys.sh"; fi
ssh -o BatchMode=yes -o StrictHostKeyChecking=no bobbi@192.168.1.165 'bash -s' <<'REMOTE'
echo "===== Readarr container OS info ====="
sudo docker exec Readarr cat /etc/os-release 2>/dev/null | head -5

echo
echo "===== Python availability ====="
sudo docker exec Readarr which python3 2>/dev/null
sudo docker exec Readarr python3 --version 2>/dev/null
sudo docker exec Readarr which python 2>/dev/null
sudo docker exec Readarr python --version 2>/dev/null

echo
echo "===== Other useful tools ====="
sudo docker exec Readarr which curl 2>/dev/null
sudo docker exec Readarr which jq 2>/dev/null
sudo docker exec Readarr which zip 2>/dev/null
sudo docker exec Readarr which unzip 2>/dev/null
sudo docker exec Readarr which xmllint 2>/dev/null

echo
echo "===== Currently mounted volumes ====="
sudo docker inspect Readarr 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
for m in d[0]['Mounts']:
    print(f\"  {m['Source']}  ->  {m['Destination']}  ({m.get('Mode','rw')})\")
"
REMOTE

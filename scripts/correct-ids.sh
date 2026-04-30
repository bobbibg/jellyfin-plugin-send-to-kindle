#!/usr/bin/env bash
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== Raw VirtualFolders ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for v in data:
    print(f\"Name={v.get('Name'):20} ItemId={v.get('ItemId')} Locations={v.get('Locations')}\")
" 2>/dev/null || curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders"

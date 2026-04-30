#!/usr/bin/env bash
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""
PLUGIN_ID="309ec7e549814e8c992f8e4dde9591e0"

echo "===== Comic Vine plugin configuration ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Plugins/${PLUGIN_ID}/Configuration"
echo

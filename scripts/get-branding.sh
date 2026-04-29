#!/usr/bin/env bash
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== Current branding configuration ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/System/Configuration/branding"
echo

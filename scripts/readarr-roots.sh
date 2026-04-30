#!/usr/bin/env bash
READARR="http://192.168.1.165:7650"
APIKEY="e8db6d80b2514b04bfacc7168bec4478"

echo "===== Current root folders ====="
curl -s -H "X-Api-Key: $APIKEY" "${READARR}/api/v1/rootFolder"

echo
echo "===== Tags ====="
curl -s -H "X-Api-Key: $APIKEY" "${READARR}/api/v1/tag"

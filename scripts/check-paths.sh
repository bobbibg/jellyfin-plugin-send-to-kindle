#!/usr/bin/env bash
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== A few random Books library items + their Path field ====="
curl -s -H "$AUTH_HDR" \
    "${JF_URL}/Items?ParentId=4e985111ed7f570b595204d82adb02f3&Recursive=true&IncludeItemTypes=Book&Limit=5&Fields=Path" \
    | tr '{' '\n' | grep -E '"(Name|Path)":' | head -15

echo
echo "===== Few comics items + Path ====="
curl -s -H "$AUTH_HDR" \
    "${JF_URL}/Items?ParentId=2912d51b5fccd138129c54cce1e8bbc6&Recursive=true&Limit=5&Fields=Path" \
    | tr '{' '\n' | grep -E '"(Name|Path)":' | head -15

echo
echo "===== Library locations from VirtualFolders ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" \
    | tr ',' '\n' \
    | grep -E '"(Name|Locations)":' | head -20

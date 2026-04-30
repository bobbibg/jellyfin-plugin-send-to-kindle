#!/usr/bin/env bash
# Show metadata fetcher order for the Books library, so we can see whether
# OpenLibrary is overriding embedded EPUB metadata.
JF_URL="http://192.168.1.165:7900"
API_KEY="07a2b386e14d4e74b18d06988ad3544f"
AUTH_HDR="Authorization: MediaBrowser Token=\"${API_KEY}\""

echo "===== VirtualFolders (full JSON) ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Library/VirtualFolders" \
    | tr ',' '\n' \
    | grep -E '"(Name|CollectionType|ItemId|MetadataFetchers|MetadataFetcherOrder|MetadataFetcherOrder|EnabledMetadataReaders|EnabledMetadataSavers|MetadataReaderOrder)"' \
    | head -50

echo
echo "===== Comic Vine plugin config ====="
curl -s -H "$AUTH_HDR" "${JF_URL}/Plugins" \
    | tr '{' '\n' | grep -i 'comic\|vine'

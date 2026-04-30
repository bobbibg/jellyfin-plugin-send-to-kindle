#!/usr/bin/env bash
READARR="http://192.168.1.165:7650"
APIKEY="e8db6d80b2514b04bfacc7168bec4478"

echo "===== Author count + sample paths ====="
curl -s -H "X-Api-Key: $APIKEY" "${READARR}/api/v1/author" \
    | python3 -c "
import json, sys
authors = json.load(sys.stdin)
print(f'Total authors: {len(authors)}')
print()
print('First 10 author paths:')
for a in authors[:10]:
    print(f\"  {a.get('authorName',''):30} :: path={a.get('path','')}\")
print()
print('Path prefix counts:')
from collections import Counter
prefixes = Counter()
for a in authors:
    p = a.get('path', '')
    if p.startswith('/library/'):
        prefixes['/library/*'] += 1
    elif p.startswith('/data/'):
        prefixes['/data/*'] += 1
    else:
        prefixes['other'] += 1
for k, v in prefixes.items():
    print(f'  {k}: {v}')
"

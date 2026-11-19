"""Read-only verification of the completed publisher-library migration.

The owner requested deletion of all project media backups. This historical tool
name is retained for compatibility; it no longer uploads or requires local media.
"""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import certifi
import time
import requests

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'docs/verification/2026-11-19/cloud-library'
OUTPUT.mkdir(parents=True, exist_ok=True)
CONFIG = json.loads((ROOT / 'config/app.json').read_text())
BASE = CONFIG['SUPABASE_URL'].rstrip('/')
BUCKET = 'dance-library'
PREFIX = f'{BASE}/storage/v1/object/public/{BUCKET}/v1/'


def request(url, *, data=None, headers=None, method=None):
    for attempt in range(3):
        try:
            response = requests.request(method or ('POST' if data is not None else 'GET'),
                url, data=data, headers=headers or {}, timeout=(15, 60), allow_redirects=False,
                verify=certifi.where())
            if response.status_code in [429, 500, 502, 503, 504] and attempt < 2:
                time.sleep(1 + attempt)
                continue
            return response.status_code, response.headers, response.content
        except requests.RequestException:
            if attempt == 2:
                raise RuntimeError('The publisher transfer connection was interrupted; rerun to resume safely.') from None
            time.sleep(1 + attempt)


def main():
    catalog = json.loads((ROOT / 'assets/data/media_library.json').read_text())
    assert catalog['version'] == 2
    resources = catalog['resources']

    def verify_one(key):
        entry = resources[key]
        status, headers, data = request(entry['url'])
        assert status == 200 and len(data) == entry['bytes'], key
        assert hashlib.sha256(data).hexdigest() == entry['sha256'], key
        assert headers.get('Content-Type', '').split(';')[0] == entry['content_type'], key
        result = {'key': key, **entry, 'public_get': status, 'sha256_matches': True}
        if entry['content_type'] == 'video/mp4':
            status, range_headers, chunk = request(entry['url'], headers={'Range': 'bytes=0-1023'})
            assert status == 206 and chunk == data[:1024], key
            assert range_headers.get('Content-Range', '').endswith('/' + str(len(data))), key
            result['byte_range'] = 'passed'
        return result

    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(verify_one, sorted(resources)))
    result = {'objects': len(results), 'bytes': sum(item['bytes'] for item in results),
              'operation': 'read-only public cloud verification; no local backup required',
              'objects_detail': results}
    (OUTPUT / 'remote-reverification.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'verified_objects': len(results), 'verified_bytes': result['bytes']}))


if __name__ == '__main__':
    main()

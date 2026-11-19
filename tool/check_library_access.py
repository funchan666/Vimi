"""Check that clients can read, but cannot add publisher-library objects."""
import json
from pathlib import Path
from migrate_library_to_cloud import BASE, CONFIG, OUTPUT, request


def main():
    data = (Path(__file__).resolve().parents[1] / 'assets/ui/neon-mark.webp').read_bytes()
    endpoint = BASE + '/storage/v1/object/dance-library/v1/covers/qa-write-denied.webp'
    headers = {'apikey': CONFIG['SUPABASE_PUBLISHABLE_KEY'], 'Content-Type': 'image/webp'}
    result = {}
    status, _, _ = request(endpoint, data=data, headers=headers)
    assert status in (400, 401, 403), 'Anonymous upload unexpectedly accepted'
    result['anonymous_insert_denied'] = status
    root = Path(__file__).resolve().parents[1]
    for role, filename in [('ordinary_member', 'play-review-access.json'), ('content_operator', 'reviewer-access.json')]:
        credentials = json.loads((root / 'config' / filename).read_text())
        status, _, body = request(BASE + '/auth/v1/token?grant_type=password',
            data=json.dumps({'email': credentials['email'], 'password': credentials['password']}).encode(),
            headers={'apikey': CONFIG['SUPABASE_PUBLISHABLE_KEY'], 'Content-Type': 'application/json'})
        assert status == 200
        user = json.loads(body)
        assert (user['user']['app_metadata'].get('vimi_role') == 'moderator') == (role == 'content_operator')
        token = user['access_token']
        try:
            status, _, body = request(endpoint, data=data, headers={**headers, 'Authorization': 'Bearer ' + token})
            assert status in (400, 401, 403) and b'row-level security' in body.lower(), role + ' upload unexpectedly accepted'
            result[role + '_insert_denied'] = status
        finally:
            request(BASE + '/auth/v1/logout?scope=local', data=b'',
                headers={'apikey': CONFIG['SUPABASE_PUBLISHABLE_KEY'], 'Authorization': 'Bearer ' + token})
    (OUTPUT / 'access-verification.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()

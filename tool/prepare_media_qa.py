"""Create one isolated, disposable account for the native supplied-media journey."""
import json
import os
from pathlib import Path
import secrets
import ssl
import time
import urllib.request
import certifi

root = Path(__file__).resolve().parents[1]
destination = root / 'config/qa-media.json'
if destination.exists():
    raise SystemExit('Reuse or clean the recorded media QA actor first.')
config = json.loads((root / 'config/app.json').read_text())
email = f'vimi-qa-direct-media-{int(time.time())}@example.invalid'
password = secrets.token_urlsafe(28) + 'a9!'
request = urllib.request.Request(
    config['SUPABASE_URL'] + '/auth/v1/signup',
    data=json.dumps({'email': email, 'password': password, 'data': {
        'birth_date': '2000-01-01', 'display_name': 'Supplied Media QA',
        'consent_version': '2026-11-18'}}).encode(),
    headers={'apikey': config['SUPABASE_PUBLISHABLE_KEY'],
             'Content-Type': 'application/json'})
with urllib.request.urlopen(request, timeout=30,
        context=ssl.create_default_context(cafile=certifi.where())) as response:
    data = json.load(response)
assert data.get('access_token') and data['user']['email'] == email
config.update(QA_EMAIL_C=email, QA_PASSWORD_C=password, QA_USER_C=data['user']['id'])
with os.fdopen(os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'w') as stream:
    json.dump(config, stream)
print('One labelled media QA actor created; private configuration stored mode 0600. Cleanup is required.')

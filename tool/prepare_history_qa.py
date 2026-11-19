"""Create labelled, disposable Auth fixtures. Never use member accounts here.

Stores credentials only in ignored config/qa-history.json (mode 0600).
The companion history QA suite and cleanup must remove these accounts afterward.
"""
import json
import certifi
import ssl
import os
from pathlib import Path
import secrets
import time
import urllib.request

root = Path(__file__).resolve().parents[1]
config = json.loads((root / 'config/app.json').read_text())
reviewer = json.loads((root / 'config/reviewer-access.json').read_text())
destination = root / 'config/qa-history.json'
if destination.exists():
    raise SystemExit('QA config already exists. Reuse or clean those fixtures before creating more.')
run_id = str(int(time.time()))
config['QA_HISTORY_RUN'] = run_id
for letter in ['A', 'B']:
    password = secrets.token_urlsafe(26) + 'a9!'
    email = f'vimi-qa-{letter.lower()}-history-{run_id}@example.invalid'
    request = urllib.request.Request(config['SUPABASE_URL'] + '/auth/v1/signup',
        data=json.dumps({'email': email, 'password': password, 'data': {
            'birth_date': '2000-01-01', 'display_name': f'History QA {letter}',
            'consent_version': '2026-11-18'}}).encode(),
        headers={'apikey': config['SUPABASE_PUBLISHABLE_KEY'], 'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=30, context=ssl.create_default_context(cafile=certifi.where())) as response:
        data = json.load(response)
    if not data.get('access_token'):
        raise SystemExit('Immediate signup did not produce a session. Check the Auth configuration.')
    config.update({f'QA_EMAIL_{letter}': email, f'QA_PASSWORD_{letter}': password,
                   f'QA_USER_{letter}': data['user']['id']})
    # Persist each successful account so interrupted preparation remains cleanable.
    with os.fdopen(os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), 'w') as stream:
        json.dump(config, stream)
config.update({'QA_REVIEWER_EMAIL': reviewer['email'], 'QA_REVIEWER_PASSWORD': reviewer['password'],
               'QA_HISTORY_RUN': run_id})
with os.fdopen(os.open(destination, os.O_WRONLY | os.O_TRUNC, 0o600), 'w') as stream:
    json.dump(config, stream)
print(json.dumps({'accounts_created': 2, 'run': run_id,
    'user_a': config['QA_USER_A'], 'user_b': config['QA_USER_B']}))

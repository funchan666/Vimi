"""Inspect a main-entrypoint APK against the actual private QA/operator values."""
import hashlib
import json
from pathlib import Path
import zipfile

root=Path(__file__).resolve().parents[1]
apk=root/'dist/Vimi-1.0.0-arm64-preview.apk'
operator=json.loads((root/'config/reviewer-access.json').read_text())
qa_files=sorted((root/'config').glob('qa-*.json'))
qa_secrets={str(value) for file in qa_files for key,value in json.loads(file.read_text()).items()
            if 'password' in key.lower() and value}
review_access=root/'config/play-review-access.json'
secrets=({json.loads(review_access.read_text())['password']} if review_access.exists() else set())|{operator['password']}|qa_secrets
assert len(secrets)>=2,'Actual retained operator and ordinary review credentials are required'
needles=[secret.encode(encoding) for secret in secrets for encoding in ['utf-8','utf-16-le','utf-16-be']]
with zipfile.ZipFile(apk) as package:
    names=package.namelist()
    assert 'lib/arm64-v8a/libapp.so' in names
    assert not any('qa-history' in name or 'qa-media' in name or 'reviewer-access' in name or 'play-review-access' in name or 'rehearsal-sample' in name for name in names)
    for name in names:
        data=package.read(name)
        assert not any(secret in data for secret in needles),'Private credential found in '+name
        assert b'History QA' not in data and b'Supplied Media QA' not in data and b'QA_PASSWORD_' not in data,'QA target found in '+name
result={'file':str(apk.relative_to(root)),'mode':'profile','signing':'local debug key; preview only',
        'bytes':apk.stat().st_size,'sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),
        'qa_credentials_present':False,'private_configs_present':False,'qa_fixture_labels_present':False,
        'actual_distinct_passwords_checked':len(secrets),'arm64':True}
(root/'docs/verification/2026-11-19/preview-artifact.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))

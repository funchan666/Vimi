"""Read-only release readiness checks; never submits a form or uploads an app."""
import argparse,json,ssl,urllib.request,urllib.error
from pathlib import Path
from urllib.parse import urlparse
import certifi
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--check-public-urls',action='store_true');args=parser.parse_args()
c=json.loads((root/'config/app.json').read_text());blockers=[];urls={}
for key,phrase in [('PRIVACY_URL','privacy'),('TERMS_URL','terms'),('CHILD_SAFETY_URL','child'),('DELETE_ACCOUNT_URL','delet')]:
    value=c.get(key,'');uri=urlparse(value)
    if uri.scheme!='https' or not uri.hostname or uri.hostname in ['example.com','localhost'] or uri.hostname.endswith('.invalid'):
        blockers.append(key+' is missing or not a real HTTPS URL');continue
    if args.check_public_urls:
        try:
            req=urllib.request.Request(value,headers={'User-Agent':'Vimi-Policy-Readiness/1.0'})
            with urllib.request.urlopen(req,context=ssl.create_default_context(cafile=certifi.where()),timeout=25) as response:
                content=response.read(200000).decode('utf-8');kind=response.headers.get('Content-Type','');disposition=response.headers.get('Content-Disposition','')
                valid=response.status==200 and 'text/html' in kind and 'attachment' not in disposition.lower() and 'vimi' in content.lower() and phrase in content.lower()
                if not valid:blockers.append(key+' did not return a readable Vimi HTML policy')
                urls[key]={'status':response.status,'html': 'text/html' in kind,'valid':valid}
        except (urllib.error.URLError,ValueError):blockers.append(key+' could not be read without authentication')
for key in ['SUPPORT_EMAIL','CHILD_SAFETY_EMAIL']:
    if '@' not in c.get(key,''):blockers.append(key+' is missing')
if not (root/'android/key.properties').is_file():blockers.append('Publisher upload signing is not configured')
if any('SERVICE_ROLE' in key or 'SERVICE_ACCOUNT' in key for key in c) or any(isinstance(value,str) and value.startswith('sb_secret_') for value in c.values()):
    blockers.append('Server-only secrets were found in client configuration')
report={'automated_configuration_ready':not blockers,'blockers':blockers,'public_urls':urls,
        'manual_release_requirements':['Real developer identity and package registration','Data safety and IARC declarations match the submitted build','Named child-safety contact and actual response/reporting process','Ordinary reusable Play review login and full access instructions','Production recovery email delivery','Release AAB and final Play pre-launch report'],
        'google_approval_guaranteed':False}
(root/'docs/verification/2026-11-19/play-release-readiness.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))

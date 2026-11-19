"""Delete only the two labelled QA actors through the genuine deletion API.
Keep private config until the remaining labelled SQL fixtures and APK scans are complete.
"""
import json
from pathlib import Path
import ssl
import urllib.request
import certifi

root=Path(__file__).resolve().parents[1]
c=json.loads((root/'config/qa-history.json').read_text())
ctx=ssl.create_default_context(cafile=certifi.where())
def request(path,body,token=None):
    req=urllib.request.Request(c['SUPABASE_URL']+path,data=json.dumps(body).encode(),headers={
        'apikey':c['SUPABASE_PUBLISHABLE_KEY'],'Content-Type':'application/json',
        'Authorization':'Bearer '+(token or c['SUPABASE_PUBLISHABLE_KEY'])})
    with urllib.request.urlopen(req,context=ctx,timeout=60) as response:return json.load(response)
results={}
for letter in ['B','A']:
    if 'QA_EMAIL_'+letter not in c or c.get('QA_DELETED_'+letter) is True:
        continue
    email=c['QA_EMAIL_'+letter]
    assert email.startswith('vimi-qa-'+letter.lower()+'-') and email.endswith('@example.invalid')
    auth=request('/auth/v1/token?grant_type=password',{'email':email,'password':c['QA_PASSWORD_'+letter]})
    assert auth['user']['id']==c['QA_USER_'+letter]
    response=request('/functions/v1/delete-account',{'confirm_user_id':c['QA_USER_'+letter]},auth['access_token'])
    assert response.get('deleted') is True,'Deletion did not confirm completion'
    results[letter]='deleted via authenticated function'
(root/'docs/verification/2026-11-19/history-cleanup.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results))

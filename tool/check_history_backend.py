"""Read-only Edge Function acceptance against labelled disposable QA accounts."""
import json
from pathlib import Path
import ssl
import urllib.error
import urllib.request
import certifi

root=Path(__file__).resolve().parents[1]
c=json.loads((root/'config/qa-history.json').read_text())
assert c['QA_EMAIL_A'].startswith('vimi-qa-a-') and c['QA_EMAIL_A'].endswith('@example.invalid')
ctx=ssl.create_default_context(cafile=certifi.where())
def request(path,body,token=None):
    headers={'apikey':c['SUPABASE_PUBLISHABLE_KEY'],'Content-Type':'application/json'}
    if token: headers['Authorization']='Bearer '+token
    req=urllib.request.Request(c['SUPABASE_URL']+path,data=json.dumps(body).encode(),headers=headers)
    try:
        with urllib.request.urlopen(req,context=ctx,timeout=40) as response:return response.status,json.load(response)
    except urllib.error.HTTPError as error:
        return error.code,json.load(error)
def login(email,password):
    status,data=request('/auth/v1/token?grant_type=password',{'email':email,'password':password})
    assert status==200,'QA sign-in failed'
    return data['access_token']
a=login(c['QA_EMAIL_A'],c['QA_PASSWORD_A'])
reviewer=login(c['QA_REVIEWER_EMAIL'],c['QA_REVIEWER_PASSWORD'])
path='/functions/v1/moderate-content'
assert request(path,{'action':'queue','section':'comments'})[0]==401
assert request(path,{'action':'queue','section':'comments'},a)[0]==403
assert request(path,{'action':'queue','section':'invalid'},reviewer)[0]==400
assert request(path,{'action':'queue','section':'comments','after_id':'bad','after_created':'2026-11-19T00:00:00.123456Z'},reviewer)[0]==400
results={'guest_denied':True,'member_denied':True,'invalid_section_denied':True,'invalid_cursor_denied':True}
for section,expected in [('comments',35),('reports',31)]:
    body={'action':'queue','section':section}; seen=[]; cursors=[]
    while True:
        status,data=request(path,body,reviewer)
        assert status==200,'Queue could not be read'
        items=data['items']; visible=items[:25]
        for row in visible:
            assert row['id'] not in seen,'Queue duplicated an item'
            seen.append(row['id'])
        if len(items)<=25: break
        last=visible[-1]
        cursor=last['created_at'].replace('+00:00','Z')
        body.update({'after_id':last['id'],'after_created':cursor})
        cursors.append(cursor)
    assert len(seen)==expected,section+' count does not match labelled fixtures'
    results[section]={'items':len(seen),'stable_unique_ids':True,'cursor_fractional_seconds':cursors}
destination=root/'docs/verification/2026-11-19/history-edge-checks.json'
destination.write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results))

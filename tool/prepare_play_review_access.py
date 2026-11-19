"""Create one ordinary, reusable Play access account without moderator privileges."""
import json,os,secrets,ssl,urllib.request
from pathlib import Path
import certifi
root=Path(__file__).resolve().parents[1];path=root/'config/play-review-access.json'
if path.exists():raise SystemExit('Review credentials already exist; preserve and reuse them.')
c=json.loads((root/'config/app.json').read_text());email='app-review@vimi.invalid';password=secrets.token_urlsafe(28)+'a9!'
ctx=ssl.create_default_context(cafile=certifi.where())
req=urllib.request.Request(c['SUPABASE_URL']+'/auth/v1/signup',data=json.dumps({'email':email,'password':password,
 'data':{'birth_date':'1990-01-01','display_name':'Vimi App Review','consent_version':'2026-11-18'}}).encode(),
 headers={'apikey':c['SUPABASE_PUBLISHABLE_KEY'],'Content-Type':'application/json'})
with urllib.request.urlopen(req,context=ctx,timeout=30) as response:data=json.load(response)
assert data.get('access_token') and data['user']['app_metadata'].get('vimi_role')!='moderator'
with os.fdopen(os.open(path,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600),'w') as stream:
 json.dump({'email':email,'password':password,'user_id':data['user']['id'],'purpose':'Ordinary reusable Google Play App access account; no moderator privileges or special feature behavior.'},stream,indent=2)
print(json.dumps({'ordinary_review_account_created':True,'moderator':False,'credential_file':'config/play-review-access.json'}))

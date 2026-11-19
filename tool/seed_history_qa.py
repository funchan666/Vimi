"""Prepare owned Storage files and SQL for the disposable history acceptance run.
The SQL is deliberately saved for the connected project's explicit migration/query tool.
"""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import ssl
import urllib.request
import certifi

root = Path(__file__).resolve().parents[1]
config_path = root / 'config/qa-history.json'
c = json.loads(config_path.read_text())
assert c['QA_EMAIL_A'].startswith('vimi-qa-a-') and c['QA_EMAIL_B'].endswith('@example.invalid')
ctx = ssl.create_default_context(cafile=certifi.where())
def request(path, body, token=None, mime='application/json'):
    req = urllib.request.Request(c['SUPABASE_URL']+path, data=body,
        headers={'apikey': c['SUPABASE_PUBLISHABLE_KEY'], 'Authorization': 'Bearer '+(token or c['SUPABASE_PUBLISHABLE_KEY']), 'Content-Type': mime})
    with urllib.request.urlopen(req, timeout=40, context=ctx) as response:
        return json.load(response)
auth = request('/auth/v1/token?grant_type=password', json.dumps({'email': c['QA_EMAIL_B'], 'password': c['QA_PASSWORD_B']}).encode())
run = c['QA_HISTORY_RUN']; a=c['QA_USER_A']; b=c['QA_USER_B']
image = (root/'assets/ui/neon-floor.webp').read_bytes()
paths = [f'{b}/posts/history-{run}-{i}.webp' for i in range(41)]
def upload(path):
    request('/storage/v1/object/dance-media/'+path, image, auth['access_token'], 'image/webp')
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    list(pool.map(upload, paths))
video_path = f'{b}/posts/history-{run}-decoder.mp4'
request('/storage/v1/object/dance-media/'+video_path,
    (root/'test/fixtures/rehearsal-sample.mp4').read_bytes(), auth['access_token'], 'video/mp4')
c['QA_VIDEO'] = video_path
def uid(label):
    x=hashlib.md5(f'{run}-{label}'.encode()).hexdigest()
    return f'{x[:8]}-{x[8:12]}-{x[12:16]}-{x[16:20]}-{x[20:]}'
def q(value): return "'"+value.replace("'","''")+"'"
sql=['begin;']
for i in range(31):
    sql.append(f"insert into auth.users(id,email,raw_user_meta_data) values ({q(uid('person'+str(i)))},'vimi-qa-history-{run}-{i}@example.invalid','{{\"birth_date\":\"2000-01-01\",\"display_name\":\"History QA Dancer {i:02}\",\"consent_version\":\"2026-11-18\"}}');")
for peer in [b]+[uid('person'+str(i)) for i in range(31)]:
    sql.append(f"insert into public.follows(follower_id,following_id) values ('{a}','{peer}'),('{peer}','{a}');")
for i,path in enumerate(paths):
    sql.append(f"insert into public.posts(id,author_id,caption,style,media_path,media_kind,status,client_id,created_at) values ('{uid('post'+str(i))}','{b}','History QA original photo {i:02}','K-pop','{path}','image','approved',gen_random_uuid(),timestamptz '2026-11-18 06:00:00.123456+00');")
for i in range(31):
    sql.append(f"insert into public.messages(sender_id,recipient_id,body,client_id,created_at) values ('{uid('person'+str(i))}','{a}','History QA inbox conversation',gen_random_uuid(),timestamptz '2026-11-18 05:00:00.123456+00');")
post=uid('post0')
for i in range(61):
    sql.append(f"insert into public.comments(post_id,author_id,body,status,client_id,created_at) values ('{post}','{b}','History QA approved comment {i:02}','approved',gen_random_uuid(),timestamptz '2026-11-18 06:00:00.123456+00');")
for i in range(35):
    sql.append(f"insert into public.comments(post_id,author_id,body,status,client_id,created_at) values ('{post}','{b}','History QA pending review {i:02}','pending',gen_random_uuid(),timestamptz '2026-11-18 06:00:00.123456+00');")
for i in range(127):
    sql.append(f"insert into public.messages(sender_id,recipient_id,body,client_id,created_at) values ('{a if i%2 else b}','{b if i%2 else a}','History chat {i:03}',gen_random_uuid(),timestamptz '2026-11-18 06:00:00.123456+00'+interval '{i} seconds');")
for i in range(31):
    sql.append(f"insert into public.reports(reporter_id,target_type,target_id,reason) values ('{a}','post','{uid('absent'+str(i))}','Other');")
    sql.append(f"insert into public.wallet_ledger(user_id,delta,description,reference) values ('{a}',0,'History QA zero-value audit {i:02}','history-qa-{run}-{i}');")
sql+=['commit;',"select 'History QA fixtures prepared' result;"]
(root/'config/qa-history-seed.sql').write_text('\n'.join(sql))
c['QA_POST']=post
with os.fdopen(os.open(config_path,os.O_WRONLY|os.O_TRUNC,0o600),'w') as stream: json.dump(c,stream)
print(json.dumps({'uploaded_files':len(paths)+1,'seed_sql':'config/qa-history-seed.sql','profiles':31,'posts':41,'comments':96,'messages':127,'reports':31,'zero_value_audit_rows':31}))

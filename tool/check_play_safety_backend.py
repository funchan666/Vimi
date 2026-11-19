"""Exercise safety removal with harmless, clearly labelled disposable QA content."""
import json,os,ssl,urllib.request,urllib.error,uuid
from pathlib import Path
import certifi
root=Path(__file__).resolve().parents[1];path=root/'config/qa-history.json';c=json.loads(path.read_text())
assert c['QA_EMAIL_A'].startswith('vimi-qa-a-') and c['QA_EMAIL_B'].endswith('@example.invalid')
ctx=ssl.create_default_context(cafile=certifi.where())
def request(route,body=None,token=None,mime='application/json',method='POST'):
    payload=json.dumps(body).encode() if mime=='application/json' and body is not None else body
    req=urllib.request.Request(c['SUPABASE_URL']+route,data=payload,method=method,headers={
        'apikey':c['SUPABASE_PUBLISHABLE_KEY'],'Authorization':'Bearer '+(token or c['SUPABASE_PUBLISHABLE_KEY']),'Content-Type':mime})
    try:
        with urllib.request.urlopen(req,context=ctx,timeout=40) as response:
            raw=response.read();return response.status,json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:return error.code,None
    except urllib.error.URLError:raise RuntimeError('QA network request failed') from None
def login(letter):
    code,data=request('/auth/v1/token?grant_type=password',{'email':c['QA_EMAIL_'+letter],'password':c['QA_PASSWORD_'+letter]})
    assert code==200,'QA login failed';return data['access_token']
def rpc(name,body,token):
    code,data=request('/rest/v1/rpc/'+name,body,token);assert code in (200,204),name+' did not succeed';return data
def review(kind,ident,status):
    code,data=request('/functions/v1/moderate-content',{'kind':kind,'id':ident,'status':status},reviewer)
    assert code==200 and data.get('updated'), 'Review action failed: '+kind+'/'+status

a=login('A');b=login('B');code,admin=request('/auth/v1/token?grant_type=password',{'email':c['QA_REVIEWER_EMAIL'],'password':c['QA_REVIEWER_PASSWORD']});assert code==200
reviewer=admin['access_token'];aid=c['QA_USER_A'];bid=c['QA_USER_B']
photo=(root/'assets/ui/neon-floor.webp').read_bytes();run=c['QA_HISTORY_RUN']
post_path=bid+'/posts/play-safety-'+run+'.webp';avatar=aid+'/avatar/play-safety-'+run+'.webp'
for media,token in [(post_path,b),(avatar,a)]:
    assert request('/storage/v1/object/dance-media/'+media,photo,token,'image/webp')[0] in (200,201),'Owned fixture upload failed'
rpc('update_dancer',{'p_name':'Safety QA A','p_bio':'Harmless safety test profile','p_styles':['K-pop'],'p_avatar':avatar},a)
post=rpc('submit_post',{'p_caption':'Harmless original QA photo for safety workflow acceptance','p_style':'K-pop','p_media_path':post_path,'p_kind':'image','p_client_id':str(uuid.uuid4()),'p_challenge':None},b)
review('post',post,'approved')
rpc('submit_comment',{'p_post':post,'p_body':'Harmless QA comment','p_client_id':str(uuid.uuid4())},a)
code,comments=request('/rest/v1/comments?select=id&post_id=eq.'+post,token=a,method='GET');assert code==200 and len(comments)==1
comment=comments[0]['id']
rpc('set_follow',{'p_peer':bid,'p_followed':True},a);rpc('set_follow',{'p_peer':aid,'p_followed':True},b)
message=rpc('send_message',{'p_peer':aid,'p_body':'Harmless QA safety-control test message','p_client_id':str(uuid.uuid4())},b)
for kind,ident,token in [('post',post,a),('user',aid,b),('message',message,a)]:rpc('report_content',{'p_type':kind,'p_target':ident,'p_reason':'Child safety'},token)
c['QA_SAFETY_TARGETS']=[post,comment,message,aid]
with os.fdopen(os.open(path,os.O_WRONLY|os.O_TRUNC,0o600),'w') as f:json.dump(c,f)
assert request('/functions/v1/moderate-content',{'kind':'post','id':post,'status':'removed'},a)[0]==403,'Member gained moderation access'
assert request('/rest/v1/rpc/remove_moderated_content',{'p_actor':aid,'p_kind':'post','p_target':post},a)[0] in (401,403),'Member gained service RPC access'
code,queue=request('/functions/v1/moderate-content',{'action':'queue','section':'reports','child_safety_only':True},reviewer)
assert code==200 and len(queue['items'])==3,'Child safety queue failed'
profile=next(row['target'] for row in queue['items'] if row['target_type']=='user')
assert profile['avatar_path']==avatar and profile.get('review_url'),'Avatar not inspectable by reviewer'
for kind,ident in [('message',message),('message',message),('comment',comment),('post',post),('user',aid)]:review(kind,ident,'removed')
assert rpc('get_post',{'p_id':post},b) is None,'Removed post remains visible'
assert rpc('get_thread_page',{'p_peer':bid},a)==[],'Removed message remains visible'
profile=rpc('get_dancer',{'p_id':aid},a)
assert profile['display_name']=='Dancer' and profile['avatar_path'] is None and profile['bio']=='','Profile reset incomplete'
for prefix,token in [(aid+'/avatar',a),(bid+'/posts',b)]:
    code,files=request('/storage/v1/object/list/dance-media',{'prefix':prefix,'limit':100,'offset':0},token)
    assert code==200 and not files,'Removed media objects remain in Storage'
review('user',aid,'suspended')
results={'ordinary_member_moderation_denied':True,'service_rpc_denied':True,'child_safety_reports_and_filter':True,
 'reported_avatar_review_url':True,'permanent_post_comment_message_removal':True,'repeat_removal_idempotent':True,
 'profile_text_and_avatar_cleared':True,'uploaded_media_physically_removed':True,'account_suspension':True,
 'fixture_notice':'Harmless original QA content only; no illegal or child content used.'}
(root/'docs/verification/2026-11-19/play-safety-backend.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results))

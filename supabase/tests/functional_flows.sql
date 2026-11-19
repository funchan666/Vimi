-- Hosted/local contract test. Every fixture and financial entry is rolled back.
begin;
create function pg_temp.qa_check(ok boolean, label text) returns void
language plpgsql as $$begin if not coalesce(ok,false) then raise exception 'QA_FAIL: %',label; end if; end;$$;
do $$begin execute format('grant usage on schema %I to authenticated,service_role',pg_my_temp_schema()::regnamespace::text); end;$$;
grant execute on function pg_temp.qa_check(boolean,text) to authenticated,service_role;

-- Missing consent must fail even when the field is JSON null or absent.
do $$begin
  begin
    insert into auth.users(id,email,raw_user_meta_data) values
      ('d4444444-4444-4444-8444-444444444419','vimi-consent-qa@example.invalid',
       '{"birth_date":"2000-01-01","display_name":"Consent QA"}'::jsonb);
    raise exception using errcode='XX000',message='QA_FAIL: missing consent accepted';
  exception when raise_exception then null; end;
end;$$;

insert into auth.users(id,email,raw_user_meta_data) values
 ('a1111111-1111-4111-8111-111111111119','vimi-a-qa@example.invalid','{"birth_date":"2000-01-01","display_name":"Vimi A QA","consent_version":"2026-11-18"}'),
 ('b2222222-2222-4222-8222-222222222219','vimi-b-qa@example.invalid','{"birth_date":"2000-01-01","display_name":"Vimi B QA","consent_version":"2026-11-18"}'),
 ('c3333333-3333-4333-8333-333333333319','vimi-c-qa@example.invalid','{"birth_date":"2000-01-01","display_name":"Vimi C QA","consent_version":"2026-11-18"}');
insert into storage.objects(bucket_id,name,owner_id) values
 ('dance-media','a1111111-1111-4111-8111-111111111119/posts/functional.jpg','a1111111-1111-4111-8111-111111111119');

set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-4111-8111-111111111119","role":"authenticated"}';
select pg_temp.qa_check(public.account_status()='active','adult provisioned');
select pg_temp.qa_check((select balance=0 from public.wallets),'wallet starts at zero');
select public.set_follow('b2222222-2222-4222-8222-222222222219',true);
select public.set_follow('b2222222-2222-4222-8222-222222222219',true);
select pg_temp.qa_check((select count(*)=1 from public.follows where follower_id=auth.uid()),'follow retries idempotent');
select pg_temp.qa_check(not public.can_message('b2222222-2222-4222-8222-222222222219'),'one-way follow cannot message');
select set_config('qa.post_id',public.submit_post('An original QA cover','K-pop',
 'a1111111-1111-4111-8111-111111111119/posts/functional.jpg','image','e5555555-5555-4555-8555-555555555519',null)::text,true);
select pg_temp.qa_check(public.submit_post('Retry','K-pop',
 'a1111111-1111-4111-8111-111111111119/posts/functional.jpg','image','e5555555-5555-4555-8555-555555555519',null)::text=current_setting('qa.post_id'),'publish retry keeps one post');
select pg_temp.qa_check(not private.can_remove_media('a1111111-1111-4111-8111-111111111119/posts/functional.jpg'),'submitted media protected from draft discard');

set local request.jwt.claims = '{"sub":"b2222222-2222-4222-8222-222222222219","role":"authenticated"}';
select pg_temp.qa_check(public.get_post(current_setting('qa.post_id')::uuid) is null,'pending post hidden from peer');
select pg_temp.qa_check((select count(*)=0 from storage.objects where name like 'a1111111%'),'pending media hidden from peer');
select public.set_follow('a1111111-1111-4111-8111-111111111119',true);
select pg_temp.qa_check(public.can_message('a1111111-1111-4111-8111-111111111119'),'mutual follows enable messaging');
select set_config('qa.message_id',public.send_message('a1111111-1111-4111-8111-111111111119','Work on the last eight?','f6666666-6666-4666-8666-666666666619')::text,true);
select pg_temp.qa_check(public.send_message('a1111111-1111-4111-8111-111111111119','Retry','f6666666-6666-4666-8666-666666666619')::text=current_setting('qa.message_id'),'message retry idempotent');

set local request.jwt.claims = '{"sub":"c3333333-3333-4333-8333-333333333319","role":"authenticated"}';
select pg_temp.qa_check((select count(*)=0 from public.messages),'unrelated account cannot read conversation');
reset role;
update public.posts set status='approved' where id=current_setting('qa.post_id')::uuid;

set local role authenticated;
set local request.jwt.claims = '{"sub":"b2222222-2222-4222-8222-222222222219","role":"authenticated"}';
select pg_temp.qa_check(public.get_post(current_setting('qa.post_id')::uuid) is not null,'approved post visible');
select public.set_post_action(current_setting('qa.post_id')::uuid,'like',true);
select public.set_post_action(current_setting('qa.post_id')::uuid,'like',true);
select public.set_post_action(current_setting('qa.post_id')::uuid,'save',true);
select public.set_post_action(current_setting('qa.post_id')::uuid,'save',true);
select pg_temp.qa_check((select count(*)=1 from public.likes where user_id=auth.uid()),'like retries idempotent');
select pg_temp.qa_check((select count(*)=1 from public.saves where user_id=auth.uid()),'save retries idempotent');
select public.submit_comment(current_setting('qa.post_id')::uuid,'Try the turn one beat earlier.','e7777777-7777-4777-8777-777777777719');
select public.submit_comment(current_setting('qa.post_id')::uuid,'Retry','e7777777-7777-4777-8777-777777777719');
select pg_temp.qa_check((select count(*)=1 from public.comments where author_id=auth.uid()),'comment retry idempotent');
select pg_temp.qa_check((select status='pending' from public.comments where author_id=auth.uid()),'new comment awaits review');

set local request.jwt.claims = '{"sub":"a1111111-1111-4111-8111-111111111119","role":"authenticated"}';
select pg_temp.qa_check((select (x->>'unread')::int=1 from public.get_inbox() x),'inbox records unread message');
select public.mark_read('b2222222-2222-4222-8222-222222222219');
select pg_temp.qa_check((select read_at is not null from public.messages where id=current_setting('qa.message_id')::uuid),'read receipt stored');
select pg_temp.qa_check((select count(*)=0 from public.comments),'pending peer comment hidden');

set local request.jwt.claims = '{"sub":"b2222222-2222-4222-8222-222222222219","role":"authenticated"}';
select public.report_content('post',current_setting('qa.post_id')::uuid,'Spam or scam');
select pg_temp.qa_check(public.get_post(current_setting('qa.post_id')::uuid) is null,'reported post hidden for reporter');
select pg_temp.qa_check((select count(*)=1 from public.reports),'reporter can view own report');
set local request.jwt.claims = '{"sub":"a1111111-1111-4111-8111-111111111119","role":"authenticated"}';
select pg_temp.qa_check((select count(*)=0 from public.reports),'other account cannot view report');
select public.set_block('b2222222-2222-4222-8222-222222222219',true);
select pg_temp.qa_check(not public.can_message('b2222222-2222-4222-8222-222222222219'),'block disables messaging');
select pg_temp.qa_check((select count(*)=0 from public.messages),'block hides conversation');
select public.set_block('b2222222-2222-4222-8222-222222222219',false);
select pg_temp.qa_check((select count(*)=0 from public.follows),'unblock does not restore follows');
select pg_temp.qa_check(not public.can_message('b2222222-2222-4222-8222-222222222219'),'unblock alone does not enable messages');
do $$begin
 begin update public.wallets set balance=9999; raise exception using errcode='XX000',message='QA_FAIL: client wrote wallet';
 exception when insufficient_privilege then null;end;
 begin perform public.credit_play_purchase(auth.uid(),'qa-forged','vimi_coins_100','qa'); raise exception using errcode='XX000',message='QA_FAIL: client granted coins';
 exception when insufficient_privilege then null;end;
end;$$;

reset role;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';
select pg_temp.qa_check(public.credit_play_purchase('a1111111-1111-4111-8111-111111111119','qa-a-token-20261119','vimi_coins_100','qa-order-a')=100,'service credit exact catalog amount');
select pg_temp.qa_check(public.credit_play_purchase('a1111111-1111-4111-8111-111111111119','qa-a-token-20261119','vimi_coins_100','qa-order-a')=100,'credit retry idempotent');
select pg_temp.qa_check(public.credit_play_purchase('a1111111-1111-4111-8111-111111111119','qa-b-token-20261119','vimi_coins_350','qa-order-b')=450,'second credit total');

reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-4111-8111-111111111119","role":"authenticated"}';
select pg_temp.qa_check(public.unlock_studio_pack('chorus-builder')=330,'pack debits once');
select pg_temp.qa_check(public.unlock_studio_pack('chorus-builder')=330,'unlock retry idempotent');
reset role;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';
select public.reverse_play_purchase('qa-b-token-20261119');
select public.reverse_play_purchase('qa-b-token-20261119');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-4111-8111-111111111119","role":"authenticated"}';
select pg_temp.qa_check((select balance=0 and reversal_debt=20 from public.wallets),'reversal creates exact debt once');
select pg_temp.qa_check((select count(*)=0 from public.pack_unlocks),'reversed debt gates paid packs');
reset role;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';
select pg_temp.qa_check(public.credit_play_purchase('a1111111-1111-4111-8111-111111111119','qa-c-token-20261119','vimi_coins_100','qa-order-c')=80,'new credits settle debt first');
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-4111-8111-111111111119","role":"authenticated"}';
select pg_temp.qa_check((select count(*)=1 from public.pack_unlocks),'settled debt restores prior unlock');
reset role;
select 'PASS: provision, idempotent content/social actions, review visibility, IM/RLS, reports/blocks, wallet grants/unlocks/reversals; all fixtures rolled back' as result;
rollback;

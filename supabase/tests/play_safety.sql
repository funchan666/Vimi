-- Isolated hosted contract test. Every fixture and audit row rolls back.
begin;
insert into auth.users(id,email,raw_user_meta_data,raw_app_meta_data) values
 ('a1191111-1111-4111-8111-111111111119','vimi-play-qa-a@example.invalid','{"birth_date":"2000-01-01","display_name":"Safety QA A","consent_version":"2026-11-18"}','{}'),
 ('b2292222-2222-4222-8222-222222222219','vimi-play-qa-b@example.invalid','{"birth_date":"2000-01-01","display_name":"Safety QA B","consent_version":"2026-11-18"}','{}'),
 ('d4494444-4444-4444-8444-444444444419','vimi-play-qa-reviewer@example.invalid','{"birth_date":"2000-01-01","display_name":"Safety QA Reviewer","consent_version":"2026-11-18"}','{"vimi_role":"moderator"}');
insert into public.posts(id,author_id,caption,style,media_path,media_kind,status,client_id)values
 ('e5595555-5555-4555-8555-555555555519','a1191111-1111-4111-8111-111111111119','Safety QA original photo','K-pop','a1191111-1111-4111-8111-111111111119/posts/safety.webp','image','approved',gen_random_uuid());
insert into public.comments(id,post_id,author_id,body,client_id)values
 ('e7797777-7777-4777-8777-777777777719','e5595555-5555-4555-8555-555555555519','a1191111-1111-4111-8111-111111111119','Safety QA comment',gen_random_uuid());
insert into public.messages(id,sender_id,recipient_id,body,client_id)values
 ('f6696666-6666-4666-8666-666666666619','a1191111-1111-4111-8111-111111111119','b2292222-2222-4222-8222-222222222219','Safety QA message',gen_random_uuid());
insert into public.wallet_ledger(user_id,delta,description,reference)values
 ('a1191111-1111-4111-8111-111111111119',0,'Safety QA pack reference','pack:a1191111-1111-4111-8111-111111111119:chorus-builder');
insert into storage.objects(bucket_id,name,owner_id)values
 ('dance-media','a1191111-1111-4111-8111-111111111119/posts/unsubmitted-safety.webp','a1191111-1111-4111-8111-111111111119');
set local role authenticated;
set local request.jwt.claims='{"role":"authenticated","sub":"a1191111-1111-4111-8111-111111111119"}';
do $$begin
 if (select count(*) from storage.objects where name='a1191111-1111-4111-8111-111111111119/posts/unsubmitted-safety.webp')<>1 then raise exception 'QA_FAIL: active owner media';end if;
end;$$;
reset role;
update private.accounts set status='suspended'where id='a1191111-1111-4111-8111-111111111119';
set local role authenticated;
set local request.jwt.claims='{"role":"authenticated","sub":"a1191111-1111-4111-8111-111111111119"}';
do $$begin
 if exists(select 1 from storage.objects where name='a1191111-1111-4111-8111-111111111119/posts/unsubmitted-safety.webp') then raise exception 'QA_FAIL: suspended owner media';end if;
end;$$;
reset role;
update private.accounts set status='active'where id='a1191111-1111-4111-8111-111111111119';
set local role authenticated;
set local request.jwt.claims='{"role":"authenticated","sub":"b2292222-2222-4222-8222-222222222219"}';
select public.report_content('post','e5595555-5555-4555-8555-555555555519','Child safety');
do $$begin
 if not exists(select 1 from public.reports where reason='Child safety') then raise exception 'QA_FAIL: child safety report';end if;
 begin perform public.remove_moderated_content('d4494444-4444-4444-8444-444444444419','post','e5595555-5555-4555-8555-555555555519');
  raise exception using errcode='XX000',message='QA_FAIL: client removed content';
 exception when insufficient_privilege then null;end;
 begin perform public.moderator_access('d4494444-4444-4444-8444-444444444419');
  raise exception using errcode='XX000',message='QA_FAIL: client invoked reviewer RPC';
 exception when insufficient_privilege then null;end;
end;$$;
reset role;
set local role service_role;
set local request.jwt.claims='{"role":"service_role"}';
do $$begin
 if not public.moderator_access('d4494444-4444-4444-8444-444444444419') then raise exception 'QA_FAIL: moderator denied';end if;
 if public.moderator_access('a1191111-1111-4111-8111-111111111119') then raise exception 'QA_FAIL: ordinary user elevated';end if;
 begin perform public.remove_moderated_content('a1191111-1111-4111-8111-111111111119','post','e5595555-5555-4555-8555-555555555519');
  raise exception using errcode='XX000',message='QA_FAIL: ordinary actor accepted';
 exception when raise_exception then null;end;
end;$$;
select public.remove_moderated_content('d4494444-4444-4444-8444-444444444419','message','f6696666-6666-4666-8666-666666666619');
select public.remove_moderated_content('d4494444-4444-4444-8444-444444444419','message','f6696666-6666-4666-8666-666666666619');
select public.remove_moderated_content('d4494444-4444-4444-8444-444444444419','comment','e7797777-7777-4777-8777-777777777719');
select public.remove_moderated_content('d4494444-4444-4444-8444-444444444419','post','e5595555-5555-4555-8555-555555555519');
select public.remove_moderated_content('d4494444-4444-4444-8444-444444444419','user','a1191111-1111-4111-8111-111111111119');
do $$begin
 if exists(select 1 from public.posts where id='e5595555-5555-4555-8555-555555555519') or exists(select 1 from public.comments where id='e7797777-7777-4777-8777-777777777719') or exists(select 1 from public.messages where id='f6696666-6666-4666-8666-666666666619')
  then raise exception 'QA_FAIL: content not removed';end if;
 if (select count(*) from private.moderation_audit where target_id='f6696666-6666-4666-8666-666666666619' and status='removed')<>1
  then raise exception 'QA_FAIL: removal retry audit duplicated';end if;
 if not exists(select 1 from public.profiles where id='a1191111-1111-4111-8111-111111111119' and display_name='Dancer' and bio='' and avatar_path is null)
  then raise exception 'QA_FAIL: profile reset';end if;
end;$$;
select public.moderate_account('d4494444-4444-4444-8444-444444444419','suspended');
do $$begin if public.moderator_access('d4494444-4444-4444-8444-444444444419') then raise exception 'QA_FAIL: suspended moderator accepted';end if;end;$$;
select public.begin_account_deletion('a1191111-1111-4111-8111-111111111119');
do $$begin
 if exists(select 1 from public.wallet_ledger where reference like 'pack:a1191111-1111-4111-8111-111111111119:%')
  then raise exception 'QA_FAIL: account UUID remains in pack reference';end if;
end;$$;
reset role;
select 'PASS: child safety reports; inactive-owner Storage denial; ordinary/anonymous boundaries; active moderator role; permanent post/comment/message/profile removal; idempotent audit; suspended reviewer denial; deletion reference scrubbing; rollback' result;
rollback;

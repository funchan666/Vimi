-- Hosted contract test. All labelled fixtures are transaction-scoped and rolled back.
begin;
insert into auth.users(id,email,raw_user_meta_data)
select md5('vimi-history-qa-'||i)::uuid,'vimi-history-qa-'||i||'@example.invalid',
 jsonb_build_object('birth_date','2000-01-01','display_name','History QA '||i,'consent_version','2026-11-18')
from generate_series(0,31) i;
insert into public.posts(id,author_id,caption,style,media_path,media_kind,status,client_id,created_at)
select md5('vimi-history-post-'||i)::uuid,md5('vimi-history-qa-0')::uuid,'History QA post '||i,
 'K-pop','history-qa/'||i||'.jpg','image','approved',gen_random_uuid(),
 timestamptz '2026-11-19 05:30:00.123456+00' + ((i/25)*interval '1 microsecond') from generate_series(1,137) i;
insert into public.comments(post_id,author_id,body,status,client_id,created_at)
select md5('vimi-history-post-1')::uuid,md5('vimi-history-qa-1')::uuid,'History QA comment '||i,'approved',gen_random_uuid(),
 timestamptz '2026-11-19 05:30:00.123456+00' from generate_series(1,127) i;
insert into public.messages(id,sender_id,recipient_id,body,client_id,created_at)
select md5('vimi-history-message-'||i)::uuid,
 md5('vimi-history-qa-'||case when i%2=0 then 0 else 1 end)::uuid,
 md5('vimi-history-qa-'||case when i%2=0 then 1 else 0 end)::uuid,
 'History QA message '||i,gen_random_uuid(),
 timestamptz '2026-11-19 05:30:00.123456+00' + ((i/30)*interval '1 microsecond') from generate_series(1,241) i;
insert into public.messages(sender_id,recipient_id,body,client_id,created_at)
select md5('vimi-history-qa-0')::uuid,md5('vimi-history-qa-'||i)::uuid,'History QA other conversation',gen_random_uuid(),
 timestamptz '2026-11-19 05:30:00.123456+00' from generate_series(2,29) i;

set local role authenticated;
select set_config('request.jwt.claims',jsonb_build_object('sub',md5('vimi-history-qa-0')::uuid,'role','authenticated')::text,true);
do $$
declare kind text; cursor_time timestamptz; cursor_id uuid; batch jsonb[]; item jsonb;
 seen uuid[]; expected integer; page_size integer;
begin
 foreach kind in array array['feed','thread','inbox'] loop
  cursor_time:=null; cursor_id:=null; seen:='{}';
  page_size:=case kind when 'feed' then 20 when 'thread' then 50 else 25 end;
  expected:=case kind when 'feed' then 137 when 'thread' then 241 else 29 end;
  loop
   case kind
    when 'feed' then select array_agg(x) into batch from
      (select x from public.get_feed_page(p_author=>md5('vimi-history-qa-0')::uuid,
        p_before_created=>cursor_time,p_before_id=>cursor_id) x limit 20) page;
    when 'thread' then select array_agg(x) into batch from
      (select x from public.get_thread_page(md5('vimi-history-qa-1')::uuid,cursor_time,cursor_id) x limit 50) page;
    else select array_agg(x) into batch from
      (select x from public.get_inbox_page(cursor_time,cursor_id) x limit 25) page;
   end case;
   if batch is null then exit; end if;
   foreach item in array batch loop
    if (item->>'id')::uuid=any(seen) then raise exception 'QA_FAIL: duplicate % row',kind; end if;
    if cursor_time is not null and ((item->>'created_at')::timestamptz,(item->>'id')::uuid)>=(cursor_time,cursor_id)
      then raise exception 'QA_FAIL: unstable % ordering',kind; end if;
    seen:=array_append(seen,(item->>'id')::uuid);
    cursor_time:=(item->>'created_at')::timestamptz; cursor_id:=(item->>'id')::uuid;
   end loop;
   if cardinality(batch)<page_size then exit; end if;
  end loop;
  if cardinality(seen)<>expected then raise exception 'QA_FAIL: % has % rows instead of %',kind,cardinality(seen),expected; end if;
 end loop;
 if public.can_message(md5('vimi-history-qa-1')::uuid) then raise exception 'QA_FAIL: messaging without follows'; end if;
 if (select count(*) from public.comments where post_id=md5('vimi-history-post-1')::uuid)<>127
   then raise exception 'QA_FAIL: comments RLS'; end if;
end;$$;
-- History remains readable after unfollow; a block hides it immediately.
select public.set_block(md5('vimi-history-qa-1')::uuid,true);
do $$begin
 if exists(select 1 from public.get_thread_page(md5('vimi-history-qa-1')::uuid)) then raise exception 'QA_FAIL: block bypass'; end if;
end;$$;
select public.set_block(md5('vimi-history-qa-1')::uuid,false);
select set_config('request.jwt.claims',jsonb_build_object('sub',md5('vimi-history-qa-31')::uuid,'role','authenticated')::text,true);
do $$begin
 if exists(select 1 from public.get_thread_page(md5('vimi-history-qa-0')::uuid)) then raise exception 'QA_FAIL: unrelated thread access'; end if;
 if exists(select 1 from public.get_inbox_page()) then raise exception 'QA_FAIL: unrelated inbox access'; end if;
end;$$;
reset role;
do $$begin
 if exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname in ('get_feed_page','get_thread_page','get_inbox_page')
    and (p.prosecdef or has_function_privilege('anon',p.oid,'EXECUTE')))
  then raise exception 'QA_FAIL: page permissions'; end if;
end;$$;
select 'PASS: 137 posts, 241 messages and 29 inbox threads across stable timestamp/UUID pages, fractional-second ties, unfollow history, block RLS, unrelated account denial and RPC grants; fixtures rolled back' result;
rollback;

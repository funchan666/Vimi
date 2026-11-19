create index moderation_actor on private.moderation_audit(actor_id);

-- Keep all privileged implementation in private; exposed functions invoke it.
-- The private schema is not in PostgREST's exposed schema list.
do $$
declare fn record;arg_names text;wrapper text;
begin
 for fn in select p.oid,p.proname,pg_get_function_identity_arguments(p.oid) identity_args,pg_get_function_arguments(p.oid) all_args,pg_get_function_result(p.oid) result_type,p.provolatile,p.proretset,p.pronargs from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'and p.proname=any(array['account_status','get_blocked','mark_read','report_content','send_message','set_block','submit_comment','submit_post','toggle_follow','toggle_post_action','unlock_studio_pack','update_dancer'])
 loop
  select string_agg('$'||s.i::text,',')into arg_names from generate_series(1,fn.pronargs)s(i);
  execute format('alter function public.%I(%s) set schema private',fn.proname,fn.identity_args);
  wrapper:=case when fn.proretset then 'select * from private.'else 'select private.'end||quote_ident(fn.proname)||'('||coalesce(arg_names,'')||')';
  execute format('create function public.%I(%s) returns %s language sql %s security invoker set search_path='''' as %L',fn.proname,fn.all_args,fn.result_type,case fn.provolatile when 's'then 'stable'when 'i'then 'immutable'else 'volatile'end,wrapper);
  execute format('revoke all on function public.%I(%s) from public,anon,authenticated',fn.proname,fn.identity_args);
  execute format('grant execute on function public.%I(%s) to authenticated',fn.proname,fn.identity_args);
 end loop;
end;
$$;
-- Refund debt disables paid pack access and must be settled before another unlock.
create or replace function private.unlock_studio_pack(p_pack text)returns bigint language plpgsql security definer set search_path='' as $$
 declare price integer;funds bigint;debt bigint;
 begin perform private.require_account();select balance,reversal_debt into funds,debt from public.wallets where user_id=auth.uid()for update;
 if debt>0 then raise exception 'Settle the reversed purchase in your wallet before unlocking a pack.';end if;
 if exists(select 1 from public.pack_unlocks where user_id=auth.uid()and pack_id=p_pack)then return funds;end if;
 select cost into strict price from public.studio_packs where id=p_pack;
 if funds<price then raise exception 'Not enough coins. Add coins to unlock this pack.';end if;
 update public.wallets set balance=balance-price where user_id=auth.uid()returning balance into funds;
 insert into public.pack_unlocks(user_id,pack_id)values(auth.uid(),p_pack);
 insert into public.wallet_ledger(user_id,delta,description,reference)values(auth.uid(),-price,'Studio pack: '||p_pack,'pack:'||auth.uid()::text||':'||p_pack);return funds;end;
$$;

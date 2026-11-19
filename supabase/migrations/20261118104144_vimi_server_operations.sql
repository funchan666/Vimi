-- Service-only operations. No private data is exposed through public views.
create table private.api_limits(user_id uuid not null references auth.users(id)on delete cascade,action text not null,window_start timestamptz not null,hits integer not null,primary key(user_id,action));
alter table private.api_limits enable row level security;
create table private.moderation_audit(id uuid primary key default gen_random_uuid(),actor_id uuid references auth.users(id)on delete set null,kind text not null,target_id uuid not null,status text not null,created_at timestamptz not null default now());
alter table private.moderation_audit enable row level security;
alter table public.wallets add column reversal_debt bigint not null default 0 check(reversal_debt>=0);

create function public.account_status() returns text language sql stable security definer set search_path='' as $$select status from private.accounts where id=auth.uid();$$;
create function public.guard_api_request(p_user uuid,p_action text,p_limit integer)returns void language plpgsql security definer set search_path='' as $$
 declare current_hits integer;
 begin
 if(current_setting('request.jwt.claims',true)::jsonb->>'role')is distinct from 'service_role'then raise exception 'Server only.';end if;
 if not private.active(p_user)then raise exception 'Account unavailable.';end if;
 insert into private.api_limits(user_id,action,window_start,hits)values(p_user,p_action,now(),1)
 on conflict(user_id,action)do update set hits=case when api_limits.window_start<now()-interval '1 hour'then 1 else api_limits.hits+1 end,window_start=case when api_limits.window_start<now()-interval '1 hour'then now()else api_limits.window_start end returning hits into current_hits;
 if current_hits>least(greatest(p_limit,1),100)then raise exception 'Try later.';end if;
 end;
$$;
create function public.begin_account_deletion(p_user uuid)returns void language plpgsql security definer set search_path='' as $$
 begin if(current_setting('request.jwt.claims',true)::jsonb->>'role')is distinct from 'service_role'then raise exception 'Server only.';end if;
 update private.accounts set status='deleting'where id=p_user;end;
$$;
create function public.moderate_account(p_user uuid,p_status text)returns void language plpgsql security definer set search_path='' as $$
 begin if(current_setting('request.jwt.claims',true)::jsonb->>'role')is distinct from 'service_role'then raise exception 'Server only.';end if;
 if p_status not in('active','suspended')then raise exception 'Invalid status.';end if;
 update private.accounts set status=p_status where id=p_user and status<>'deleting';end;
$$;
create function public.record_moderation(p_actor uuid,p_kind text,p_target uuid,p_status text)returns void language plpgsql security definer set search_path='' as $$
 begin if(current_setting('request.jwt.claims',true)::jsonb->>'role')is distinct from 'service_role'then raise exception 'Server only.';end if;
 insert into private.moderation_audit(actor_id,kind,target_id,status)values(p_actor,p_kind,p_target,p_status);end;
$$;
create or replace function public.credit_play_purchase(p_user uuid,p_token_hash text,p_product text,p_order text)returns bigint language plpgsql security definer set search_path='' as $$
 declare amount integer;funds bigint;debt bigint;existing uuid;repaid bigint;
 begin
 if(current_setting('request.jwt.claims',true)::jsonb->>'role')is distinct from 'service_role'then raise exception 'Server only.';end if;
 if not private.active(p_user)then raise exception 'Account unavailable.';end if;
 select balance,reversal_debt into funds,debt from public.wallets where user_id=p_user for update;
 select user_id into existing from private.play_purchases where token_hash=p_token_hash;
 if found then if existing is distinct from p_user then raise exception 'Purchase belongs to another account.';end if;return funds;end if;
 select coins into strict amount from public.coin_products where id=p_product and active;
 insert into private.play_purchases(token_hash,user_id,product_id,order_id,coins)values(p_token_hash,p_user,p_product,p_order,amount);
 repaid:=least(debt,amount);
 update public.wallets set balance=balance+amount-repaid,reversal_debt=reversal_debt-repaid where user_id=p_user returning balance into funds;
 insert into public.wallet_ledger(user_id,delta,description,reference)values(p_user,amount,case when repaid>0 then 'Google Play coins; '||repaid::text||' settled a reversed purchase'else 'Google Play coin purchase'end,p_token_hash);return funds;
 end;
$$;
create function public.reverse_play_purchase(p_token_hash text)returns void language plpgsql security definer set search_path='' as $$
 declare owner uuid;amount bigint;funds bigint;
 begin
 if(current_setting('request.jwt.claims',true)::jsonb->>'role')is distinct from 'service_role'then raise exception 'Server only.';end if;
 -- Lock wallet before receipt, in the same order used by credits, to avoid deadlocks.
 select user_id into owner from private.play_purchases where token_hash=p_token_hash;
 if not found then return;end if;
 if owner is not null then select balance into funds from public.wallets where user_id=owner for update;end if;
 select coins into amount from private.play_purchases where token_hash=p_token_hash and voided_at is null for update;
 if not found then return;end if;
 update private.play_purchases set voided_at=now()where token_hash=p_token_hash;
 if owner is not null then
 update public.wallets set balance=greatest(0,balance-amount),reversal_debt=reversal_debt+greatest(0,amount-funds)where user_id=owner;
 insert into public.wallet_ledger(user_id,delta,description,reference)values(owner,-amount,'Google Play purchase reversed','reversal:'||p_token_hash)on conflict(reference)do nothing;
 end if;end;
$$;
drop policy unlocks_read on public.pack_unlocks;
create policy unlocks_read on public.pack_unlocks for select to authenticated using(user_id=(select auth.uid())and exists(select 1 from public.wallets w where w.user_id=(select auth.uid())and w.reversal_debt=0));
drop policy media_insert on storage.objects;
create policy media_insert on storage.objects for insert to authenticated with check(bucket_id='dance-media'and(storage.foldername(name))[1]=(select auth.uid())::text and(storage.foldername(name))[2]in('posts','avatar')and array_length(storage.foldername(name),1)=2 and private.active((select auth.uid())));
revoke all on function public.account_status(),public.guard_api_request(uuid,text,integer),public.begin_account_deletion(uuid),public.moderate_account(uuid,text),public.record_moderation(uuid,text,uuid,text),public.reverse_play_purchase(text)from public,anon,authenticated;
grant execute on function public.account_status()to authenticated;
grant execute on function public.guard_api_request(uuid,text,integer),public.begin_account_deletion(uuid),public.moderate_account(uuid,text),public.record_moderation(uuid,text,uuid,text),public.reverse_play_purchase(text)to service_role;
grant all on all tables in schema private to service_role;

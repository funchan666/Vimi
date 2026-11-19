-- Child-safety reporting and service-only removal of violating UGC.
alter table public.reports drop constraint reports_reason_check;
alter table public.reports add constraint reports_reason_check check(reason in (
 'Child safety','Harassment','Sexual content','Hate or violence','Copyright',
 'Spam or scam','Privacy','Underage user','Other'));

create function public.moderator_access(p_actor uuid) returns boolean
language sql stable security invoker set search_path='' as $$
 select exists(select 1 from auth.users u join private.accounts a on a.id=u.id
  where u.id=p_actor and a.status='active' and u.raw_app_meta_data->>'vimi_role'='moderator');
$$;
revoke all on function public.moderator_access(uuid) from public,anon,authenticated;
grant execute on function public.moderator_access(uuid) to service_role;

create unique index moderation_removed_once on private.moderation_audit(kind,target_id) where status='removed';
create function public.remove_moderated_content(p_actor uuid,p_kind text,p_target uuid) returns void
language plpgsql security invoker set search_path='' as $$
begin
 if (current_setting('request.jwt.claims',true)::jsonb->>'role') is distinct from 'service_role'
    or not public.moderator_access(p_actor) then raise exception 'Reviewer access required.';end if;
 if p_kind='post' then delete from public.posts where id=p_target;
 elsif p_kind='comment' then delete from public.comments where id=p_target;
 elsif p_kind='message' then delete from public.messages where id=p_target;
 elsif p_kind='user' then
  update public.profiles set display_name='Dancer',bio='',avatar_path=null where id=p_target;
  if not found then raise exception 'This dancer is unavailable.';end if;
  insert into private.moderation_audit(actor_id,kind,target_id,status)values(p_actor,p_kind,p_target,'profile_reset');
  return;
 else raise exception 'Invalid content type.';
 end if;
 insert into private.moderation_audit(actor_id,kind,target_id,status)values(p_actor,p_kind,p_target,'removed')
 on conflict(kind,target_id) where status='removed' do nothing;
end;
$$;
revoke all on function public.remove_moderated_content(uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.remove_moderated_content(uuid,text,uuid) to service_role;

-- Remove the account UUID embedded in pack-ledger references when deletion starts.
create or replace function public.begin_account_deletion(p_user uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
 if (current_setting('request.jwt.claims',true)::jsonb->>'role') is distinct from 'service_role'
 then raise exception 'Server only.';end if;
 update private.accounts set status='deleting' where id=p_user;
 update public.wallet_ledger set reference='deleted:'||id::text
  where user_id=p_user and reference like 'pack:'||p_user::text||':%';
end;
$$;

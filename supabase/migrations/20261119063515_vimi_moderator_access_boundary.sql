-- Keep Auth-table reads behind a narrowly scoped private helper; service_role
-- deliberately has no blanket SELECT privilege on auth.users.
create function private.moderator_access(p_actor uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select (current_setting('request.jwt.claims',true)::jsonb->>'role')='service_role'
  and exists(select 1 from auth.users u join private.accounts a on a.id=u.id
   where u.id=p_actor and a.status='active' and u.raw_app_meta_data->>'vimi_role'='moderator');
$$;
revoke all on function private.moderator_access(uuid) from public,anon,authenticated;
grant execute on function private.moderator_access(uuid) to service_role;
create or replace function public.moderator_access(p_actor uuid) returns boolean
language sql stable security invoker set search_path='' as $$select private.moderator_access($1)$$;

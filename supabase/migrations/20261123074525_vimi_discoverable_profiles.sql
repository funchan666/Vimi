alter table private.accounts
  add column discovery_visible boolean not null default true;

-- This lookup only exposes whether another account is eligible for discovery.
create function private.profile_discovery_enabled(p_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from private.accounts a
    where a.id = p_id and a.id <> (select auth.uid())
      and a.status = 'active' and a.discovery_visible
  );
$$;
revoke all on function private.profile_discovery_enabled(uuid)
  from public, anon, authenticated, service_role;
grant execute on function private.profile_discovery_enabled(uuid) to authenticated;

-- The profile table's existing RLS still applies to blocks and reports.
create view public.discoverable_profiles with (security_invoker = true) as
select p.id, p.display_name, p.bio, p.styles, p.avatar_path, p.created_at
from public.profiles p
where private.profile_discovery_enabled(p.id);

revoke all on public.discoverable_profiles from public, anon, authenticated, service_role;
grant select on public.discoverable_profiles to authenticated;

-- Direct calls are foreground-only. Realtime publishes the call state, never SDP or ICE.
create table public.direct_calls (
  id uuid primary key default gen_random_uuid(),
  caller_id uuid not null references public.profiles(id) on delete cascade,
  callee_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('audio', 'video')),
  status text not null default 'ringing'
    check (status in ('ringing', 'accepted', 'declined', 'canceled', 'ended', 'expired')),
  created_at timestamptz not null,
  answered_at timestamptz,
  ended_at timestamptz,
  expires_at timestamptz not null,
  check (caller_id <> callee_id)
);
create index direct_calls_caller on public.direct_calls (caller_id, created_at desc);
create index direct_calls_callee on public.direct_calls (callee_id, created_at desc);
create index direct_calls_expiry on public.direct_calls (expires_at, id)
  where status in ('ringing', 'accepted');
create index direct_calls_retention on public.direct_calls (ended_at)
  where ended_at is not null;

create table private.direct_call_connections (
  call_id uuid primary key references public.direct_calls(id) on delete cascade,
  caller_session_id uuid not null,
  callee_session_id uuid,
  caller_seen_at timestamptz,
  callee_seen_at timestamptz
);
create table private.direct_call_signals (
  id bigint generated always as identity primary key,
  call_id uuid not null references public.direct_calls(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('offer', 'answer', 'ice')),
  payload jsonb not null,
  created_at timestamptz not null default clock_timestamp()
);
create index direct_call_signal_history on private.direct_call_signals (call_id, id);
create index direct_call_signal_sender on private.direct_call_signals (sender_id);
create unique index direct_call_descriptions on private.direct_call_signals (call_id, kind)
  where kind in ('offer', 'answer');

alter table public.direct_calls enable row level security;
alter table private.direct_call_connections enable row level security;
alter table private.direct_call_signals enable row level security;
revoke all on public.direct_calls, private.direct_call_connections, private.direct_call_signals
  from public, anon, authenticated;
grant select on public.direct_calls to authenticated;

create function private.valid_call_session() returns uuid
language sql stable security definer set search_path = '' as $$
  select s.id from auth.sessions s
  where s.id = nullif(auth.jwt()->>'session_id', '')::uuid
    and s.user_id = (select auth.uid())
    and (s.not_after is null or s.not_after > now())
    and private.active(s.user_id);
$$;

revoke all on function private.valid_call_session() from public, anon, authenticated;
grant execute on function private.valid_call_session() to authenticated;

create policy direct_calls_participant on public.direct_calls for select to authenticated
  using ((select auth.uid()) in (caller_id, callee_id) and (select private.valid_call_session()) is not null);
alter publication supabase_realtime add table public.direct_calls;

create function private.can_call_peer(p_peer uuid) returns boolean
language sql stable set search_path = '' as $$
  select private.can_chat(p_peer)
    and not exists (
      select 1 from public.reports r
      where r.reporter_id = p_peer and r.target_type = 'user' and r.target_id = auth.uid()
    );
$$;

create function private.direct_call_json(p_row public.direct_calls) returns jsonb
language sql volatile set search_path = '' as $$
  select case when p_row.id is not null then
    case when p_row.status in ('ringing', 'accepted') and p_row.expires_at <= clock_timestamp()
      then to_jsonb(p_row) || jsonb_build_object('status', 'expired', 'ended_at', p_row.expires_at)
      when p_row.status in ('ringing', 'accepted')
        and not private.can_call_peer(case when auth.uid() = p_row.caller_id then p_row.callee_id else p_row.caller_id end)
      then to_jsonb(p_row) || jsonb_build_object('status', 'ended', 'ended_at', clock_timestamp())
      else to_jsonb(p_row)
    end
  end;
$$;

-- Account locks serialize call starts and lease changes across different peers.
create function private.lock_direct_call_users(p_first uuid, p_second uuid) returns void
language plpgsql set search_path = '' as $$
declare
  first_key integer := pg_catalog.hashtext(p_first::text);
  second_key integer := pg_catalog.hashtext(p_second::text);
begin
  perform pg_catalog.pg_advisory_xact_lock(834701, least(first_key, second_key));
  if first_key <> second_key then
    perform pg_catalog.pg_advisory_xact_lock(834701, greatest(first_key, second_key));
  end if;
end;
$$;

-- The first recipient device to accept owns the receiving side until the call ends.
create function private.direct_call_row(p_call uuid, p_lock boolean) returns public.direct_calls
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  actor_session uuid := private.valid_call_session();
  call_row public.direct_calls;
begin
  if actor_session is null then raise exception 'Sign in again to use calls.'; end if;
  select * into call_row from public.direct_calls
    where id = p_call and actor in (caller_id, callee_id);
  if not found then return null; end if;
  if p_lock then
    perform private.lock_pair(case when actor = call_row.caller_id then call_row.callee_id else call_row.caller_id end);
    perform private.lock_direct_call_users(call_row.caller_id, call_row.callee_id);
    select * into call_row from public.direct_calls where id = p_call for update;
    if not found then return null; end if;
  end if;
  if not exists (
    select 1 from private.direct_call_connections c where c.call_id = p_call
      and (
        (actor = call_row.caller_id and c.caller_session_id = actor_session) or
        (actor = call_row.callee_id and (c.callee_session_id is null or c.callee_session_id = actor_session))
      )
  ) then return null; end if;
  return call_row;
end;
$$;

create function private.start_call(p_peer uuid, p_kind text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  actor_session uuid := private.valid_call_session();
  call_row public.direct_calls;
  current_time_utc timestamptz;
begin
  if actor_session is null then raise exception 'Sign in again to use calls.'; end if;
  if p_peer is null or p_peer = actor or p_kind is null or p_kind not in ('audio', 'video') then
    raise exception 'Choose a dancer and a call type.';
  end if;
  perform private.lock_pair(p_peer);
  perform private.lock_direct_call_users(actor, p_peer);
  if not private.can_call_peer(p_peer) then
    raise exception 'Calls are available between dancers who follow each other.';
  end if;
  current_time_utc := clock_timestamp();
  select * into call_row from public.direct_calls c
    where c.status in ('ringing', 'accepted') and c.expires_at > current_time_utc
      and (c.caller_id in (actor, p_peer) or c.callee_id in (actor, p_peer)) limit 1;
  if found then
    if call_row.caller_id = actor and call_row.callee_id = p_peer and call_row.kind = p_kind
      and exists (
        select 1 from private.direct_call_connections c
        where c.call_id = call_row.id and c.caller_session_id = actor_session
      ) then
      return private.direct_call_json(call_row);
    end if;
    raise exception 'One of you is already in another call.';
  end if;
  if (select count(*) from public.direct_calls
      where caller_id = actor and created_at > current_time_utc - interval '1 minute') >= 6 then
    raise exception 'Wait a moment before starting another call.';
  end if;
  insert into public.direct_calls (caller_id, callee_id, kind, created_at, expires_at)
    values (actor, p_peer, p_kind, current_time_utc, current_time_utc + interval '45 seconds')
    returning * into call_row;
  insert into private.direct_call_connections (call_id, caller_session_id)
    values (call_row.id, actor_session);
  return private.direct_call_json(call_row);
end;
$$;

create function private.update_call(p_call uuid, p_action text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  call_row public.direct_calls := private.direct_call_row(p_call, true);
  actor uuid := auth.uid();
  peer uuid;
  current_time_utc timestamptz := clock_timestamp();
  next_status text;
begin
  if call_row.id is null then return null; end if;
  if call_row.status not in ('ringing', 'accepted') or call_row.expires_at <= current_time_utc then
    return private.direct_call_json(call_row);
  end if;
  peer := case when actor = call_row.caller_id then call_row.callee_id else call_row.caller_id end;
  if p_action = 'accept' and actor = call_row.callee_id then
    if call_row.status = 'accepted' then return private.direct_call_json(call_row); end if;
    if not private.can_call_peer(peer) then raise exception 'This call is no longer available.'; end if;
    update private.direct_call_connections
      set callee_session_id = private.valid_call_session(),
          caller_seen_at = current_time_utc, callee_seen_at = current_time_utc
      where call_id = p_call;
    update public.direct_calls set status = 'accepted', answered_at = current_time_utc,
      expires_at = current_time_utc + interval '75 seconds'
      where id = p_call returning * into call_row;
    return private.direct_call_json(call_row);
  end if;
  next_status := case
    when p_action = 'decline' and actor = call_row.callee_id and call_row.status = 'ringing' then 'declined'
    when p_action = 'cancel' and actor = call_row.caller_id and call_row.status = 'ringing' then 'canceled'
    when p_action in ('end', 'cancel') and call_row.status = 'accepted' then 'ended'
  end;
  if next_status is null then raise exception 'This action is unavailable for the current call.'; end if;
  update public.direct_calls set status = next_status, ended_at = current_time_utc
    where id = p_call returning * into call_row;
  return private.direct_call_json(call_row);
end;
$$;

create function private.get_call(p_call uuid) returns jsonb
language sql volatile security definer set search_path = '' as $$
  select private.direct_call_json(private.direct_call_row(p_call, false));
$$;

create function private.get_active_call() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid();
  actor_session uuid := private.valid_call_session();
  call_row public.direct_calls;
begin
  if actor_session is null then raise exception 'Sign in again to use calls.'; end if;
  select c.* into call_row
    from public.direct_calls c join private.direct_call_connections s on s.call_id = c.id
    where c.status in ('ringing', 'accepted') and c.expires_at > clock_timestamp()
      and (
        (c.caller_id = actor and s.caller_session_id = actor_session) or
        (c.callee_id = actor and (s.callee_session_id is null or s.callee_session_id = actor_session))
      )
      and private.can_call_peer(case when actor = c.caller_id then c.callee_id else c.caller_id end)
    order by c.created_at desc limit 1;
  return private.direct_call_json(call_row);
end;
$$;

create function private.touch_call(p_call uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  call_row public.direct_calls := private.direct_call_row(p_call, true);
  caller_seen timestamptz;
  callee_seen timestamptz;
  new_expiry timestamptz;
  current_time_utc timestamptz := clock_timestamp();
begin
  if call_row.id is null or call_row.status <> 'accepted' or call_row.expires_at <= current_time_utc then
    return private.direct_call_json(call_row);
  end if;
  if not private.can_call_peer(case when auth.uid() = call_row.caller_id then call_row.callee_id else call_row.caller_id end) then
    update public.direct_calls set status = 'ended', ended_at = current_time_utc
      where id = p_call returning * into call_row;
    return private.direct_call_json(call_row);
  end if;
  update private.direct_call_connections
    set caller_seen_at = case when auth.uid() = call_row.caller_id then current_time_utc else caller_seen_at end,
        callee_seen_at = case when auth.uid() = call_row.callee_id then current_time_utc else callee_seen_at end
    where call_id = p_call returning caller_seen_at, callee_seen_at into caller_seen, callee_seen;
  new_expiry := least(least(caller_seen, callee_seen) + interval '75 seconds',
    call_row.answered_at + interval '4 hours');
  if new_expiry > call_row.expires_at then
    update public.direct_calls set expires_at = new_expiry where id = p_call returning * into call_row;
  end if;
  return private.direct_call_json(call_row);
end;
$$;

create function private.send_call_signal(p_call uuid, p_kind text, p_payload jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare
  call_row public.direct_calls := private.direct_call_row(p_call, true);
  actor uuid := auth.uid();
begin
  if call_row.id is null or call_row.status <> 'accepted' or call_row.expires_at <= clock_timestamp()
    or not private.can_call_peer(case when actor = call_row.caller_id then call_row.callee_id else call_row.caller_id end) then
    raise exception 'This call is no longer available.';
  end if;
  if p_kind is null or p_kind not in ('offer', 'answer', 'ice') or p_payload is null
    or jsonb_typeof(p_payload) <> 'object' or octet_length(p_payload::text) > 49152 then
    raise exception 'Invalid call signal.';
  end if;
  if p_kind in ('offer', 'answer') then
    if (p_kind = 'offer' and actor <> call_row.caller_id) or
      (p_kind = 'answer' and actor <> call_row.callee_id) or
      p_payload->>'type' is distinct from p_kind or
      jsonb_typeof(p_payload->'sdp') is distinct from 'string' or
      coalesce(length(p_payload->>'sdp'), 0) = 0 or p_payload - 'type' - 'sdp' <> '{}'::jsonb then
      raise exception 'Invalid call description.';
    end if;
    if p_kind = 'answer' and not exists (
      select 1 from private.direct_call_signals where call_id = p_call and kind = 'offer'
    ) then raise exception 'This call is waiting for an offer.'; end if;
    insert into private.direct_call_signals (call_id, sender_id, kind, payload)
      values (p_call, actor, p_kind, p_payload)
      on conflict (call_id, kind) where kind in ('offer', 'answer') do nothing;
    if not found and not exists (
      select 1 from private.direct_call_signals
      where call_id = p_call and kind = p_kind and payload = p_payload
    ) then raise exception 'The call description has already been sent.'; end if;
    return;
  end if;
  if jsonb_typeof(p_payload->'candidate') is distinct from 'string' or
    length(p_payload->>'candidate') not between 1 and 2048 or
    coalesce(jsonb_typeof(p_payload->'sdpMid'), 'null') not in ('string', 'null') or
    coalesce(jsonb_typeof(p_payload->'sdpMLineIndex'), 'null') not in ('number', 'null') or
    (p_payload->>'sdpMid' is null and p_payload->>'sdpMLineIndex' is null) or
    length(p_payload->>'sdpMid') > 128 or
    p_payload->>'sdpMLineIndex' !~ '^[0-9]{1,3}$' or
    p_payload - 'candidate' - 'sdpMid' - 'sdpMLineIndex' <> '{}'::jsonb or
    octet_length(p_payload::text) > 4096 then raise exception 'Invalid call candidate.'; end if;
  if (select count(*) from private.direct_call_signals
      where call_id = p_call and sender_id = actor and kind = 'ice') < 128 then
    insert into private.direct_call_signals (call_id, sender_id, kind, payload)
      values (p_call, actor, p_kind, p_payload);
  end if;
end;
$$;

create function private.get_call_signals(p_call uuid, p_after bigint default 0) returns setof jsonb
language plpgsql security definer set search_path = '' as $$
declare
  call_row public.direct_calls := private.direct_call_row(p_call, false);
begin
  if call_row.id is not null and call_row.status = 'accepted' and call_row.expires_at > clock_timestamp()
    and private.can_call_peer(case when auth.uid() = call_row.caller_id then call_row.callee_id else call_row.caller_id end) then
    return query select to_jsonb(s) from private.direct_call_signals s
      where s.call_id = p_call and s.sender_id <> auth.uid() and s.id > greatest(0, p_after)
      order by s.id limit 64;
  end if;
end;
$$;

create function private.purge_direct_call_content() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from private.direct_call_signals where call_id = new.id;
  return null;
end;
$$;
create trigger direct_call_purge_signals after update of status on public.direct_calls
  for each row when (old.status in ('ringing', 'accepted') and new.status not in ('ringing', 'accepted'))
  execute function private.purge_direct_call_content();

create function private.end_direct_call_on_safety_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  member uuid;
  peer uuid;
begin
  case tg_table_name
    when 'follows' then member := old.follower_id; peer := old.following_id;
    when 'blocks' then member := new.blocker_id; peer := new.blocked_id;
    when 'reports' then member := new.reporter_id; peer := new.target_id;
    when 'accounts' then member := new.id;
  end case;
  update public.direct_calls set status = 'ended', ended_at = clock_timestamp()
    where status in ('ringing', 'accepted') and expires_at > clock_timestamp()
      and ((caller_id = member and (peer is null or callee_id = peer))
        or (callee_id = member and (peer is null or caller_id = peer)));
  return null;
end;
$$;
create trigger direct_calls_unfollow after delete on public.follows
  for each row execute function private.end_direct_call_on_safety_change();
create trigger direct_calls_block after insert on public.blocks
  for each row execute function private.end_direct_call_on_safety_change();
create trigger direct_calls_report after insert on public.reports
  for each row when (new.target_type = 'user') execute function private.end_direct_call_on_safety_change();
create trigger direct_calls_restrict_account after update of status on private.accounts
  for each row when (old.status = 'active' and new.status <> 'active')
  execute function private.end_direct_call_on_safety_change();

create function private.expire_direct_calls() returns void
language plpgsql set search_path = '' as $$
begin
  update public.direct_calls set status = 'expired', ended_at = expires_at
    where id in (select id from public.direct_calls
      where status in ('ringing', 'accepted') and expires_at <= statement_timestamp()
      for update skip locked);
  delete from public.direct_calls where ended_at <= statement_timestamp() - interval '24 hours';
end;
$$;
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('vimi-direct-call-retention', '*/5 * * * *', 'select private.expire_direct_calls()');

create function public.start_call(p_peer uuid, p_kind text) returns jsonb
language sql security invoker set search_path = '' as $$ select private.start_call(p_peer, p_kind); $$;
create function public.update_call(p_call uuid, p_action text) returns jsonb
language sql security invoker set search_path = '' as $$ select private.update_call(p_call, p_action); $$;
create function public.get_call(p_call uuid) returns jsonb
language sql security invoker set search_path = '' as $$ select private.get_call(p_call); $$;
create function public.get_active_call() returns jsonb
language sql security invoker set search_path = '' as $$ select private.get_active_call(); $$;
create function public.touch_call(p_call uuid) returns jsonb
language sql security invoker set search_path = '' as $$ select private.touch_call(p_call); $$;
create function public.send_call_signal(p_call uuid, p_kind text, p_payload jsonb) returns void
language sql security invoker set search_path = '' as $$ select private.send_call_signal(p_call, p_kind, p_payload); $$;
create function public.get_call_signals(p_call uuid, p_after bigint default 0) returns setof jsonb
language sql security invoker set search_path = '' as $$ select * from private.get_call_signals(p_call, p_after); $$;

revoke all on function private.can_call_peer(uuid), private.direct_call_json(public.direct_calls),
  private.lock_direct_call_users(uuid, uuid), private.direct_call_row(uuid, boolean), private.purge_direct_call_content(),
  private.end_direct_call_on_safety_change(), private.expire_direct_calls()
  from public, anon, authenticated;
revoke all on function private.start_call(uuid, text), private.update_call(uuid, text),
  private.get_call(uuid), private.get_active_call(), private.touch_call(uuid),
  private.send_call_signal(uuid, text, jsonb), private.get_call_signals(uuid, bigint),
  public.start_call(uuid, text), public.update_call(uuid, text), public.get_call(uuid),
  public.get_active_call(), public.touch_call(uuid),
  public.send_call_signal(uuid, text, jsonb), public.get_call_signals(uuid, bigint)
  from public, anon, authenticated;
grant execute on function private.start_call(uuid, text), private.update_call(uuid, text),
  private.get_call(uuid), private.get_active_call(), private.touch_call(uuid),
  private.send_call_signal(uuid, text, jsonb), private.get_call_signals(uuid, bigint),
  public.start_call(uuid, text), public.update_call(uuid, text), public.get_call(uuid),
  public.get_active_call(), public.touch_call(uuid),
  public.send_call_signal(uuid, text, jsonb), public.get_call_signals(uuid, bigint)
  to authenticated;

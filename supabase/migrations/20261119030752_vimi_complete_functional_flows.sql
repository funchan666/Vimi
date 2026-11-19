-- Complete account/media state transitions without exposing privileged operations.
create or replace function private.provision_dancer()
returns trigger language plpgsql security definer set search_path = '' as $$
declare birth date; dancer_name text;
begin
  birth := (new.raw_user_meta_data->>'birth_date')::date;
  if birth is null or birth > current_date - interval '18 years' or birth < date '1900-01-01' then
    raise exception 'Vimi is for adults aged 18 and over.';
  end if;
  if (new.raw_user_meta_data->>'consent_version') is distinct from '2026-11-18' then
    raise exception 'Accept the Terms and Privacy Policy.';
  end if;
  dancer_name := trim(new.raw_user_meta_data->>'display_name');
  insert into private.accounts(id,birth_date,consent_version) values(new.id,birth,'2026-11-18');
  insert into public.profiles(id,display_name) values(new.id,dancer_name);
  insert into public.wallets(user_id) values(new.id);
  return new;
end;
$$;

create function private.can_remove_media(p_name text)
returns boolean language sql stable security definer set search_path = '' as $$
  select private.active(auth.uid())
    and split_part(p_name,'/',1) = auth.uid()::text
    and not exists(select 1 from public.posts where media_path = p_name)
    and not exists(select 1 from public.profiles where avatar_path = p_name);
$$;
revoke all on function private.can_remove_media(text) from public, anon, authenticated;
grant execute on function private.can_remove_media(text) to authenticated;
drop policy media_delete on storage.objects;
create policy media_delete on storage.objects for delete to authenticated
using (bucket_id = 'dance-media' and owner_id = (select auth.uid())::text and private.can_remove_media(name));

create function private.set_follow(p_peer uuid, p_followed boolean)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_account();
  perform private.lock_pair(p_peer);
  if p_peer is null or p_followed is null or p_peer = auth.uid() or not private.can_see_user(p_peer) then
    raise exception 'This dancer is unavailable.';
  end if;
  if p_followed then
    insert into public.follows(follower_id,following_id) values(auth.uid(),p_peer) on conflict do nothing;
  else
    delete from public.follows where follower_id = auth.uid() and following_id = p_peer;
  end if;
  return p_followed;
end;
$$;
create function public.set_follow(p_peer uuid, p_followed boolean)
returns boolean language sql security invoker set search_path = '' as $$select private.set_follow(p_peer,p_followed);$$;
revoke all on function private.set_follow(uuid,boolean),public.set_follow(uuid,boolean) from public,anon,authenticated;
grant execute on function private.set_follow(uuid,boolean),public.set_follow(uuid,boolean) to authenticated;

create function private.set_post_action(p_post uuid, p_action text, p_selected boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_account();
  if p_selected is null or not private.can_see_post(p_post) then raise exception 'This post is unavailable.'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text || p_post::text || p_action,0));
  if p_action = 'like' then
    if p_selected then insert into public.likes values(auth.uid(),p_post) on conflict do nothing;
    else delete from public.likes where user_id = auth.uid() and post_id = p_post; end if;
  elsif p_action = 'save' then
    if p_selected then insert into public.saves values(auth.uid(),p_post) on conflict do nothing;
    else delete from public.saves where user_id = auth.uid() and post_id = p_post; end if;
  else raise exception 'Unknown post action.'; end if;
end;
$$;
create function public.set_post_action(p_post uuid, p_action text, p_selected boolean)
returns void language sql security invoker set search_path = '' as $$select private.set_post_action(p_post,p_action,p_selected);$$;
revoke all on function private.set_post_action(uuid,text,boolean),public.set_post_action(uuid,text,boolean) from public,anon,authenticated;
grant execute on function private.set_post_action(uuid,text,boolean),public.set_post_action(uuid,text,boolean) to authenticated;

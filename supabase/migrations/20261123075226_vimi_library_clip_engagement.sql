-- Clip IDs match the publisher video catalog in assets/data/media_library.json.
create table private.library_clips (
  id text primary key,
  active boolean not null default true,
  author_profile_id uuid references public.profiles(id) on delete set null
);
create index library_clips_author_profile on private.library_clips (author_profile_id)
  where author_profile_id is not null;

insert into private.library_clips (id) values
  ('open-air-group'),
  ('street-style-group'),
  ('night-plaza-solo'),
  ('studio-mirror'),
  ('holiday-duet'),
  ('room-formation'),
  ('evening-plaza-duet'),
  ('studio-partner'),
  ('group-studio'),
  ('hallway-take');

create table private.library_clip_likes (
  clip_id text not null references private.library_clips(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  primary key (clip_id, user_id)
);
create index library_clip_likes_user on private.library_clip_likes (user_id);

alter table private.library_clips enable row level security;
alter table private.library_clip_likes enable row level security;
revoke all on private.library_clips, private.library_clip_likes
  from public, anon, authenticated;

alter table public.comments
  alter column post_id drop not null,
  add column library_clip_id text references private.library_clips(id) on delete cascade,
  add constraint comments_one_parent check ((post_id is null) <> (library_clip_id is null));
create index library_clip_comments_timeline
  on public.comments (library_clip_id, created_at desc, id desc)
  where library_clip_id is not null;

create function private.can_see_library_clip(p_clip_id text) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.active((select auth.uid())) and exists (
    select 1 from private.library_clips c where c.id = p_clip_id and c.active
  );
$$;

create function private.can_see_comment_parent(p_post_id uuid, p_clip_id text) returns boolean
language sql stable security invoker set search_path = '' as $$
  select case when p_post_id is not null then private.can_see_post(p_post_id)
    else private.can_see_library_clip(p_clip_id) end;
$$;

alter policy comments_read on public.comments using (
  private.can_see_comment_parent(post_id, library_clip_id)
  and private.can_see_user(author_id)
  and (status = 'approved' or author_id = (select auth.uid()))
  and not exists (
    select 1 from public.reports r where r.reporter_id = (select auth.uid())
      and r.target_type = 'comment' and r.target_id = comments.id
  )
);

create function private.library_clip_like_stats(p_clip_id text)
returns table (clip_id text, likes_count bigint, liked boolean, author_profile_id uuid)
language sql stable security definer set search_path = '' as $$
  select c.id,
    (select count(*) from private.library_clip_likes l where l.clip_id = c.id),
    exists (select 1 from private.library_clip_likes l
      where l.clip_id = c.id and l.user_id = (select auth.uid())),
    case when private.can_see_user(c.author_profile_id) then c.author_profile_id end
  from private.library_clips c
  where c.active and (p_clip_id is null or c.id = p_clip_id)
    and (select private.active(auth.uid()));
$$;

create function private.library_clip_stats(p_clip_id text)
returns table (clip_id text, likes_count bigint, comments_count bigint, liked boolean, author jsonb)
language sql stable security invoker set search_path = '' as $$
  select s.clip_id, s.likes_count,
    (select count(*) from public.comments c
      where c.library_clip_id = s.clip_id and c.status = 'approved'),
    s.liked, public.get_dancer(s.author_profile_id)
  from private.library_clip_like_stats(p_clip_id) s;
$$;

create function public.get_library_clip_stats()
returns table (clip_id text, likes_count bigint, comments_count bigint, liked boolean, author jsonb)
language sql stable security invoker set search_path = '' as $$
  select * from private.library_clip_stats(null);
$$;

create function private.write_library_clip_like(p_clip_id text, p_liked boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_account();
  if p_liked is null or not private.can_see_library_clip(p_clip_id) then
    raise exception 'This video is unavailable.';
  end if;
  if p_liked then
    insert into private.library_clip_likes (clip_id, user_id) values (p_clip_id, auth.uid())
      on conflict (clip_id, user_id) do nothing;
  else
    delete from private.library_clip_likes where clip_id = p_clip_id and user_id = auth.uid();
  end if;
end;
$$;

create function public.set_library_clip_like(p_clip_id text, p_liked boolean) returns jsonb
language plpgsql security invoker set search_path = '' as $$
begin
  perform private.write_library_clip_like(p_clip_id, p_liked);
  return (select to_jsonb(s) from private.library_clip_stats(p_clip_id) s);
end;
$$;

create function public.get_library_clip_comments(
  p_clip_id text,
  p_before_created timestamptz default null,
  p_before_id uuid default null
) returns setof jsonb
language sql stable security invoker set search_path = '' as $$
  with page as (
    select c.id, c.author_id, c.body, c.status, c.created_at
    from public.comments c
    where c.library_clip_id = p_clip_id
      and (p_before_created is null) = (p_before_id is null)
      and (p_before_created is null or (c.created_at, c.id) < (p_before_created, p_before_id))
    order by c.created_at desc, c.id desc
    limit 51
  )
  select to_jsonb(page) || jsonb_build_object('author', public.get_dancer(page.author_id))
  from page order by page.created_at desc, page.id desc;
$$;

create function private.submit_library_clip_comment(p_clip_id text, p_body text, p_client_id uuid)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  saved_id uuid;
  comment_body text := trim(p_body);
begin
  perform private.require_account();
  if not private.can_see_library_clip(p_clip_id) then
    raise exception 'This video is unavailable.';
  end if;
  if p_client_id is null or comment_body is null or char_length(comment_body) not between 1 and 1000 then
    raise exception 'Enter a comment between 1 and 1,000 characters.';
  end if;
  insert into public.comments (library_clip_id, author_id, body, client_id)
    values (p_clip_id, auth.uid(), comment_body, p_client_id)
    on conflict (author_id, client_id) do nothing returning id into saved_id;
  if saved_id is null then
    select id into saved_id from public.comments
    where author_id = auth.uid() and client_id = p_client_id and library_clip_id = p_clip_id;
    if not found then raise exception 'This comment could not be saved. Please try again.'; end if;
  end if;
  return saved_id;
end;
$$;

create function public.submit_library_clip_comment(p_clip_id text, p_body text, p_client_id uuid)
returns uuid
language sql security invoker set search_path = '' as $$
  select private.submit_library_clip_comment(p_clip_id, p_body, p_client_id);
$$;

create or replace function private.edit_content(p_type text, p_id uuid, p_body text, p_style text default null)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_account();
  if p_type = 'post' then
    update public.posts set caption = trim(p_body), style = p_style, status = 'pending'
      where id = p_id and author_id = auth.uid();
  elsif p_type = 'comment' then
    update public.comments set body = trim(p_body), status = 'pending'
      where id = p_id and author_id = auth.uid()
        and private.can_see_comment_parent(post_id, library_clip_id);
  else
    raise exception 'Unknown content.';
  end if;
  if not found then raise exception 'This content is unavailable.'; end if;
end;
$$;

create or replace function private.report_content(p_type text, p_target uuid, p_reason text)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_account();
  if p_type = 'post' and not private.can_see_post(p_target) then
    raise exception 'This post is unavailable.';
  end if;
  if p_type = 'user' and not private.can_see_user(p_target) then
    raise exception 'This dancer is unavailable.';
  end if;
  if p_type = 'comment' and not exists (
    select 1 from public.comments c where c.id = p_target
      and private.can_see_comment_parent(c.post_id, c.library_clip_id)
      and (c.post_id is not null or (
        private.can_see_user(c.author_id) and (c.status = 'approved' or c.author_id = auth.uid())
      ))
  ) then
    raise exception 'This comment is unavailable.';
  end if;
  if p_type = 'message' and not exists (
    select 1 from public.messages m where m.id = p_target and auth.uid() in (m.sender_id, m.recipient_id)
  ) then
    raise exception 'This message is unavailable.';
  end if;
  insert into public.reports (reporter_id, target_type, target_id, reason)
    values (auth.uid(), p_type, p_target, p_reason)
    on conflict (reporter_id, target_type, target_id) do nothing;
end;
$$;

revoke all on function
  private.can_see_library_clip(text), private.can_see_comment_parent(uuid, text),
  private.library_clip_like_stats(text), private.library_clip_stats(text),
  private.write_library_clip_like(text, boolean), private.submit_library_clip_comment(text, text, uuid),
  public.get_library_clip_stats(), public.set_library_clip_like(text, boolean),
  public.get_library_clip_comments(text, timestamptz, uuid), public.submit_library_clip_comment(text, text, uuid)
  from public, anon, authenticated;
grant execute on function
  private.can_see_library_clip(text), private.can_see_comment_parent(uuid, text),
  private.library_clip_like_stats(text), private.library_clip_stats(text),
  private.write_library_clip_like(text, boolean), private.submit_library_clip_comment(text, text, uuid),
  public.get_library_clip_stats(), public.set_library_clip_like(text, boolean),
  public.get_library_clip_comments(text, timestamptz, uuid), public.submit_library_clip_comment(text, text, uuid)
  to authenticated;

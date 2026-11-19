-- Stable keyset pages: one extra row advertises the next page. All reads retain RLS.
create function public.get_feed_page(
 p_style text default null, p_author uuid default null, p_saved boolean default false,
 p_challenge text default null, p_before_created timestamptz default null, p_before_id uuid default null
) returns setof jsonb language sql stable security invoker set search_path='' as $$
 select to_jsonb(p)||jsonb_build_object(
  'author',public.get_dancer(p.author_id),
  'likes_count',(select count(*) from public.likes l where l.post_id=p.id),
  'comments_count',(select count(*) from public.comments c where c.post_id=p.id and c.status='approved'),
  'liked',exists(select 1 from public.likes l where l.post_id=p.id and l.user_id=(select auth.uid())),
  'saved',exists(select 1 from public.saves s where s.post_id=p.id and s.user_id=(select auth.uid())))
 from public.posts p
 where (p_style is null or p.style=p_style) and (p_author is null or p.author_id=p_author)
  and (p_challenge is null or p.challenge_id=p_challenge)
  and (p.status='approved' or p_author=(select auth.uid()))
  and (not p_saved or exists(select 1 from public.saves s where s.post_id=p.id and s.user_id=(select auth.uid())))
  and (p_before_created is null or (p.created_at,p.id)<(p_before_created,p_before_id))
 order by p.created_at desc,p.id desc limit 21;
$$;

-- Reading existing history does not require continuing mutual follows; sending still does.
create function public.get_thread_page(
 p_peer uuid, p_before_created timestamptz default null, p_before_id uuid default null
) returns setof jsonb language sql stable security invoker set search_path='' as $$
 with history as (
  (select m.* from public.messages m
   where m.sender_id=(select auth.uid()) and m.recipient_id=p_peer
    and (p_before_created is null or (m.created_at,m.id)<(p_before_created,p_before_id))
   order by m.created_at desc,m.id desc limit 51)
  union all
  (select m.* from public.messages m
   where m.sender_id=p_peer and m.recipient_id=(select auth.uid())
    and (p_before_created is null or (m.created_at,m.id)<(p_before_created,p_before_id))
   order by m.created_at desc,m.id desc limit 51)
 ) select to_jsonb(h) from history h order by h.created_at desc,h.id desc limit 51;
$$;

create function public.get_inbox_page(
 p_before_created timestamptz default null, p_before_id uuid default null
) returns setof jsonb language sql stable security invoker set search_path='' as $$
 with visible as (
  select m.*,case when m.sender_id=(select auth.uid()) then m.recipient_id else m.sender_id end peer
  from public.messages m where m.sender_id=(select auth.uid()) or m.recipient_id=(select auth.uid())
 ), latest as (
  select distinct on (v.peer) v.* from visible v order by v.peer,v.created_at desc,v.id desc
 ) select jsonb_build_object('id',l.id,'peer',public.get_dancer(l.peer),'body',l.body,
   'created_at',l.created_at,'unread',(select count(*) from public.messages m
    where m.sender_id=l.peer and m.recipient_id=(select auth.uid()) and m.read_at is null))
 from latest l where (p_before_created is null or (l.created_at,l.id)<(p_before_created,p_before_id))
 order by l.created_at desc,l.id desc limit 26;
$$;

revoke execute on function public.get_feed_page(text,uuid,boolean,text,timestamptz,uuid),
 public.get_thread_page(uuid,timestamptz,uuid),public.get_inbox_page(timestamptz,uuid) from public,anon;
grant execute on function public.get_feed_page(text,uuid,boolean,text,timestamptz,uuid),
 public.get_thread_page(uuid,timestamptz,uuid),public.get_inbox_page(timestamptz,uuid) to authenticated;

create index profiles_timeline on public.profiles(created_at desc,id desc);
create index posts_timeline on public.posts(created_at desc,id desc) where status='approved';
create index posts_author_timeline on public.posts(author_id,created_at desc,id desc);
create index comments_timeline on public.comments(post_id,created_at desc,id desc);
create index follows_incoming_timeline on public.follows(following_id,created_at desc,follower_id desc);
create index follows_outgoing_timeline on public.follows(follower_id,created_at desc,following_id desc);
create index messages_thread_timeline on public.messages(sender_id,recipient_id,created_at desc,id desc);
create index reports_owner_timeline on public.reports(reporter_id,created_at desc,id desc);
create index ledger_owner_timeline on public.wallet_ledger(user_id,created_at desc,id desc);
create index posts_review_timeline on public.posts(created_at,id) where status='pending';
create index comments_review_timeline on public.comments(created_at,id) where status='pending';
create index reports_review_timeline on public.reports(created_at,id) where status='open';

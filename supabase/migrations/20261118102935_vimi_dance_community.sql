-- Vimi: Flutter/Android only. All client-visible data has explicit grants and RLS.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;

create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null check(char_length(display_name) between 2 and 40),
 bio text not null default '' check(char_length(bio)<=280),
 styles text[] not null default array['K-pop']::text[] check(cardinality(styles) between 1 and 4 and styles <@ array['K-pop','Girl group','Boy group','Freestyle']::text[]),
 avatar_path text,
 created_at timestamptz not null default now()
);
create table private.accounts (
 id uuid primary key references auth.users(id) on delete cascade,
 birth_date date not null,
 consent_version text not null,
 status text not null default 'active' check(status in ('active','suspended','deleting'))
);
create table public.challenges (
 id text primary key, title text not null, style text not null, counts integer not null check(counts>0), description text not null, prompts jsonb not null
);
create table public.posts (
 id uuid primary key default gen_random_uuid(), author_id uuid not null references public.profiles(id) on delete cascade,
 caption text not null check(char_length(caption) between 1 and 2000), style text not null check(style in ('K-pop','Girl group','Boy group','Freestyle')),
 media_path text not null unique, media_kind text not null check(media_kind in ('image','video')),
 challenge_id text references public.challenges(id), status text not null default 'pending' check(status in ('pending','approved','rejected')),
 client_id uuid not null, created_at timestamptz not null default now(), unique(author_id,client_id)
);
create index posts_feed on public.posts(created_at desc) where status='approved';
create index posts_author on public.posts(author_id,created_at desc);
create index posts_challenge on public.posts(challenge_id,created_at desc) where status='approved';
create table public.comments (
 id uuid primary key default gen_random_uuid(),post_id uuid not null references public.posts(id) on delete cascade,
 author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check(char_length(body) between 1 and 1000),status text not null default 'pending' check(status in ('pending','approved','rejected')),
 client_id uuid not null,created_at timestamptz not null default now(),unique(author_id,client_id)
);
create index comments_post on public.comments(post_id,created_at);
create index comments_author on public.comments(author_id);
create table public.follows (
 follower_id uuid not null references public.profiles(id) on delete cascade,following_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),primary key(follower_id,following_id),check(follower_id<>following_id)
);
create index follows_incoming on public.follows(following_id,follower_id);
create table public.blocks (
 blocker_id uuid not null references public.profiles(id) on delete cascade,blocked_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(),primary key(blocker_id,blocked_id),check(blocker_id<>blocked_id)
);
create index blocks_incoming on public.blocks(blocked_id,blocker_id);
create table public.likes (user_id uuid not null references public.profiles(id) on delete cascade,post_id uuid not null references public.posts(id) on delete cascade,primary key(user_id,post_id));
create index likes_post on public.likes(post_id);
create table public.saves (user_id uuid not null references public.profiles(id) on delete cascade,post_id uuid not null references public.posts(id) on delete cascade,primary key(user_id,post_id));
create index saves_post on public.saves(post_id);
create table public.reports (
 id uuid primary key default gen_random_uuid(),reporter_id uuid not null references public.profiles(id) on delete cascade,
 target_type text not null check(target_type in ('post','comment','user','message')),target_id uuid not null,
 reason text not null check(reason in ('Harassment','Sexual content','Hate or violence','Copyright','Spam or scam','Privacy','Underage user','Other')),
 status text not null default 'open' check(status in ('open','resolved')),created_at timestamptz not null default now(),unique(reporter_id,target_type,target_id)
);
create index reports_queue on public.reports(created_at) where status='open';
create table public.messages (
 id uuid primary key default gen_random_uuid(),sender_id uuid not null references public.profiles(id) on delete cascade,recipient_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check(char_length(body) between 1 and 2000),client_id uuid not null,created_at timestamptz not null default now(),read_at timestamptz,
 check(sender_id<>recipient_id),unique(sender_id,client_id)
);
create index messages_inbox on public.messages(recipient_id,created_at desc);
create index messages_sent on public.messages(sender_id,recipient_id,created_at desc);
create table public.wallets(user_id uuid primary key references public.profiles(id) on delete cascade,balance bigint not null default 0 check(balance>=0));
create table public.coin_products(id text primary key,coins integer not null check(coins>0),active boolean not null default true);
create table public.studio_packs(id text primary key,title text not null,cost integer not null check(cost>0));
create table public.pack_unlocks(user_id uuid not null references public.profiles(id) on delete cascade,pack_id text not null references public.studio_packs(id),created_at timestamptz not null default now(),primary key(user_id,pack_id));
create index unlocks_pack on public.pack_unlocks(pack_id);
create table public.wallet_ledger (
 id uuid primary key default gen_random_uuid(),user_id uuid references public.profiles(id) on delete set null,
 delta bigint not null,description text not null,reference text not null unique,created_at timestamptz not null default now()
);
create index ledger_user on public.wallet_ledger(user_id,created_at desc);
create table private.play_purchases (
 token_hash text primary key,user_id uuid references auth.users(id) on delete set null,product_id text not null references public.coin_products(id),order_id text not null,
 coins bigint not null,created_at timestamptz not null default now(),voided_at timestamptz
);
create index purchases_user on private.play_purchases(user_id);
create index purchases_product on private.play_purchases(product_id);

create function private.active(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from private.accounts a where a.id=p_id and a.status='active');
$$;
create function private.can_see_user(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.active(auth.uid()) and private.active(p_id) and not exists(select 1 from public.blocks b where (b.blocker_id=auth.uid() and b.blocked_id=p_id) or (b.blocker_id=p_id and b.blocked_id=auth.uid()))
 and not exists(select 1 from public.reports r where r.reporter_id=auth.uid() and r.target_type='user' and r.target_id=p_id);
$$;
create function private.can_see_post(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.posts p where p.id=p_id and private.can_see_user(p.author_id) and (p.status='approved' or p.author_id=auth.uid())
 and not exists(select 1 from public.reports r where r.reporter_id=auth.uid() and r.target_type='post' and r.target_id=p.id));
$$;
create function private.can_chat(p_peer uuid) returns boolean language sql stable security definer set search_path='' as $$
 select p_peer<>auth.uid() and private.can_see_user(p_peer) and exists(select 1 from public.follows where follower_id=auth.uid() and following_id=p_peer) and exists(select 1 from public.follows where follower_id=p_peer and following_id=auth.uid());
$$;
create function private.lock_pair(p_peer uuid) returns void language sql volatile security definer set search_path='' as $$
 select pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(least(auth.uid()::text,p_peer::text)||greatest(auth.uid()::text,p_peer::text),0));
$$;
create function private.require_account() returns void language plpgsql stable security definer set search_path='' as $$
 begin if auth.uid() is null or not private.active(auth.uid()) then raise exception 'Sign in to continue.'; end if; end;
$$;
create function private.provision_dancer() returns trigger language plpgsql security definer set search_path='' as $$
 declare birth date; dancer_name text;
 begin
  birth:=(new.raw_user_meta_data->>'birth_date')::date;
  if birth is null or birth>current_date-interval '18 years' or birth<date '1900-01-01' then raise exception 'Vimi is for adults aged 18 and over.'; end if;
  if new.raw_user_meta_data->>'consent_version'<>'2026-11-18' then raise exception 'Accept the Terms and Privacy Policy.'; end if;
  dancer_name:=trim(new.raw_user_meta_data->>'display_name');
  insert into private.accounts(id,birth_date,consent_version) values(new.id,birth,'2026-11-18');
  insert into public.profiles(id,display_name) values(new.id,dancer_name);
  insert into public.wallets(user_id) values(new.id);
  return new;
 end;
$$;
create trigger provision_vimi_account after insert on auth.users for each row execute function private.provision_dancer();

-- Security-definer helpers are confined to a non-exposed schema with fixed paths.
revoke all on all functions in schema private from public,anon,authenticated;
grant execute on function private.active(uuid),private.can_see_user(uuid),private.can_see_post(uuid),private.can_chat(uuid) to authenticated;

alter table public.profiles enable row level security;
create policy profiles_read on public.profiles for select to authenticated using(private.can_see_user(id));
alter table public.challenges enable row level security;
create policy challenges_read on public.challenges for select to authenticated using(private.active((select auth.uid())));
alter table public.posts enable row level security;
create policy posts_read on public.posts for select to authenticated using(private.can_see_post(id));
create policy posts_delete on public.posts for delete to authenticated using(author_id=(select auth.uid()) and private.active((select auth.uid())));
alter table public.comments enable row level security;
create policy comments_read on public.comments for select to authenticated using(private.can_see_post(post_id) and private.can_see_user(author_id) and (status='approved' or author_id=(select auth.uid())) and not exists(select 1 from public.reports r where r.reporter_id=(select auth.uid()) and r.target_type='comment' and r.target_id=comments.id));
create policy comments_delete on public.comments for delete to authenticated using(author_id=(select auth.uid()) and private.active((select auth.uid())));
alter table public.follows enable row level security;
create policy follows_read on public.follows for select to authenticated using(private.can_see_user(follower_id) and private.can_see_user(following_id));
alter table public.blocks enable row level security;
create policy blocks_read on public.blocks for select to authenticated using(blocker_id=(select auth.uid()));
alter table public.likes enable row level security;
create policy likes_read on public.likes for select to authenticated using(private.can_see_post(post_id));
alter table public.saves enable row level security;
create policy saves_read on public.saves for select to authenticated using(user_id=(select auth.uid()) and private.can_see_post(post_id));
alter table public.reports enable row level security;
create policy reports_read on public.reports for select to authenticated using(reporter_id=(select auth.uid()));
alter table public.messages enable row level security;
create policy messages_read on public.messages for select to authenticated using((sender_id=(select auth.uid()) or recipient_id=(select auth.uid())) and private.can_see_user(sender_id) and private.can_see_user(recipient_id) and not exists(select 1 from public.reports r where r.reporter_id=(select auth.uid()) and r.target_type='message' and r.target_id=messages.id));
alter table public.wallets enable row level security;
create policy wallet_read on public.wallets for select to authenticated using(user_id=(select auth.uid()) and private.active((select auth.uid())));
alter table public.coin_products enable row level security;
create policy products_read on public.coin_products for select to authenticated using(active);
alter table public.studio_packs enable row level security;
create policy packs_read on public.studio_packs for select to authenticated using(true);
alter table public.pack_unlocks enable row level security;
create policy unlocks_read on public.pack_unlocks for select to authenticated using(user_id=(select auth.uid()));
alter table public.wallet_ledger enable row level security;
create policy ledger_read on public.wallet_ledger for select to authenticated using(user_id=(select auth.uid()));
alter table private.accounts enable row level security;
alter table private.play_purchases enable row level security;
revoke all on all tables in schema public from anon,authenticated;
grant select on all tables in schema public to authenticated;
grant delete on public.posts,public.comments to authenticated;
grant all on all tables in schema public,private to service_role;

create function public.get_dancer(p_id uuid) returns jsonb language sql stable security invoker set search_path='' as $$
 select to_jsonb(p)||jsonb_build_object('followers_count',(select count(*) from public.follows where following_id=p.id),'following_count',(select count(*) from public.follows where follower_id=p.id),'is_following',exists(select 1 from public.follows where follower_id=auth.uid() and following_id=p.id),'follows_you',exists(select 1 from public.follows where follower_id=p.id and following_id=auth.uid())) from public.profiles p where id=p_id;
$$;
create function public.get_feed(p_style text default null,p_author uuid default null,p_saved boolean default false,p_offset integer default 0,p_challenge text default null) returns setof jsonb language sql stable security invoker set search_path='' as $$
 select to_jsonb(p)||jsonb_build_object('author',public.get_dancer(p.author_id),'likes_count',(select count(*) from public.likes l where l.post_id=p.id),'comments_count',(select count(*) from public.comments c where c.post_id=p.id and c.status='approved'),'liked',exists(select 1 from public.likes l where l.post_id=p.id and l.user_id=auth.uid()),'saved',exists(select 1 from public.saves s where s.post_id=p.id and s.user_id=auth.uid()))
 from public.posts p where (p_style is null or p.style=p_style) and (p_author is null or p.author_id=p_author) and (p_challenge is null or p.challenge_id=p_challenge)
 and (p.status='approved' or p_author=auth.uid()) and (not p_saved or exists(select 1 from public.saves s where s.post_id=p.id and s.user_id=auth.uid())) order by p.created_at desc,p.id desc limit 20 offset greatest(0,least(p_offset,10000));
$$;
create function public.update_dancer(p_name text,p_bio text,p_styles text[],p_avatar text default null) returns void language plpgsql security definer set search_path='' as $$
 begin perform private.require_account();
 if p_avatar is not null and (split_part(p_avatar,'/',1)<>auth.uid()::text or p_avatar not like '%/avatar/%') then raise exception 'Invalid avatar.';end if;
 update public.profiles set display_name=trim(p_name),bio=trim(p_bio),styles=p_styles,avatar_path=p_avatar where id=auth.uid();end;
$$;
create function public.toggle_follow(p_peer uuid) returns boolean language plpgsql security definer set search_path='' as $$
 begin perform private.require_account();perform private.lock_pair(p_peer);
 if not private.can_see_user(p_peer) or p_peer=auth.uid() then raise exception 'This dancer is unavailable.';end if;
 if exists(select 1 from public.follows where follower_id=auth.uid() and following_id=p_peer) then delete from public.follows where follower_id=auth.uid() and following_id=p_peer;return false;end if;
 insert into public.follows(follower_id,following_id)values(auth.uid(),p_peer);return true;end;
$$;
create function public.set_block(p_peer uuid,p_blocked boolean) returns void language plpgsql security definer set search_path='' as $$
 begin perform private.require_account();perform private.lock_pair(p_peer);
 if p_peer=auth.uid() then raise exception 'Choose another dancer.';end if;
 if p_blocked then insert into public.blocks(blocker_id,blocked_id)values(auth.uid(),p_peer)on conflict do nothing;delete from public.follows where(follower_id=auth.uid() and following_id=p_peer)or(follower_id=p_peer and following_id=auth.uid());else delete from public.blocks where blocker_id=auth.uid() and blocked_id=p_peer;end if;end;
$$;
create function public.get_blocked() returns setof jsonb language plpgsql security definer set search_path='' as $$
 begin perform private.require_account();return query select jsonb_build_object('id',p.id,'display_name',p.display_name,'styles',p.styles)from public.blocks b join public.profiles p on p.id=b.blocked_id where b.blocker_id=auth.uid();end;
$$;
create function public.can_message(p_peer uuid)returns boolean language sql stable security invoker set search_path='' as $$select private.can_chat(p_peer);$$;
create function public.send_message(p_peer uuid,p_body text,p_client_id uuid) returns uuid language plpgsql security definer set search_path='' as $$
 declare result uuid;
 begin perform private.require_account();perform private.lock_pair(p_peer);
 if not private.can_chat(p_peer)then raise exception 'Messages require mutual follows and no blocks.';end if;
 insert into public.messages(sender_id,recipient_id,body,client_id)values(auth.uid(),p_peer,trim(p_body),p_client_id)on conflict(sender_id,client_id)do update set client_id=excluded.client_id returning id into result;return result;end;
$$;
create function public.mark_read(p_peer uuid)returns void language plpgsql security definer set search_path='' as $$begin perform private.require_account();if not private.can_see_user(p_peer)then return;end if;update public.messages set read_at=now()where sender_id=p_peer and recipient_id=auth.uid()and read_at is null;end;$$;
create function public.get_inbox() returns setof jsonb language sql stable security invoker set search_path='' as $$
 with latest as(select distinct on(case when sender_id=auth.uid()then recipient_id else sender_id end) m.*,case when sender_id=auth.uid()then recipient_id else sender_id end peer from public.messages m order by case when sender_id=auth.uid()then recipient_id else sender_id end,created_at desc)
 select jsonb_build_object('peer',public.get_dancer(l.peer),'body',l.body,'created_at',l.created_at,'unread',(select count(*)from public.messages m where m.sender_id=l.peer and m.recipient_id=auth.uid()and m.read_at is null))from latest l order by l.created_at desc limit 100;
$$;
create function public.submit_post(p_caption text,p_style text,p_media_path text,p_kind text,p_client_id uuid,p_challenge text default null)returns uuid language plpgsql security definer set search_path='' as $$
 declare result uuid;
 begin perform private.require_account();
 if split_part(p_media_path,'/',1)<>auth.uid()::text or p_media_path not like '%/posts/%'or not exists(select 1 from storage.objects o where o.bucket_id='dance-media'and o.name=p_media_path and o.owner_id=auth.uid()::text)then raise exception 'Upload your media before publishing.';end if;
 insert into public.posts(author_id,caption,style,media_path,media_kind,challenge_id,client_id)values(auth.uid(),trim(p_caption),p_style,p_media_path,p_kind,p_challenge,p_client_id)on conflict(author_id,client_id)do update set client_id=excluded.client_id returning id into result;return result;end;
$$;
create function public.submit_comment(p_post uuid,p_body text,p_client_id uuid)returns void language plpgsql security definer set search_path='' as $$
 begin perform private.require_account();if not private.can_see_post(p_post)or not exists(select 1 from public.posts where id=p_post and status='approved')then raise exception 'This post is unavailable.';end if;
 insert into public.comments(post_id,author_id,body,client_id)values(p_post,auth.uid(),trim(p_body),p_client_id)on conflict(author_id,client_id)do nothing;end;
$$;
create function public.toggle_post_action(p_post uuid,p_action text)returns void language plpgsql security definer set search_path='' as $$
 begin perform private.require_account();if not private.can_see_post(p_post)then raise exception 'This post is unavailable.';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text||p_post::text||p_action,0));
 if p_action='like'then if exists(select 1 from public.likes where user_id=auth.uid()and post_id=p_post)then delete from public.likes where user_id=auth.uid()and post_id=p_post;else insert into public.likes values(auth.uid(),p_post);end if;
 elsif p_action='save'then if exists(select 1 from public.saves where user_id=auth.uid()and post_id=p_post)then delete from public.saves where user_id=auth.uid()and post_id=p_post;else insert into public.saves values(auth.uid(),p_post);end if;
 else raise exception 'Unknown post action.';end if;end;
$$;
create function public.report_content(p_type text,p_target uuid,p_reason text)returns void language plpgsql security definer set search_path='' as $$
 begin perform private.require_account();
 if p_type='post'and not private.can_see_post(p_target)then raise exception 'This post is unavailable.';end if;
 if p_type='user'and not private.can_see_user(p_target)then raise exception 'This dancer is unavailable.';end if;
 if p_type='comment'and not exists(select 1 from public.comments c where c.id=p_target and private.can_see_post(c.post_id))then raise exception 'This comment is unavailable.';end if;
 if p_type='message'and not exists(select 1 from public.messages where id=p_target and auth.uid()in(sender_id,recipient_id))then raise exception 'This message is unavailable.';end if;
 insert into public.reports(reporter_id,target_type,target_id,reason)values(auth.uid(),p_type,p_target,p_reason)on conflict(reporter_id,target_type,target_id)do nothing;end;
$$;
create function public.unlock_studio_pack(p_pack text)returns bigint language plpgsql security definer set search_path='' as $$
 declare price integer; funds bigint;
 begin perform private.require_account();select balance into funds from public.wallets where user_id=auth.uid()for update;
 if exists(select 1 from public.pack_unlocks where user_id=auth.uid()and pack_id=p_pack)then return funds;end if;
 select cost into strict price from public.studio_packs where id=p_pack;
 if funds<price then raise exception 'Not enough coins. Add coins to unlock this pack.';end if;
 update public.wallets set balance=balance-price where user_id=auth.uid()returning balance into funds;
 insert into public.pack_unlocks(user_id,pack_id)values(auth.uid(),p_pack);
 insert into public.wallet_ledger(user_id,delta,description,reference)values(auth.uid(),-price,'Studio pack: '||p_pack,'pack:'||auth.uid()::text||':'||p_pack);return funds;end;
$$;
-- Service-only receipt grant: no app-supplied coin amount and no duplicate credits.
create function public.credit_play_purchase(p_user uuid,p_token_hash text,p_product text,p_order text)returns bigint language plpgsql security definer set search_path='' as $$
 declare amount integer;funds bigint;existing uuid;
 begin
 if (current_setting('request.jwt.claims',true)::jsonb->>'role')is distinct from 'service_role'then raise exception 'Server only.';end if;
 if not private.active(p_user)then raise exception 'Account unavailable.';end if;
 select balance into funds from public.wallets where user_id=p_user for update;
 select user_id into existing from private.play_purchases where token_hash=p_token_hash;
 if found then if existing is distinct from p_user then raise exception 'Purchase belongs to another account.';end if;return funds;end if;
 select coins into strict amount from public.coin_products where id=p_product and active;
 insert into private.play_purchases(token_hash,user_id,product_id,order_id,coins)values(p_token_hash,p_user,p_product,p_order,amount);
 update public.wallets set balance=balance+amount where user_id=p_user returning balance into funds;
 insert into public.wallet_ledger(user_id,delta,description,reference)values(p_user,amount,'Google Play coin purchase',p_token_hash);return funds;
 end;
$$;

insert into public.coin_products(id,coins)values('vimi_coins_100',100),('vimi_coins_350',350),('vimi_coins_600',600),('vimi_coins_1300',1300),('vimi_coins_2800',2800),('vimi_coins_7500',7500),('vimi_coins_16000',16000);
insert into public.studio_packs(id,title,cost)values('chorus-builder','Chorus Builder',120),('formation-notes','Formation Notes',180),('comeback-planner','Comeback Planner',240);
insert into public.challenges(id,title,style,counts,description,prompts)values
('clean-chorus','Make the chorus yours','Girl group',32,'Choose a chorus you have permission to use. Find four eight-count phrases and make each ending clear.','["Mark the four phrase endings","Practice the transitions at a slower tempo","Record one full take without stopping"]'),
('precision-eight','One sharp eight','Boy group',8,'A short phrase, full commitment. Work on isolations, clean accents and a deliberate final shape.','["Choose eight counts of your own movement","Separate the accents from the transitions","Film a relaxed take and a full-energy take"]'),
('one-take','Your one-take moment','K-pop',64,'Bring your own routine to a complete one-take cover. Tell the community which part you practiced most.','["Warm up and mark your floor space","Run the routine once at comfortable energy","Share a single continuous take with your practice note"]');

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)values('dance-media','dance-media',false,52428800,array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime']);
create policy media_insert on storage.objects for insert to authenticated with check(bucket_id='dance-media'and (storage.foldername(name))[1]=(select auth.uid())::text and private.active((select auth.uid())));
create policy media_read on storage.objects for select to authenticated using(bucket_id='dance-media'and (owner_id=(select auth.uid())::text or exists(select 1 from public.posts p where p.media_path=objects.name and p.status='approved'and private.can_see_post(p.id))or exists(select 1 from public.profiles p where p.avatar_path=objects.name and private.can_see_user(p.id))));
create policy media_delete on storage.objects for delete to authenticated using(bucket_id='dance-media'and owner_id=(select auth.uid())::text);

revoke all on all functions in schema public from public,anon,authenticated;
grant execute on function public.get_dancer(uuid),public.get_feed(text,uuid,boolean,integer,text),public.update_dancer(text,text,text[],text),public.toggle_follow(uuid),public.set_block(uuid,boolean),public.get_blocked(),public.can_message(uuid),public.send_message(uuid,text,uuid),public.mark_read(uuid),public.get_inbox(),public.submit_post(text,text,text,text,uuid,text),public.submit_comment(uuid,text,uuid),public.toggle_post_action(uuid,text),public.report_content(text,uuid,text),public.unlock_studio_pack(text) to authenticated;
grant execute on function public.credit_play_purchase(uuid,text,text,text)to service_role;
alter publication supabase_realtime add table public.messages;

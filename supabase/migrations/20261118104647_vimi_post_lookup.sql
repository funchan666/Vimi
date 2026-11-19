create function public.get_post(p_id uuid)returns jsonb language sql stable security invoker set search_path='' as $$
 select to_jsonb(p)||jsonb_build_object('author',public.get_dancer(p.author_id),'likes_count',(select count(*)from public.likes l where l.post_id=p.id),'comments_count',(select count(*)from public.comments c where c.post_id=p.id and c.status='approved'),'liked',exists(select 1 from public.likes l where l.post_id=p.id and l.user_id=auth.uid()),'saved',exists(select 1 from public.saves s where s.post_id=p.id and s.user_id=auth.uid()))from public.posts p where p.id=p_id;
$$;
revoke all on function public.get_post(uuid)from public,anon,authenticated;
grant execute on function public.get_post(uuid)to authenticated;

create function private.edit_content(p_type text,p_id uuid,p_body text,p_style text default null)returns void language plpgsql security definer set search_path='' as $$
 begin perform private.require_account();
 if p_type='post'then update public.posts set caption=trim(p_body),style=p_style,status='pending'where id=p_id and author_id=auth.uid();
 elsif p_type='comment'then update public.comments set body=trim(p_body),status='pending'where id=p_id and author_id=auth.uid()and private.can_see_post(post_id);
 else raise exception 'Unknown content.';end if;
 if not found then raise exception 'This content is unavailable.';end if;
 end;
$$;
create function public.edit_content(p_type text,p_id uuid,p_body text,p_style text default null)returns void language sql security invoker set search_path='' as $$select private.edit_content(p_type,p_id,p_body,p_style);$$;
revoke all on function private.edit_content(text,uuid,text,text),public.edit_content(text,uuid,text,text)from public,anon,authenticated;
grant execute on function private.edit_content(text,uuid,text,text),public.edit_content(text,uuid,text,text)to authenticated;

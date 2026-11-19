-- A previously issued JWT must not let a suspended or deleting owner mint new
-- media access. Existing short-lived signed URLs retain their original expiry.
drop policy media_read on storage.objects;
create policy media_read on storage.objects
for select to authenticated
using (
  bucket_id = 'dance-media'
  and private.active((select auth.uid()))
  and (
    owner_id = (select auth.uid())::text
    or exists (
      select 1 from public.posts p
      where p.media_path = objects.name
        and p.status = 'approved'
        and private.can_see_post(p.id)
    )
    or exists (
      select 1 from public.profiles p
      where p.avatar_path = objects.name
        and private.can_see_user(p.id)
    )
  )
);

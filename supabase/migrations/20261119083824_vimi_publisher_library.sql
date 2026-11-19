-- Publisher-owned reference media; member uploads stay in private dance-media.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('dance-library','dance-library',true,52428800,
        array['image/jpeg','image/png','image/webp','video/mp4']);

-- Narrow, insert-only import permission. Removed by the completion migration
-- after all public downloads match the local optimized source bytes.
create policy vimi_publisher_library_import on storage.objects
for insert to authenticated
with check (
  bucket_id = 'dance-library'
  and name ~ '^v1/(portraits|thumbnails|covers|videos)/[a-z0-9.-]+$'
  and (select auth.jwt()->'app_metadata'->>'vimi_role') = 'moderator'
  and private.active((select auth.uid()))
);

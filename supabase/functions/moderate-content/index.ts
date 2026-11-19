import { authenticated, reply, requestBody, uuid } from '../_shared/server.ts';
Deno.serve(async req => {
  try {
    const { admin, user } = await authenticated(req);
    if (user.app_metadata?.vimi_role !== 'moderator') return reply({ error: 'forbidden' }, 403);
    const access = await admin.rpc('moderator_access', { p_actor: user.id });
    if (access.error) throw access.error;
    if (access.data !== true) return reply({ error: 'forbidden' }, 403);
    const body = await requestBody(req);
    const { kind, id, status, action } = body;
    if (action === 'queue') {
      const section = body.section;
      const childSafetyOnly = body.child_safety_only === true;
      if (body.child_safety_only != null && typeof body.child_safety_only !== 'boolean') return reply({ error: 'invalid_filter' }, 400);
      const sections = ['posts', 'comments', 'reports'];
      if (section != null && !sections.includes(section)) return reply({ error: 'invalid_section' }, 400);
      if ((body.after_created == null) !== (body.after_id == null) ||
          (body.after_id != null && (!uuid(body.after_id) || typeof body.after_created !== 'string' ||
           !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$/.test(body.after_created) ||
           !Number.isFinite(Date.parse(body.after_created))))) return reply({ error: 'invalid_cursor' }, 400);
      const page = async (table: string, columns: string, status: string) => {
        if (section != null && section !== table) return { data: [], error: null };
        let request = admin.from(table).select(columns).eq('status', status);
        if (table === 'reports' && childSafetyOnly) request = request.in('reason', ['Child safety', 'Underage user']);
        if (section != null && body.after_id != null) {
          const time = body.after_created;
          request = request.or(`created_at.gt.${time},and(created_at.eq.${time},id.gt.${body.after_id})`);
        }
        return await request.order('created_at').order('id').limit(section == null ? 100 : 26);
      };
      const [posts, comments, reports] = await Promise.all([
        page('posts', 'id,author_id,caption,media_path,media_kind,created_at', 'pending'),
        page('comments', 'id,author_id,post_id,body,created_at', 'pending'),
        page('reports', '*', 'open'),
      ]);
      if (posts.error || comments.error || reports.error) throw new Error('queue_unavailable');
      type Row = Record<string, any>;
      const withMedia = async (post: Row) => {
        const signed = await admin.storage.from('dance-media').createSignedUrl(post.media_path, 300);
        return { ...post, review_url: signed.data?.signedUrl ?? null, media_unavailable: !!signed.error };
      };
      const reportRows = reports.data ?? [];
      const ids = (type: string) => [...new Set(reportRows.filter(r => r.target_type === type).map(r => r.target_id))];
      const lookup = async (table: string, columns: string, values: string[]): Promise<Row[]> => {
        if (!values.length) return [];
        const result = await admin.from(table).select(columns).in('id', values);
        if (result.error) throw new Error('queue_unavailable');
        return (result.data ?? []) as unknown as Row[];
      };
      const [reportedPosts, reportedComments, reportedUsers, reportedMessages] = await Promise.all([
        lookup('posts', 'id,author_id,caption,media_path,media_kind', ids('post')),
        lookup('comments', 'id,author_id,body,post_id', ids('comment')),
        lookup('profiles', 'id,display_name,bio,styles,avatar_path', ids('user')),
        lookup('messages', 'id,sender_id,body', ids('message')),
      ]);
      const targetSets: Record<string, Row[]> = { post: reportedPosts, comment: reportedComments, user: reportedUsers, message: reportedMessages };
      const reviewedReports = await Promise.all(reportRows.map(async report => {
        const target = targetSets[report.target_type]?.find(row => row.id === report.target_id);
        if (!target) return { ...report, target: null };
        return { ...report, target: {
          ...(report.target_type === 'post' ? await withMedia(target) :
            report.target_type === 'user' && target.avatar_path ? await withMedia({ ...target, media_path: target.avatar_path, media_kind: 'image' }) : target),
          review_author_id: report.target_type === 'user' ? target.id : target.author_id ?? target.sender_id,
        } };
      }));
      const media = await Promise.all((posts.data ?? []).map(withMedia));
      if (section != null) return reply({ items: section === 'posts' ? media : section === 'comments' ? comments.data : reviewedReports });
      return reply({ posts: media, comments: comments.data, reports: reviewedReports });
    }
    if (!uuid(id)) return reply({ error: 'invalid_id' }, 400);
    if (status === 'removed' && ['post', 'comment', 'message', 'user'].includes(kind as string)) {
      const table = kind === 'post' ? 'posts' : 'profiles';
      if (kind === 'post' || kind === 'user') {
        const existing = await admin.from(table).select(kind === 'post' ? 'media_path,author_id' : 'avatar_path,id').eq('id', id).maybeSingle();
        if (existing.error) throw existing.error;
        const row = existing.data as Record<string, any> | null;
        const media = row?.[kind === 'post' ? 'media_path' : 'avatar_path'];
        const owner = row?.[kind === 'post' ? 'author_id' : 'id'];
        if (media != null) {
          if (typeof media !== 'string' || !media.startsWith(`${owner}/${kind === 'post' ? 'posts' : 'avatar'}/`)) throw new Error('invalid_media_path');
          if (kind === 'post') {
            const hidden = await admin.from('posts').update({ status: 'rejected' }).eq('id', id);
            if (hidden.error) throw hidden.error;
          }
          const removed = await admin.storage.from('dance-media').remove([media]);
          if (removed.error) throw removed.error;
        }
      }
      const removed = await admin.rpc('remove_moderated_content', { p_actor: user.id, p_kind: kind, p_target: id });
      if (removed.error) throw removed.error;
      return reply({ updated: true, removed: true });
    }
    if ((kind === 'post' || kind === 'comment') && (status === 'approved' || status === 'rejected')) {
      const { data, error } = await admin.from(kind === 'post' ? 'posts' : 'comments').update({ status }).eq('id', id).select('id').maybeSingle();
      if (error) throw error;
      if (!data) return reply({ error: 'item_unavailable' }, 404);
    } else if (kind === 'report' && status === 'resolved') {
      const { data, error } = await admin.from('reports').update({ status }).eq('id', id).select('id').maybeSingle();
      if (error) throw error;
      if (!data) return reply({ error: 'item_unavailable' }, 404);
    } else if (kind === 'user' && (status === 'suspended' || status === 'active')) {
      const existing = await admin.from('profiles').select('id').eq('id', id).maybeSingle();
      if (existing.error) throw existing.error;
      if (!existing.data) return reply({ error: 'item_unavailable' }, 404);
      const { error } = await admin.rpc('moderate_account', { p_user: id, p_status: status });
      if (error) throw error;
    } else return reply({ error: 'invalid_action' }, 400);
    const { error: audit } = await admin.rpc('record_moderation', { p_actor: user.id, p_kind: kind, p_target: id, p_status: status });
    if (audit) throw audit;
    return reply({ updated: true });
  } catch (error) {
    if (error instanceof Error && error.message === 'unauthorized') return reply({ error: 'sign_in_required' }, 401);
    return reply({ error: 'moderation_unavailable' }, 503);
  }
});

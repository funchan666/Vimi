import { authenticated, reply, requestBody, uuid } from '../_shared/server.ts';
Deno.serve(async req => {
  try {
    const { admin, user } = await authenticated(req);
    if (user.app_metadata?.vimi_role !== 'moderator') return reply({ error: 'forbidden' }, 403);
    const body = await requestBody(req);
    const { kind, id, status, action } = body;
    if (action === 'queue') {
      const [posts, comments, reports] = await Promise.all([
        admin.from('posts').select('id,author_id,caption,media_path,media_kind,created_at').eq('status', 'pending').order('created_at').limit(100),
        admin.from('comments').select('id,author_id,post_id,body,created_at').eq('status', 'pending').order('created_at').limit(100),
        admin.from('reports').select().eq('status', 'open').order('created_at').limit(100),
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
        lookup('profiles', 'id,display_name,bio,styles', ids('user')),
        lookup('messages', 'id,sender_id,body', ids('message')),
      ]);
      const targetSets: Record<string, Row[]> = { post: reportedPosts, comment: reportedComments, user: reportedUsers, message: reportedMessages };
      const reviewedReports = await Promise.all(reportRows.map(async report => {
        const target = targetSets[report.target_type]?.find(row => row.id === report.target_id);
        if (!target) return { ...report, target: null };
        return { ...report, target: {
          ...(report.target_type === 'post' ? await withMedia(target) : target),
          review_author_id: report.target_type === 'user' ? target.id : target.author_id ?? target.sender_id,
        } };
      }));
      const media = await Promise.all((posts.data ?? []).map(withMedia));
      return reply({ posts: media, comments: comments.data, reports: reviewedReports });
    }
    if (!uuid(id)) return reply({ error: 'invalid_id' }, 400);
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

import { authenticated, reply, requestBody } from '../_shared/server.ts';
Deno.serve(async req => {
  try {
    const { admin, user, token } = await authenticated(req);
    const body = await requestBody(req);
    if (body.confirm_user_id !== user.id) return reply({ error: 'confirmation_required' }, 400);
    if (!user.last_sign_in_at || Date.now() - Date.parse(user.last_sign_in_at) > 10 * 60 * 1000) return reply({ error: 'sign_in_again' }, 401);
    const { error: gate } = await admin.rpc('begin_account_deletion', { p_user: user.id });
    if (gate) return reply({ error: 'deletion_not_started' }, 503);
    await admin.auth.admin.signOut(token, 'global');
    const bucket = admin.storage.from('dance-media');
    // Delete one page at a time and re-list offset zero; a failed run is safe to retry.
    for (const folder of ['posts', 'avatar']) {
      while (true) {
        const { data, error } = await bucket.list(`${user.id}/${folder}`, { limit: 100 });
        if (error) throw new Error('media_deletion_failed');
        const names = (data ?? []).filter(row => row.id).map(row => `${user.id}/${folder}/${row.name}`);
        if (!names.length) break;
        const { error: removal } = await bucket.remove(names);
        if (removal) throw new Error('media_deletion_failed');
      }
    }
    const { error } = await admin.auth.admin.deleteUser(user.id);
    if (error) throw new Error('account_deletion_failed');
    return reply({ deleted: true });
  } catch (error) {
    if (error instanceof Error && error.message === 'unauthorized') return reply({ error: 'sign_in_required' }, 401);
    return reply({ error: 'deletion_incomplete_retry' }, 503);
  }
});

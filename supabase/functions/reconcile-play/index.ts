import { authenticated, digest, reply, requestBody } from '../_shared/server.ts';
import { playBase, playFetch } from '../_shared/google-play.ts';
Deno.serve(async req => {
  try {
    const { admin, user } = await authenticated(req);
    if (user.app_metadata?.vimi_role !== 'moderator') return reply({ error: 'forbidden' }, 403);
    const body = await requestBody(req);
    const start = typeof body.start_time_ms === 'number' ? body.start_time_ms : Date.now() - 29 * 86400000;
    const query = new URLSearchParams({ startTime: String(Math.floor(start)), type: '0', maxResults: '100' });
    if (typeof body.page_token === 'string') query.set('token', body.page_token);
    const response = await playFetch(`${playBase}/purchases/voidedpurchases?${query}`);
    if (!response.ok) throw new Error('reconciliation_unavailable');
    const result = await response.json() as { voidedPurchases?: { purchaseToken: string; orderId: string }[]; tokenPagination?: { nextPageToken?: string } };
    let reversed = 0;
    for (const purchase of result.voidedPurchases ?? []) {
      const { error } = await admin.rpc('reverse_play_purchase', { p_token_hash: await digest(purchase.purchaseToken) });
      if (error) throw error;
      reversed++;
    }
    return reply({ processed: reversed, next_page_token: result.tokenPagination?.nextPageToken ?? null });
  } catch (error) {
    if (error instanceof Error && error.message === 'unauthorized') return reply({ error: 'sign_in_required' }, 401);
    return reply({ error: 'reconciliation_unavailable' }, 503);
  }
});

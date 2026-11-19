import { authenticated, digest, reply, requestBody } from '../_shared/server.ts';
import { playFetch, purchase } from '../_shared/google-play.ts';

Deno.serve(async req => {
  try {
    const { admin, user } = await authenticated(req);
    const body = await requestBody(req);
    const product = body.product_id, token = body.purchase_token;
    if (typeof product !== 'string' || typeof token !== 'string' || token.length < 10 || token.length > 4096) return reply({ error: 'invalid_purchase' }, 400);
    const { data: item, error: itemError } = await admin.from('coin_products').select('id').eq('id', product).eq('active', true).maybeSingle();
    if (itemError || !item) return reply({ error: 'unknown_product' }, 400);
    const { error: limitError } = await admin.rpc('guard_api_request', { p_user: user.id, p_action: 'play', p_limit: 30 });
    if (limitError) return reply({ error: 'try_later' }, 429);
    const { url, receipt } = await purchase(product, token);
    if (receipt.purchaseState !== 0 || (receipt.quantity ?? 1) !== 1 || !receipt.orderId || receipt.obfuscatedExternalAccountId !== await digest(user.id)) {
      return reply({ error: 'purchase_not_grantable' }, 409);
    }
    const { data: balance, error } = await admin.rpc('credit_play_purchase', {
      p_user: user.id, p_token_hash: await digest(token), p_product: product, p_order: receipt.orderId,
    });
    if (error) return reply({ error: 'credit_not_applied' }, 409);
    let consumed = receipt.consumptionState === 1;
    if (!consumed) {
      const response = await playFetch(`${url}:consume`, { method: 'POST' });
      consumed = response.ok;
      if (!consumed) consumed = (await purchase(product, token)).receipt.consumptionState === 1;
    }
    return reply({ credited: true, consumed, balance }, consumed ? 200 : 503);
  } catch (error) {
    const reason = error instanceof Error ? error.message : 'unavailable';
    if (reason === 'unauthorized') return reply({ error: 'sign_in_required' }, 401);
    if (reason === 'method' || reason === 'invalid' || error instanceof SyntaxError) return reply({ error: 'invalid_request' }, 400);
    // No token, account credential, Google response or private key is returned/logged.
    return reply({ error: 'verification_unavailable' }, 503);
  }
});

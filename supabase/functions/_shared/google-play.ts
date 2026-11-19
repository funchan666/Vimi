let cached: { value: string; until: number } | undefined;
function base64url(bytes: Uint8Array) {
  return btoa(String.fromCharCode(...bytes)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}
const encode = (value: unknown) => base64url(new TextEncoder().encode(JSON.stringify(value)));
export async function playAccessToken() {
  if (cached && cached.until > Date.now()) return cached.value;
  const raw = Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON');
  if (!raw) throw new Error('play_not_configured');
  const service = JSON.parse(raw) as { client_email: string; private_key: string };
  if (!service.client_email || !service.private_key) throw new Error('play_not_configured');
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${encode({ alg: 'RS256', typ: 'JWT' })}.${encode({
    iss: service.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600,
  })}`;
  const pem = service.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, '');
  const key = await crypto.subtle.importKey('pkcs8', Uint8Array.from(atob(pem), c => c.charCodeAt(0)), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const signature = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned)));
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST', signal: AbortSignal.timeout(15000),
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${unsigned}.${base64url(signature)}` }),
  });
  if (!response.ok) throw new Error('play_authorization_failed');
  const result = await response.json() as { access_token: string; expires_in: number };
  cached = { value: result.access_token, until: Date.now() + (result.expires_in - 90) * 1000 };
  return cached.value;
}
export const packageName = 'com.vimistudio.vimi';
export const playBase = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}`;
export async function playFetch(url: string, options: RequestInit = {}) {
  return fetch(url, { ...options, signal: AbortSignal.timeout(15000), headers: { ...options.headers, Authorization: `Bearer ${await playAccessToken()}` } });
}
export type ProductPurchase = { purchaseState: number; consumptionState: number; orderId?: string; quantity?: number; obfuscatedExternalAccountId?: string };
export async function purchase(product: string, token: string) {
  const url = `${playBase}/purchases/products/${encodeURIComponent(product)}/tokens/${encodeURIComponent(token)}`;
  const response = await playFetch(url);
  if (!response.ok) throw new Error('purchase_unverified');
  return { url, receipt: await response.json() as ProductPurchase };
}

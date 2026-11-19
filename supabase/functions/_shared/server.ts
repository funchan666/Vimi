import { createClient } from 'npm:@supabase/supabase-js@2.119.0';

export const reply = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});
export function adminClient() {
  return createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
export async function authenticated(req: Request) {
  const token = req.headers.get('Authorization')?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) throw new Error('unauthorized');
  const admin = adminClient();
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) throw new Error('unauthorized');
  return { admin, user: data.user, token };
}
export async function requestBody(req: Request) {
  if (req.method !== 'POST') throw new Error('method');
  const text = await req.text();
  if (text.length > 16000) throw new Error('invalid');
  return JSON.parse(text) as Record<string, unknown>;
}
export async function digest(value: string) {
  return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value))))
    .map(x => x.toString(16).padStart(2, '0')).join('');
}
export const uuid = (value: unknown): value is string => typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);

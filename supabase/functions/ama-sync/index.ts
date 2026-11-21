import { normalizePost } from './normalize.mjs';

// The gateway verifies JWTs. Interactive calls additionally require admin membership;
// scheduled calls use the service role. The database RPC checks the service role.
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
export async function handleRequest(request: Request): Promise<Response> {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: cors });
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const projectUrl = Deno.env.get('SUPABASE_URL');
  const authorization = request.headers.get('authorization');
  if (!serviceKey || !projectUrl || !authorization?.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401, headers: cors });
  }
  // The gateway verifies the legacy JWT; PostgREST independently validates it
  // before we trust its service_role claim. Keys can rotate independently.
  let scheduled = authorization === `Bearer ${serviceKey}`;
  if (!scheduled) {
    try {
      const token = authorization.slice(7);
      const payload = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
      const claims = JSON.parse(atob(payload));
      if (claims.role === 'service_role') {
        const verify = await fetch(`${projectUrl}/rest/v1/rpc/jivaio_ama_status`, {
          method: 'POST', headers: { apikey: serviceKey, authorization, 'Content-Type': 'application/json' },
          body: '{}', signal: AbortSignal.timeout(10000),
        });
        scheduled = verify.ok;
      }
    } catch (_) { /* Continue with user authentication. */ }
  }
  if (!scheduled) {
    try {
      const userResponse = await fetch(`${projectUrl}/auth/v1/user`, {
        headers: { apikey: serviceKey, authorization }, signal: AbortSignal.timeout(10000),
      });
      if (!userResponse.ok) return new Response('Unauthorized', { status: 401, headers: cors });
      const user = await userResponse.json();
      if (typeof user.id !== 'string' || !/^[0-9a-f-]{36}$/i.test(user.id)) return new Response('Unauthorized', { status: 401, headers: cors });
      const membership = new URL(`${projectUrl}/rest/v1/admin_users`);
      membership.searchParams.set('user_id', `eq.${user.id}`);
      membership.searchParams.set('select', 'user_id');
      const memberResponse = await fetch(membership, {
        headers: { apikey: serviceKey, authorization: `Bearer ${serviceKey}` }, signal: AbortSignal.timeout(10000),
      });
      if (!memberResponse.ok || (await memberResponse.json()).length !== 1) return new Response('Forbidden', { status: 403, headers: cors });
    } catch (_) {
      return new Response('Authorization unavailable', { status: 503, headers: cors });
    }
  }
  const serviceHeaders = { 'Content-Type': 'application/json', apikey: serviceKey, authorization: `Bearer ${serviceKey}` };
  const rpc = (name: string, body: unknown) => fetch(`${projectUrl}/rest/v1/rpc/${name}`, {
    method: 'POST', headers: serviceHeaders, body: JSON.stringify(body), signal: AbortSignal.timeout(15000),
  });
  try {
    if (scheduled) {
      const statusResponse = await rpc('jivaio_ama_status', {});
      if (!statusResponse.ok) throw new Error('Status unavailable');
      const status = await statusResponse.json();
      if (status.automatic_enabled !== true) return Response.json({ skipped: true }, { headers: cors });
    }
    const body = await request.json().catch(() => ({}));
    const limit = scheduled && body?.limit === 1 ? '1' : '100';
    const url = new URL('https://www.ama.laquila.it/wp-json/wp/v2/posts');
    url.search = new URLSearchParams({ categories: '4', per_page: limit, orderby: 'modified', order: 'desc', _fields: 'id,date_gmt,modified_gmt,link,title,content,excerpt' }).toString();
    const response = await fetch(url, { signal: AbortSignal.timeout(15000), headers: { accept: 'application/json' } });
    if (!response.ok) throw new Error(`AMA HTTP ${response.status}`);
    const posts = await response.json();
    if (!Array.isArray(posts) || posts.length > 100) throw new Error('Invalid AMA response');
    const normalized = posts.map(normalizePost);
    const result = await rpc('jivaio_ingest_ama_alerts', { p_posts: normalized });
    if (!result.ok) throw new Error(`Database HTTP ${result.status}`);
    const resultBody = await result.json();
    const recorded = await rpc('jivaio_ama_record_attempt', { p_success: true });
    if (!recorded.ok) throw new Error('Status update failed');
    return Response.json(resultBody, { headers: cors });
  } catch (error) {
    try { await rpc('jivaio_ama_record_attempt', { p_success: false, p_error: 'Sincronizzazione non riuscita' }); } catch (_) { /* preserve original failure */ }
    console.error('AMA synchronization failed', error instanceof Error ? error.message : 'unknown error');
    return Response.json({ error: 'Synchronization failed' }, { status: 502, headers: cors });
  }
}

if (import.meta.main) Deno.serve(handleRequest);

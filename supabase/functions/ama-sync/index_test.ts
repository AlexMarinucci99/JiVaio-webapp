import { handleRequest } from './index.ts';

function equal(actual: unknown, expected: unknown) {
  if (actual !== expected) throw new Error(`Expected ${expected}, received ${actual}`);
}

Deno.test('rejects unauthenticated and non-admin callers', async () => {
  Deno.env.set('SUPABASE_URL', 'https://example.invalid');
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key');
  const originalFetch = globalThis.fetch;
  try {
    equal((await handleRequest(new Request('https://example.invalid', { method: 'POST' }))).status, 401);
    globalThis.fetch = async (input) => {
      const url = String(input);
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' });
      if (url.includes('/admin_users')) return Response.json([]);
      throw new Error('Unauthorized call reached external service');
    };
    const request = new Request('https://example.invalid', { method: 'POST', headers: { authorization: 'Bearer user-token' } });
    equal((await handleRequest(request)).status, 403);
  } finally {
    globalThis.fetch = originalFetch;
    Deno.env.delete('SUPABASE_URL');
    Deno.env.delete('SUPABASE_SERVICE_ROLE_KEY');
  }
});

Deno.test('imports valid AMA data through the protected RPC', async () => {
  Deno.env.set('SUPABASE_URL', 'https://example.invalid');
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key');
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async (input, init) => {
      const url = String(input);
      if (url.endsWith('/rest/v1/rpc/jivaio_ama_status')) return Response.json({ automatic_enabled: true });
      if (url.endsWith('/rest/v1/rpc/jivaio_ama_record_attempt')) return new Response(null, { status: 204 });
      if (url.startsWith('https://www.ama.laquila.it/')) return Response.json([{
        id: 12, link: 'https://www.ama.laquila.it/avviso/', date_gmt: '2026-11-20T10:00:00', modified_gmt: '2026-11-20T11:00:00',
        title: { rendered: 'Avviso' }, content: { rendered: '<p>Dettaglio</p>' }, excerpt: { rendered: '<p>Sintesi</p>' },
      }]);
      if (url.endsWith('/rest/v1/rpc/jivaio_ingest_ama_alerts')) {
        const data = JSON.parse(String(init?.body));
        equal(data.p_posts[0].payload.id, 'ama-12');
        equal(data.p_posts[0].payload.isPublished, false);
        return Response.json({ inserted: 1, changed: 0 });
      }
      throw new Error('Unexpected request');
    };
    const result = await handleRequest(new Request('https://example.invalid', { method: 'POST', headers: { authorization: 'Bearer test-service-key' } }));
    equal(result.status, 200);
    equal((await result.json()).inserted, 1);
  } finally {
    globalThis.fetch = originalFetch;
    Deno.env.delete('SUPABASE_URL');
    Deno.env.delete('SUPABASE_SERVICE_ROLE_KEY');
  }
});

Deno.test('scheduled execution does not fetch AMA while disabled', async () => {
  Deno.env.set('SUPABASE_URL', 'https://example.invalid');
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key');
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async (input) => {
      if (String(input).endsWith('/rest/v1/rpc/jivaio_ama_status')) return Response.json({ automatic_enabled: false });
      throw new Error('Unexpected fetch while disabled');
    };
    const result = await handleRequest(new Request('https://example.invalid', { method: 'POST', headers: { authorization: 'Bearer test-service-key' } }));
    equal(result.status, 200);
    equal((await result.json()).skipped, true);
  } finally {
    globalThis.fetch = originalFetch;
    Deno.env.delete('SUPABASE_URL');
    Deno.env.delete('SUPABASE_SERVICE_ROLE_KEY');
  }
});

Deno.test('accepts a separately signed service token only after database verification', async () => {
  Deno.env.set('SUPABASE_URL', 'https://example.invalid');
  Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'internal-service-key');
  const oldFetch = globalThis.fetch;
  try {
    let checks = 0;
    globalThis.fetch = async (input) => {
      if (String(input).endsWith('/rest/v1/rpc/jivaio_ama_status')) {
        checks++;
        return Response.json({ automatic_enabled: false });
      }
      throw new Error('Unexpected request');
    };
    const token = `header.${btoa(JSON.stringify({ role: 'service_role' }))}.signature`;
    const result = await handleRequest(new Request('https://example.invalid', { method: 'POST', headers: { authorization: `Bearer ${token}` } }));
    equal(result.status, 200);
    equal(checks, 2);
    equal((await result.json()).skipped, true);
  } finally {
    globalThis.fetch = oldFetch;
    Deno.env.delete('SUPABASE_URL');
    Deno.env.delete('SUPABASE_SERVICE_ROLE_KEY');
  }
});

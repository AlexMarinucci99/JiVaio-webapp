import {test} from 'node:test';
import assert from 'node:assert/strict';
import {plainText, normalizePost} from '../../supabase/functions/ama-sync/normalize.mjs';

test('converte HTML non attendibile in testo', () => {
  assert.equal(plainText('<p>Via &amp; piazza</p><script>bad()</script><p>Citt&#224;</p>'), 'Via & piazza\nCittà');
});
test('crea una bozza AMA e verifica la fonte', () => {
  const post = {id: 123, link: 'https://www.ama.laquila.it/avviso/', date_gmt: '2026-11-20T10:00:00', modified_gmt: '2026-11-20T11:00:00', title: {rendered: 'Avviso'}, excerpt: {rendered: '<p>Riepilogo</p>'}, content: {rendered: '<p>Dettagli</p>'}};
  const result = normalizePost(post);
  assert.equal(result.payload.id, 'ama-123');
  assert.equal(result.payload.isPublished, false);
  assert.equal(result.payload.endsAt, null);
  assert.throws(() => normalizePost({...post, link: 'https://example.com/'}));
  assert.throws(() => normalizePost({...post, id: 0}));
});

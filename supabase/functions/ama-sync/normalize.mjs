// Convert untrusted WordPress content to plain text; never render remote HTML.
export function plainText(value) {
  if (typeof value !== 'string') return '';
  const entities = {amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' '};
  return value
    .replace(/<(script|style)\b[^>]*>[\s\S]*?<\/\1\s*>/gi, ' ')
    .replace(/<\s*br\s*\/?\s*>|<\s*\/\s*(?:p|div|li|h[1-6]|tr)\s*>/gi, '\n')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&(#x[\da-f]+|#\d+|[a-z]+);/gi, (original, name) => {
      if (name[0] === '#') {
        const n = name[1].toLowerCase() === 'x'
          ? parseInt(name.slice(2), 16) : parseInt(name.slice(1), 10);
        return Number.isInteger(n) && n > 0 && n <= 0x10ffff && !(n >= 0xd800 && n <= 0xdfff)
          ? String.fromCodePoint(n) : original;
      }
      return entities[name.toLowerCase()] ?? original;
    })
    .replace(/[\t\r ]+/g, ' ')
    .replace(/ *\n */g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

export function normalizePost(post) {
  if (!Number.isSafeInteger(post?.id) || post.id <= 0) throw new Error('Invalid post ID');
  const url = new URL(post.link);
  if (url.protocol !== 'https:' || url.hostname !== 'www.ama.laquila.it') throw new Error('Invalid source URL');
  const title = plainText(post.title?.rendered);
  const details = plainText(post.content?.rendered);
  const summary = plainText(post.excerpt?.rendered) || details.slice(0, 240);
  if (!title || !summary || !details || !Number.isFinite(Date.parse(post.date_gmt + 'Z')) || !Number.isFinite(Date.parse(post.modified_gmt + 'Z'))) {
    throw new Error('Incomplete post');
  }
  return {
    externalId: post.id,
    modifiedAt: new Date(post.modified_gmt + 'Z').toISOString(),
    payload: {
      id: `ama-${post.id}`,
      title,
      summary,
      details,
      severity: 'info',
      startsAt: new Date(post.date_gmt + 'Z').toISOString(),
      endsAt: null,
      sourceName: 'AMA',
      sourceUrl: url.href,
      affectedLines: [],
      isPublished: false,
    },
  };
}

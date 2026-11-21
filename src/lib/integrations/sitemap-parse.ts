export type ExtractedPage = { title: string; url: string };

const SKIP_EXT = /\.(png|jpe?g|gif|svg|webp|ico|css|js|json|xml|pdf|zip|mp4|mp3|woff2?|ttf|txt)$/i;

const ENTITIES: Record<string, string> = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
  "#39": "'",
};

function decode(s: string): string {
  return s
    .replace(/&(#\d+|#x[\da-f]+|\w+);/gi, (m, e: string) => {
      if (e[0] === "#") {
        const code =
          e[1] === "x" || e[1] === "X" ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10);
        return Number.isFinite(code) ? String.fromCodePoint(code) : m;
      }
      return ENTITIES[e.toLowerCase()] ?? m;
    })
    .replace(/\s+/g, " ")
    .trim();
}

/** Canonical form used for dedupe: no hash, no query, no trailing slash (except root). */
export function normalizeUrl(href: string, base: URL): URL | null {
  let u: URL;
  try {
    u = new URL(href, base);
  } catch {
    return null;
  }
  if (u.protocol !== "http:" && u.protocol !== "https:") return null;
  u.hash = "";
  u.search = "";
  if (u.pathname.length > 1 && u.pathname.endsWith("/")) u.pathname = u.pathname.slice(0, -1);
  return u;
}

function inScope(u: URL, base: URL): boolean {
  if (u.origin !== base.origin || SKIP_EXT.test(u.pathname)) return false;
  const root = base.pathname.replace(/\/$/, "");
  const self = normalizeUrl(base.href, base);
  if (self && u.href === self.href) return false;
  return root === "" || u.pathname === root || u.pathname.startsWith(`${root}/`);
}

export function titleFromPath(u: URL): string {
  const slug = decodeURIComponent(u.pathname.split("/").filter(Boolean).pop() ?? u.hostname);
  const words = slug
    .replace(/\.[a-z]+$/i, "")
    .replace(/[-_]+/g, " ")
    .trim();
  return words ? words[0].toUpperCase() + words.slice(1) : u.href;
}

/** Same-origin links under the base path, in document order, deduped. */
export function parseLinks(html: string, base: URL): ExtractedPage[] {
  const body = html.replace(/<(script|style|noscript)[\s\S]*?<\/\1>/gi, "");
  const out: ExtractedPage[] = [];
  const seen = new Set<string>();
  const re = /<a\b[^>]*?href\s*=\s*(["'])(.*?)\1[^>]*>([\s\S]*?)<\/a>/gi;
  for (const m of body.matchAll(re)) {
    const u = normalizeUrl(decode(m[2]), base);
    if (!u || !inScope(u, base) || seen.has(u.href)) continue;
    seen.add(u.href);
    const text = decode(m[3].replace(/<[^>]+>/g, " "));
    out.push({ title: text || titleFromPath(u), url: u.href });
  }
  return out;
}

/** `<loc>` entries from a sitemap under the base path, in file order. */
export function parseSitemap(xml: string, base: URL): ExtractedPage[] {
  const out: ExtractedPage[] = [];
  const seen = new Set<string>();
  for (const m of xml.matchAll(/<loc>\s*([\s\S]*?)\s*<\/loc>/gi)) {
    const u = normalizeUrl(decode(m[1]), base);
    if (!u || !inScope(u, base) || seen.has(u.href)) continue;
    seen.add(u.href);
    out.push({ title: titleFromPath(u), url: u.href });
  }
  return out;
}

/** HTML order and titles win; sitemap-only pages are appended. */
export function mergePages(html: ExtractedPage[], sitemap: ExtractedPage[]): ExtractedPage[] {
  const seen = new Set(html.map((p) => p.url));
  return [...html, ...sitemap.filter((p) => !seen.has(p.url))];
}

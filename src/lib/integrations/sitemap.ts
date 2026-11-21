import "server-only";
import { parseLinks, parseSitemap, mergePages, type ExtractedPage } from "./sitemap-parse";

export type { ExtractedPage } from "./sitemap-parse";

export class ExtractError extends Error {
  constructor(
    message: string,
    readonly code: "invalid_url" | "timeout" | "http" | "network" | "empty",
  ) {
    super(message);
    this.name = "ExtractError";
  }
}

const TIMEOUT_MS = 8000;
const USER_AGENT = "DaybookBot/1.0 (+personal reading planner)";

type Fetcher = typeof fetch;

async function fetchText(
  url: string,
  fetcher: Fetcher,
): Promise<{ ok: boolean; status: number; text: string }> {
  try {
    const res = await fetcher(url, {
      headers: { "user-agent": USER_AGENT, accept: "text/html,application/xml;q=0.9,*/*;q=0.8" },
      signal: AbortSignal.timeout(TIMEOUT_MS),
      redirect: "follow",
    });
    return { ok: res.ok, status: res.status, text: res.ok ? await res.text() : "" };
  } catch (e) {
    if (e instanceof Error && (e.name === "TimeoutError" || e.name === "AbortError")) {
      throw new ExtractError(`Timed out after ${TIMEOUT_MS / 1000}s`, "timeout");
    }
    throw new ExtractError(e instanceof Error ? e.message : "Network error", "network");
  }
}

/**
 * Lists the pages of a course or blog: same-origin links in document order (with their
 * link text as titles), plus any extra pages from /sitemap.xml under the same path.
 */
export async function extractPages(
  rawUrl: string,
  fetcher: Fetcher = fetch,
): Promise<ExtractedPage[]> {
  let base: URL;
  try {
    base = new URL(rawUrl);
    if (base.protocol !== "http:" && base.protocol !== "https:") throw new Error();
  } catch {
    throw new ExtractError("Enter a full http(s) link", "invalid_url");
  }

  const [page, sitemap] = await Promise.all([
    fetchText(base.href, fetcher),
    fetchText(new URL("/sitemap.xml", base).href, fetcher).catch(() => null),
  ]);
  if (!page.ok) throw new ExtractError(`Page returned HTTP ${page.status}`, "http");

  const fromHtml = parseLinks(page.text, base);
  const fromSitemap = sitemap?.ok ? parseSitemap(sitemap.text, base) : [];
  const pages = mergePages(fromHtml, fromSitemap);
  if (pages.length === 0) throw new ExtractError("No pages found on that link", "empty");
  return pages;
}

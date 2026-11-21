import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { ExtractError, extractPages } from "./sitemap";
import { parseLinks, parseSitemap } from "./sitemap-parse";

const fixture = (f: string) => readFileSync(join(process.cwd(), "tests/fixtures", f), "utf8");
const base = new URL("https://course.dev/");

function fakeFetch(routes: Record<string, string | number>): typeof fetch {
  return (async (input: RequestInfo | URL) => {
    const body = routes[String(input)] ?? 404;
    return typeof body === "number"
      ? new Response("", { status: body })
      : new Response(body, { status: 200 });
  }) as typeof fetch;
}

describe("parseLinks", () => {
  it("returns same-origin pages in document order with clean titles", () => {
    expect(parseLinks(fixture("course.html"), base)).toEqual([
      { title: "Introduction", url: "https://course.dev/intro" },
      { title: "Caching & CDNs", url: "https://course.dev/caching" },
      { title: "Queues", url: "https://course.dev/queues" },
      { title: "Sharding", url: "https://course.dev/sharding" },
    ]);
  });

  it("stays within the base path", () => {
    const html = '<a href="/docs/a">A</a><a href="/blog/b">B</a><a href="/docs">Docs</a>';
    const pages = parseLinks(html, new URL("https://x.dev/docs/"));
    expect(pages.map((p) => p.url)).toEqual(["https://x.dev/docs/a"]);
  });
});

describe("parseSitemap", () => {
  it("keeps same-origin locs and derives titles from slugs", () => {
    expect(parseSitemap(fixture("sitemap.xml"), base)).toEqual([
      { title: "Intro", url: "https://course.dev/intro" },
      { title: "Load balancing", url: "https://course.dev/load-balancing" },
    ]);
  });
});

describe("extractPages", () => {
  it("merges html order with sitemap-only pages", async () => {
    const pages = await extractPages(
      "https://course.dev/",
      fakeFetch({
        "https://course.dev/": fixture("course.html"),
        "https://course.dev/sitemap.xml": fixture("sitemap.xml"),
      }),
    );
    expect(pages.map((p) => p.url)).toEqual([
      "https://course.dev/intro",
      "https://course.dev/caching",
      "https://course.dev/queues",
      "https://course.dev/sharding",
      "https://course.dev/load-balancing",
    ]);
  });

  it("works without a sitemap", async () => {
    const pages = await extractPages(
      "https://course.dev/",
      fakeFetch({ "https://course.dev/": fixture("course.html") }),
    );
    expect(pages).toHaveLength(4);
  });

  it("raises typed errors", async () => {
    await expect(extractPages("not a url")).rejects.toMatchObject({ code: "invalid_url" });
    await expect(extractPages("https://course.dev/", fakeFetch({}))).rejects.toMatchObject({
      code: "http",
    });
    await expect(
      extractPages("https://course.dev/", fakeFetch({ "https://course.dev/": "<p>hi</p>" })),
    ).rejects.toMatchObject({ code: "empty" });
    const boom = (async () => {
      throw Object.assign(new Error("t"), { name: "TimeoutError" });
    }) as unknown as typeof fetch;
    await expect(extractPages("https://course.dev/", boom)).rejects.toBeInstanceOf(ExtractError);
    await expect(extractPages("https://course.dev/", boom)).rejects.toMatchObject({
      code: "timeout",
    });
  });
});

const live = process.env.LIVE_NETWORK === "1";
describe.skipIf(!live)("extractPages (live network, set LIVE_NETWORK=1)", () => {
  it("finds pages on saadho.arushk.tech", async () => {
    const pages = await extractPages("https://saadho.arushk.tech/");
    expect(pages.length).toBeGreaterThan(0);
  }, 20_000);

  // A client-rendered SPA with hash routes: no links in the HTML, so its lessons are
  // bundled as seed data instead (see progress.md decisions).
  it("reports designed-to-scale as empty rather than crashing", async () => {
    await expect(extractPages("https://designed-to-scale.vercel.app/")).rejects.toMatchObject({
      code: "empty",
    });
  }, 20_000);
});

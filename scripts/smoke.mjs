// Usage: node scripts/smoke.mjs [baseUrl] route1 route2 ...
// Loads each route in headless Chromium and fails on console errors or non-2xx responses.
import { chromium } from "@playwright/test";

const [base = "http://localhost:3000", ...routes] = process.argv.slice(2);
const browser = await chromium.launch();
let failed = false;
for (const theme of ["dark", "light"]) {
  for (const width of [375, 1280]) {
    const ctx = await browser.newContext({ viewport: { width, height: 800 } });
    await ctx.addCookies([{ name: "theme", value: theme, url: base }]);
    const page = await ctx.newPage();
    const errors = [];
    page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
    page.on("pageerror", (e) => errors.push(e.message));
    for (const r of routes.length ? routes : ["/"]) {
      const res = await page.goto(base + r, { waitUntil: "networkidle" });
      const status = res?.status() ?? 0;
      const ok = status < 400 && errors.length === 0;
      console.log(`${ok ? "ok  " : "FAIL"} ${theme} ${width}px ${r} ${status} ${errors.join(" | ")}`);
      if (!ok) failed = true;
      errors.length = 0;
    }
    await ctx.close();
  }
}
await browser.close();
process.exit(failed ? 1 : 0);

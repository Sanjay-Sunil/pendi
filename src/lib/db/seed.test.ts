import { describe, expect, it } from "vitest";
import { DemoDb } from "./demo-adapter";
import { listItems, listSources } from "./reading";
import { seedDemo } from "./seed";

describe("seedDemo", () => {
  it("seeds both default reading sources at 30 days", async () => {
    const db = new DemoDb();
    await seedDemo(db, new Date("2026-03-01T04:00:00Z"));
    const sources = await listSources(db);
    expect(sources.map((s) => [s.title, s.target_days, s.start_date])).toEqual([
      ["Designed to Scale", 30, "2026-03-01"],
      ["Saadho", 30, "2026-03-01"],
    ]);
    expect((await listItems(db, sources[0].id)).length).toBe(40);
  });
});

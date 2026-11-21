import { describe, expect, it } from "vitest";
import { DemoDb } from "@/lib/db/demo-adapter";
import { createSource, setItemDone } from "@/lib/db/reading";
import { getReadingOverview } from "./queries";

const pages = Array.from({ length: 10 }, (_, i) => ({
  title: `P${i}`,
  url: `https://r.dev/${i}`,
}));

describe("reading overview over days", () => {
  it("updates progress and tomorrow's quota as pages are completed", async () => {
    const db = new DemoDb();
    await createSource(
      db,
      {
        title: "R",
        url: "https://r.dev/",
        kind: "course",
        start_date: "2026-03-01",
        target_days: 5,
      },
      pages,
    );

    let [o] = await getReadingOverview(db, "2026-03-01");
    expect(o.plan.quota).toBe(2);

    // Read 3 pages on day one (one extra).
    for (const item of o.plan.items)
      await setItemDone(db, item.id, true, new Date("2026-03-01T06:00:00Z"));
    const extra = (await db.list("reading_items", { orderBy: "position" }))[2];
    await setItemDone(db, extra.id, true, new Date("2026-03-01T07:00:00Z"));

    [o] = await getReadingOverview(db, "2026-03-01");
    expect(o.done).toBe(3);
    expect(o.plan.items.map((i) => i.title)).toEqual(["P0", "P1"]); // today's list is stable

    // Day two: 7 left over 4 days → 2, starting after the extra page.
    [o] = await getReadingOverview(db, "2026-03-02");
    expect(o.plan.quota).toBe(2);
    expect(o.plan.items.map((i) => i.title)).toEqual(["P3", "P4"]);
    expect(o.plan.items.some((i) => i.carriedOver)).toBe(false);

    // Skip day two and three entirely: day four has 7 over 2 days → 4, two carried over.
    [o] = await getReadingOverview(db, "2026-03-04");
    expect(o.plan.quota).toBe(4);
    expect(o.plan.items.filter((i) => i.carriedOver)).toHaveLength(3);
  });
});

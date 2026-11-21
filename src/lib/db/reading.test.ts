import { describe, expect, it } from "vitest";
import { DemoDb } from "./demo-adapter";
import * as reading from "./reading";

const input = {
  title: "Designed to Scale",
  url: "https://designed-to-scale.vercel.app/",
  kind: "course" as const,
  start_date: "2026-03-01",
  target_days: 30,
};

describe("reading data layer", () => {
  it("creates a source with ordered items", async () => {
    const db = new DemoDb();
    const { source, items } = await reading.createSource(db, input, [
      { title: "Intro", url: "https://designed-to-scale.vercel.app/intro" },
      { title: "Caching", url: "https://designed-to-scale.vercel.app/caching" },
    ]);
    expect(items.map((i) => [i.title, i.position])).toEqual([
      ["Intro", 0],
      ["Caching", 1],
    ]);
    expect(await reading.listSources(db)).toHaveLength(1);
    expect(await reading.listItems(db, source.id)).toHaveLength(2);
  });

  it("appends items after the last position and skips duplicate urls", async () => {
    const db = new DemoDb();
    const { source } = await reading.createSource(db, input, [
      { title: "A", url: "https://x.dev/a" },
    ]);
    const added = await reading.addItems(db, source.id, [
      { title: "A again", url: "https://x.dev/a" },
      { title: "B", url: "https://x.dev/b" },
      { title: "B twice", url: "https://x.dev/b" },
    ]);
    expect(added.map((i) => [i.title, i.position])).toEqual([["B", 1]]);
  });

  it("toggles items done and back with a timestamp and note", async () => {
    const db = new DemoDb();
    const { items } = await reading.createSource(db, input, [
      { title: "A", url: "https://x.dev/a" },
    ]);
    const now = new Date("2026-03-02T05:00:00Z");
    const done = await reading.setItemDone(db, items[0].id, true, now, "Good intro");
    expect(done).toMatchObject({ status: "done", done_at: now.toISOString(), note: "Good intro" });
    const undone = await reading.setItemDone(db, items[0].id, false);
    expect(undone).toMatchObject({ status: "todo", done_at: null, note: "Good intro" });
  });

  it("archives a source so it leaves the active list", async () => {
    const db = new DemoDb();
    const { source } = await reading.createSource(db, input, []);
    await reading.archiveSource(db, source.id);
    expect(await reading.listSources(db)).toHaveLength(0);
    expect(await reading.listSources(db, "archived")).toHaveLength(1);
  });
});

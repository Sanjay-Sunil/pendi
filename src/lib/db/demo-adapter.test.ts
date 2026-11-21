import { describe, expect, it } from "vitest";
import { DemoDb, DEMO_USER_ID } from "./demo-adapter";
import { tableSchemas } from "./schema";
import { DbError } from "./types";

const fixed = () => new Date("2026-01-01T00:00:00Z");

describe("DemoDb", () => {
  it("inserts with defaults, ids, and the demo user", async () => {
    const db = new DemoDb({}, fixed);
    const [src] = await db.insert("reading_sources", [
      { title: "Docs", url: "https://a.dev/", start_date: "2026-01-01", target_days: 30 },
    ]);
    expect(src.status).toBe("active");
    expect(src.kind).toBe("course");
    expect(src.user_id).toBe(DEMO_USER_ID);
    expect(src.created_at).toBe("2026-01-01T00:00:00.000Z");
    expect(() => tableSchemas.reading_sources.parse(src)).not.toThrow();
  });

  it("lists with filters and ordering", async () => {
    const db = new DemoDb();
    const [src] = await db.insert("reading_sources", [
      { title: "S", url: "https://s.dev/", start_date: "2026-01-01", target_days: 3 },
    ]);
    await db.insert("reading_items", [
      { source_id: src.id, title: "b", url: "https://s.dev/b", position: 2 },
      { source_id: src.id, title: "a", url: "https://s.dev/a", position: 1 },
      { source_id: "other", title: "z", url: "https://z.dev/", position: 0 },
    ]);
    const items = await db.list("reading_items", {
      where: { source_id: src.id },
      orderBy: "position",
    });
    expect(items.map((i) => i.title)).toEqual(["a", "b"]);
    const desc = await db.list("reading_items", { orderBy: "position", ascending: false });
    expect(desc[0].title).toBe("b");
  });

  it("updates, gets, and removes", async () => {
    const db = new DemoDb();
    const [h] = await db.insert("habits", [{ name: "Walk" }]);
    const updated = await db.update("habits", h.id, { name: "Run" });
    expect(updated.name).toBe("Run");
    expect((await db.get("habits", h.id))?.name).toBe("Run");
    await db.remove("habits", h.id);
    expect(await db.get("habits", h.id)).toBeNull();
  });

  it("returns copies, not live references", async () => {
    const db = new DemoDb();
    const [h] = await db.insert("habits", [{ name: "Walk" }]);
    h.name = "mutated";
    expect((await db.get("habits", h.id))?.name).toBe("Walk");
  });

  it("enforces unique constraints", async () => {
    const db = new DemoDb();
    await db.insert("habit_logs", [{ habit_id: "h1", day: "2026-01-01" }]);
    await expect(db.insert("habit_logs", [{ habit_id: "h1", day: "2026-01-01" }])).rejects.toThrow(
      DbError,
    );
  });

  it("throws not_found when updating a missing row", async () => {
    const db = new DemoDb();
    await expect(db.update("habits", "nope", { name: "x" })).rejects.toMatchObject({
      code: "not_found",
    });
  });

  it("cascades deletes to child rows", async () => {
    const db = new DemoDb();
    const [habit] = await db.insert("habits", [{ name: "Read" }]);
    await db.insert("habit_logs", [{ habit_id: habit.id, day: "2026-01-01" }]);
    await db.remove("habits", habit.id);
    expect(await db.list("habit_logs")).toHaveLength(0);
  });
});

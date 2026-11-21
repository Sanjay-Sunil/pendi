import { describe, expect, it } from "vitest";
import {
  estimateMinutes,
  splitByReadingTime,
  todayQuota,
  todaysItems,
  type PlannerItem,
} from "./planner";

function items(n: number): PlannerItem[] {
  return Array.from({ length: n }, (_, i) => ({
    id: `i${i}`,
    position: i,
    status: "todo",
    done_at: null,
  }));
}

/** Marks the first `n` items done at noon IST on `day`. */
function complete(list: PlannerItem[], n: number, day: string): PlannerItem[] {
  let left = n;
  return list.map((i) => {
    if (left > 0 && i.status === "todo") {
      left--;
      return { ...i, status: "done", done_at: `${day}T06:30:00Z` };
    }
    return i;
  });
}

describe("todayQuota", () => {
  it("splits evenly across the target days", () => {
    expect(todayQuota(30, "2026-03-01", 30, "2026-03-01")).toBe(1);
    expect(todayQuota(120, "2026-03-01", 30, "2026-03-01")).toBe(4);
    expect(todayQuota(31, "2026-03-01", 30, "2026-03-01")).toBe(2); // ceil
  });

  it("redistributes missed days over the days left", () => {
    // 30 pages, 30 days, nothing read for 10 days: 30 over 20 days.
    expect(todayQuota(30, "2026-03-01", 30, "2026-03-11")).toBe(2);
  });

  it("puts everything remaining on the last day and after the deadline", () => {
    expect(todayQuota(7, "2026-03-01", 30, "2026-03-30")).toBe(7);
    expect(todayQuota(7, "2026-03-01", 30, "2026-04-15")).toBe(7);
  });

  it("returns 0 for a completed source", () => {
    expect(todayQuota(0, "2026-03-01", 30, "2026-03-05")).toBe(0);
  });

  it("treats a future start as day one", () => {
    expect(todayQuota(10, "2026-03-05", 5, "2026-03-01")).toBe(2);
  });
});

describe("todaysItems", () => {
  const source = { start_date: "2026-03-01", target_days: 10 };

  it("returns the first quota items in order", () => {
    const plan = todaysItems(items(20), source, "2026-03-01");
    expect(plan.quota).toBe(2);
    expect(plan.items.map((i) => i.id)).toEqual(["i0", "i1"]);
    expect(plan.items.every((i) => !i.carriedOver)).toBe(true);
  });

  it("keeps today's list stable as pages are ticked off", () => {
    const ticked = complete(items(20), 1, "2026-03-01");
    const plan = todaysItems(ticked, source, "2026-03-01");
    expect(plan.quota).toBe(2);
    expect(plan.items.map((i) => i.id)).toEqual(["i0", "i1"]);
    expect(plan.doneToday).toBe(1);
  });

  it("advances tomorrow and flags carried-over pages after a missed day", () => {
    const day1 = complete(items(20), 2, "2026-03-01");
    expect(todaysItems(day1, source, "2026-03-02").items.map((i) => i.id)).toEqual(["i2", "i3"]);

    // Missed 2 March: 18 left over 8 days → 3 today; pace expected 4 done, so 2 are overdue.
    const plan = todaysItems(day1, source, "2026-03-03");
    expect(plan.quota).toBe(3);
    expect(plan.items.map((i) => [i.id, i.carriedOver])).toEqual([
      ["i2", true],
      ["i3", true],
      ["i4", false],
    ]);
  });

  it("ignores skipped items", () => {
    const list = items(4).map((i) => (i.id === "i0" ? { ...i, status: "skipped" as const } : i));
    const plan = todaysItems(list, { start_date: "2026-03-01", target_days: 3 }, "2026-03-01");
    expect(plan.items.map((i) => i.id)).toEqual(["i1"]);
    expect(plan.remaining).toBe(3);
  });

  it("returns nothing for a finished source", () => {
    const plan = todaysItems(complete(items(3), 3, "2026-03-01"), source, "2026-03-02");
    expect(plan.quota).toBe(0);
    expect(plan.items).toEqual([]);
  });
});

describe("reading-time splitting", () => {
  it("splits into 20-minute parts with unique urls", () => {
    const parts = splitByReadingTime("Long post", "https://b.dev/post#intro", 45);
    expect(parts).toHaveLength(3);
    expect(parts[2]).toEqual({ title: "Long post · Part 3", url: "https://b.dev/post#part-3" });
  });

  it("keeps short pages whole", () => {
    expect(splitByReadingTime("Short", "https://b.dev/s", 12)).toEqual([
      { title: "Short", url: "https://b.dev/s" },
    ]);
  });

  it("estimates minutes from word count", () => {
    expect(estimateMinutes(2300)).toBe(10);
    expect(estimateMinutes(0)).toBe(1);
  });
});

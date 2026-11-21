import { describe, expect, it } from "vitest";
import { addDays, daysBetween, formatDue, startOfDay, toLocalDay, todayLocal } from "./dates";

const IST = "Asia/Kolkata";

describe("todayLocal", () => {
  it("rolls over at IST midnight, not UTC midnight", () => {
    // 18:29:59Z = 23:59:59 IST; 18:30Z = 00:00 IST next day
    expect(todayLocal(new Date("2026-03-09T18:29:59Z"), IST)).toBe("2026-03-09");
    expect(todayLocal(new Date("2026-03-09T18:30:00Z"), IST)).toBe("2026-03-10");
  });

  it("differs from the UTC date in the early IST morning", () => {
    const now = new Date("2026-03-09T20:00:00Z"); // 01:30 IST on the 10th
    expect(todayLocal(now, "UTC")).toBe("2026-03-09");
    expect(todayLocal(now, IST)).toBe("2026-03-10");
  });

  it("defaults to APP_TIMEZONE / IST", () => {
    expect(todayLocal(new Date("2026-03-09T18:30:00Z"))).toBe("2026-03-10");
  });
});

describe("startOfDay", () => {
  it("returns the UTC instant of local midnight", () => {
    expect(startOfDay("2026-03-10", IST).toISOString()).toBe("2026-03-09T18:30:00.000Z");
    expect(startOfDay("2026-03-10", "UTC").toISOString()).toBe("2026-03-10T00:00:00.000Z");
  });

  it("is stable across the year in DST-free zones", () => {
    for (const day of ["2026-01-15", "2026-07-15", "2026-11-01"]) {
      expect(startOfDay(day, IST).getUTCHours()).toBe(18);
      expect(startOfDay(day, IST).getUTCMinutes()).toBe(30);
      expect(startOfDay(day, "Asia/Tokyo").getUTCHours()).toBe(15);
    }
  });

  it("rejects malformed days", () => {
    expect(() => startOfDay("2026-3-1", IST)).toThrow(RangeError);
  });
});

describe("toLocalDay", () => {
  it("buckets instants by local day", () => {
    expect(toLocalDay("2026-03-09T18:30:00Z", IST)).toBe("2026-03-10");
    expect(toLocalDay("2026-03-09T18:29:00Z", IST)).toBe("2026-03-09");
  });
});

describe("daysBetween / addDays", () => {
  it("counts calendar days", () => {
    expect(daysBetween("2026-03-01", "2026-03-31")).toBe(30);
    expect(daysBetween("2026-03-10", "2026-03-08")).toBe(-2);
    expect(daysBetween("2026-02-28", "2026-03-01")).toBe(1);
    expect(daysBetween("2024-02-28", "2024-03-01")).toBe(2); // leap year
  });

  it("adds days across month and year ends", () => {
    expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
    expect(addDays("2026-03-01", -1)).toBe("2026-02-28");
  });
});

describe("formatDue", () => {
  const now = new Date("2026-03-09T20:00:00Z"); // 10 Mar 01:30 IST

  it("labels by local calendar day", () => {
    expect(formatDue("2026-03-10T17:00:00Z", now, IST)).toBe("Today");
    expect(formatDue("2026-03-10T19:00:00Z", now, IST)).toBe("Tomorrow"); // 00:30 IST 11th
    expect(formatDue("2026-03-09T12:00:00Z", now, IST)).toBe("Overdue 1d");
    expect(formatDue("2026-03-15T06:00:00Z", now, IST)).toBe("In 5d");
    expect(formatDue("2026-04-14T06:00:00Z", now, IST)).toBe("Apr 14");
  });
});

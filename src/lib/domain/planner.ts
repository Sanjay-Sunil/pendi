import { daysBetween, toLocalDay, type LocalDay } from "./dates";

export type PlannerItem = {
  id: string;
  position: number;
  status: "todo" | "done" | "skipped";
  done_at: string | null;
};

export type PlannerSource = { start_date: LocalDay; target_days: number };

/**
 * Pages to read today: remaining spread evenly over the days left.
 * Day 1 is `startDate`; on or after the last day, everything remaining is due.
 */
export function todayQuota(
  remainingItems: number,
  startDate: LocalDay,
  targetDays: number,
  today: LocalDay,
): number {
  if (remainingItems <= 0) return 0;
  const daysElapsed = Math.max(0, daysBetween(startDate, today));
  const daysLeft = targetDays - daysElapsed;
  return Math.ceil(remainingItems / Math.max(1, daysLeft));
}

export type TodayPlan<T extends PlannerItem> = {
  quota: number;
  /** Today's slice in reading order; includes items already ticked today. */
  items: Array<T & { carriedOver: boolean }>;
  doneToday: number;
  remaining: number;
  daysLeft: number;
};

/**
 * Today's reading slice. The quota is fixed at the start of the day (items finished
 * today still count toward it) so ticking pages off never shrinks or grows the list.
 * Items that an even pace would have finished before today are flagged as carried over.
 */
export function todaysItems<T extends PlannerItem>(
  all: T[],
  source: PlannerSource,
  today: LocalDay,
  tz?: string,
): TodayPlan<T> {
  const live = all.filter((i) => i.status !== "skipped").sort((a, b) => a.position - b.position);
  const doneOn = (i: T) => (i.status === "done" && i.done_at ? toLocalDay(i.done_at, tz) : null);
  const doneBefore = live.filter((i) => {
    const d = doneOn(i);
    return d !== null && d < today;
  });
  const open = live.filter((i) => !doneBefore.includes(i));
  const quota = todayQuota(open.length, source.start_date, source.target_days, today);

  const elapsed = Math.max(0, daysBetween(source.start_date, today));
  const expectedBeforeToday = Math.min(
    live.length,
    Math.ceil((live.length * elapsed) / source.target_days),
  );
  const behind = Math.max(0, expectedBeforeToday - doneBefore.length);

  const items = open.slice(0, quota).map((item, i) => ({ ...item, carriedOver: i < behind }));
  return {
    quota,
    items,
    doneToday: items.filter((i) => i.status === "done").length,
    remaining: open.filter((i) => i.status !== "done").length,
    daysLeft: Math.max(0, source.target_days - elapsed),
  };
}

const MINUTES_PER_PART = 20;
const WORDS_PER_MINUTE = 230;

export function estimateMinutes(wordCount: number): number {
  return Math.max(1, Math.ceil(wordCount / WORDS_PER_MINUTE));
}

/** Splits a long single page into ~20-minute parts with distinct URLs. */
export function splitByReadingTime(
  title: string,
  url: string,
  minutes: number,
): Array<{ title: string; url: string }> {
  const parts = Math.max(1, Math.ceil(minutes / MINUTES_PER_PART));
  if (parts === 1) return [{ title, url }];
  const base = url.split("#")[0];
  return Array.from({ length: parts }, (_, i) => ({
    title: `${title} · Part ${i + 1}`,
    url: `${base}#part-${i + 1}`,
  }));
}

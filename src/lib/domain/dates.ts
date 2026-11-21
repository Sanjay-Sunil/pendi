import { formatInTimeZone, fromZonedTime } from "date-fns-tz";

/** A calendar day in the user's timezone, as `YYYY-MM-DD`. */
export type LocalDay = string;

export const DEFAULT_TIMEZONE = "Asia/Kolkata";

export function appTimezone(): string {
  return process.env.APP_TIMEZONE || DEFAULT_TIMEZONE;
}

const DAY_RE = /^\d{4}-\d{2}-\d{2}$/;

function assertDay(day: LocalDay): void {
  if (!DAY_RE.test(day)) throw new RangeError(`Invalid day: ${day}`);
}

/** Today's date in `tz`. */
export function todayLocal(now: Date = new Date(), tz: string = appTimezone()): LocalDay {
  return formatInTimeZone(now, tz, "yyyy-MM-dd");
}

/** The UTC instant at which `day` begins in `tz`. */
export function startOfDay(day: LocalDay, tz: string = appTimezone()): Date {
  assertDay(day);
  return fromZonedTime(`${day}T00:00:00`, tz);
}

/** The local day an instant falls on in `tz`. */
export function toLocalDay(instant: Date | string, tz: string = appTimezone()): LocalDay {
  return formatInTimeZone(new Date(instant), tz, "yyyy-MM-dd");
}

function dayNumber(day: LocalDay): number {
  assertDay(day);
  const [y, m, d] = day.split("-").map(Number);
  return Date.UTC(y, m - 1, d) / 86_400_000;
}

/** Whole calendar days from `from` to `to` (negative if `to` is earlier). */
export function daysBetween(from: LocalDay, to: LocalDay): number {
  return dayNumber(to) - dayNumber(from);
}

export function addDays(day: LocalDay, n: number): LocalDay {
  const t = (dayNumber(day) + n) * 86_400_000;
  return new Date(t).toISOString().slice(0, 10);
}

/**
 * Human label for a due instant relative to now, by calendar day in `tz`:
 * "Overdue 2d", "Today", "Tomorrow", "In 5d", or "Mar 14" beyond two weeks.
 */
export function formatDue(
  dueAt: Date | string,
  now: Date = new Date(),
  tz: string = appTimezone(),
): string {
  const diff = daysBetween(todayLocal(now, tz), toLocalDay(dueAt, tz));
  if (diff < 0) return `Overdue ${-diff}d`;
  if (diff === 0) return "Today";
  if (diff === 1) return "Tomorrow";
  if (diff <= 14) return `In ${diff}d`;
  return formatInTimeZone(new Date(dueAt), tz, "MMM d");
}

/**
 * Every "which day is this" question in the API — `?date=2026-09-06` query
 * params, day-boundary filtering — goes through here so there's one place
 * that decides a "day" means a UTC calendar day.
 */

const DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

export function isValidDateOnly(value: string): boolean {
  if (!DATE_ONLY_PATTERN.test(value)) return false;
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && toDateOnly(date) === value;
}

/** `[start of day, start of next day)` for a "yyyy-MM-dd" string. Validate
 * with `isValidDateOnly` first — this doesn't check the format. */
export function dateOnlyRange(value: string): { start: Date; end: Date } {
  const start = new Date(`${value}T00:00:00Z`);
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, end };
}

export function toDateOnly(date: Date): string {
  return date.toISOString().slice(0, 10);
}

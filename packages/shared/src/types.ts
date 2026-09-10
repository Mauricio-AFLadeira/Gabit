/**
 * Domain types shared between the mobile app and the API. Plain data +
 * pure functions rather than classes with getters — this is the direct
 * port of the Swift version's `MauItKit` (structs + computed properties),
 * kept in exactly one place so the client and server can't drift apart on
 * what "over budget" or "daily target" mean.
 */

// ---------------------------------------------------------------- Goal -----

export type GoalDirection = "loseFat" | "recomposition" | "buildMass";

export const GOAL_DIRECTIONS: readonly GoalDirection[] = [
  "loseFat",
  "recomposition",
  "buildMass",
];

export interface GoalDirectionInfo {
  readonly title: string;
  readonly subtitle: string;
  /** Whether this direction adds to or subtracts from maintenance calories. */
  readonly isSurplus: boolean;
}

export const goalDirectionInfo: Readonly<Record<GoalDirection, GoalDirectionInfo>> = {
  loseFat: { title: "Lose fat", subtitle: "Eat below maintenance", isSurplus: false },
  recomposition: {
    title: "Recomposition",
    subtitle: "Slight deficit, protein held high",
    isSurplus: false,
  },
  buildMass: { title: "Build mass", subtitle: "Controlled surplus", isSurplus: true },
};

export function isGoalDirection(value: string): value is GoalDirection {
  return (GOAL_DIRECTIONS as readonly string[]).includes(value);
}

// ------------------------------------------------------------- MealType -----

export type MealType = "breakfast" | "lunch" | "dinner" | "snack";

export const MEAL_TYPES: readonly MealType[] = ["breakfast", "lunch", "dinner", "snack"];

export interface MealTypeInfo {
  readonly label: string;
  /** Single-character glyph on the round entry-row avatar — the design's
   * stated stand-in for a real icon set. */
  readonly glyph: string;
}

export const mealTypeInfo: Readonly<Record<MealType, MealTypeInfo>> = {
  breakfast: { label: "Breakfast", glyph: "B" },
  lunch: { label: "Lunch", glyph: "L" },
  dinner: { label: "Dinner", glyph: "D" },
  snack: { label: "Snack", glyph: "S" },
};

export function isMealType(value: string): value is MealType {
  return (MEAL_TYPES as readonly string[]).includes(value);
}

// ----------------------------------------------------------- Food entry -----

export interface MacroBreakdown {
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
}

/** A logged meal, or a manually-estimated burn that credits the day's
 * budget instead of spending it. */
export type FoodEntryKind = { type: "meal"; mealType: MealType } | { type: "exercise" };

export interface FoodEntry {
  id: string;
  kind: FoodEntryKind;
  title: string;
  /** "HH:mm" */
  time: string;
  calories: number;
  macros?: MacroBreakdown;
}

/** A tappable "recent" chip on the quick-add screen — logs as-is in one tap. */
export interface QuickAddItem {
  id: string;
  title: string;
  calories: number;
}

// ---------------------------------------------------------------- DayLog -----

/** One day's worth of intake, credited burn and macro progress — the model
 * behind the Today screen, in both its on-track and over-budget states. */
export interface DayLog {
  id: string;
  /** ISO "yyyy-MM-dd", UTC calendar day. */
  date: string;
  targetCalories: number;
  eatenCalories: number;
  burnCalories: number;
  proteinGrams: number;
  proteinTarget: number;
  carbsGrams: number;
  carbsTarget: number;
  fatGrams: number;
  fatTarget: number;
  entries: FoodEntry[];
  /** A short, non-scolding read on the day — present only in the
   * over-budget state, where the screen owes the user context rather than
   * a warning. */
  insightNote?: string;
}

/** Positive while under budget, negative once burn-credited intake exceeds
 * the target — the sign the whole Today screen keys off of. */
export function remainingCalories(day: DayLog): number {
  return day.targetCalories - day.eatenCalories + day.burnCalories;
}

export function isOverBudget(day: DayLog): boolean {
  return remainingCalories(day) < 0;
}

/** Fraction of the target ring the "eaten, net of burn" arc should fill. */
export function consumedFraction(day: DayLog): number {
  if (day.targetCalories <= 0) return 0;
  return Math.min(1, Math.max(0, (day.eatenCalories - day.burnCalories) / day.targetCalories));
}

/** Fraction of the target the thin burn arc credits back. */
export function burnFraction(day: DayLog): number {
  if (day.targetCalories <= 0) return 0;
  return Math.min(1, Math.max(0, day.burnCalories / day.targetCalories));
}

const WEEKDAY_FORMATTER = new Intl.DateTimeFormat("en-US", { weekday: "short", timeZone: "UTC" });
const DAY_FORMATTER = new Intl.DateTimeFormat("en-US", { day: "2-digit", timeZone: "UTC" });
const MONTH_FORMATTER = new Intl.DateTimeFormat("en-US", { month: "short", timeZone: "UTC" });

/** "Sun 06 Sep" — matches the design's mono date label exactly. */
export function weekdayLabel(isoDate: string): string {
  const date = new Date(`${isoDate}T00:00:00Z`);
  return `${WEEKDAY_FORMATTER.format(date)} ${DAY_FORMATTER.format(date)} ${MONTH_FORMATTER.format(date)}`;
}

// ----------------------------------------------------------- Progress -----

/** One point on the weight trend line. */
export interface WeightReading {
  id: string;
  /** ISO "yyyy-MM-dd". */
  date: string;
  kg: number;
}

/** A three-part sentence with one emphasized clause in the middle — the
 * shape the projection callout needs without smuggling markup into a
 * plain string. */
export interface EmphasizedSentence {
  prefix: string;
  emphasis: string;
  suffix: string;
}

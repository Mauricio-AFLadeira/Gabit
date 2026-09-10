import { GoalDirection, goalDirectionInfo } from "./types";

/**
 * The one piece of arithmetic the onboarding screen relies on: a daily
 * calorie target is derived from maintenance, direction and rate — never
 * typed by the user directly.
 */

/** Rough energy density of a kilogram of body fat, used to convert a
 * weekly rate of change into a daily calorie delta. */
export const KCAL_PER_KG_FAT = 7700;

export function dailyTarget(
  maintenance: number,
  direction: GoalDirection,
  ratePerWeek: number,
): number {
  const dailyDelta = (ratePerWeek * KCAL_PER_KG_FAT) / 7;
  const signedDelta = goalDirectionInfo[direction].isSurplus ? dailyDelta : -dailyDelta;
  return Math.round(maintenance + signedDelta);
}

export interface MacroTargets {
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
}

/** A standard 30/40/30 protein/carbs/fat split of a daily calorie target,
 * converted to grams via 4/4/9 kcal-per-gram. A reasonable default in the
 * absence of a per-user macro preference. */
export function defaultMacroTargets(dailyCalories: number): MacroTargets {
  return {
    proteinGrams: Math.round((dailyCalories * 0.3) / 4),
    carbsGrams: Math.round((dailyCalories * 0.4) / 4),
    fatGrams: Math.round((dailyCalories * 0.3) / 9),
  };
}

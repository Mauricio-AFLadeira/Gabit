import { Router } from "express";
import {
  DayLog,
  FoodEntry,
  FoodEntryKind,
  burnFraction,
  consumedFraction,
  dailyTarget,
  defaultMacroTargets,
  isGoalDirection,
  isMealType,
  isOverBudget,
  remainingCalories,
  weekdayLabel,
} from "@mauit/shared";
import { prisma } from "../db";
import { asyncHandler } from "../lib/asyncHandler";
import { dateOnlyRange, isValidDateOnly } from "../lib/dateOnly";
import { HttpError } from "../middleware/errorHandler";

export const daysRouter = Router();

function toFoodEntryKind(kind: string): FoodEntryKind {
  if (kind === "exercise") return { type: "exercise" };
  return { type: "meal", mealType: isMealType(kind) ? kind : "snack" };
}

function formatTime(date: Date): string {
  return date.toISOString().slice(11, 16);
}

/** Backs screens 02/05 (Today, on-track and over-budget) — one endpoint,
 * because they're one screen in two states, just like on the client. */
daysRouter.get(
  "/:date",
  asyncHandler(async (req, res) => {
    const { date } = req.params;
    if (!date || !isValidDateOnly(date)) {
      throw new HttpError(400, "`date` must be formatted yyyy-MM-dd.");
    }

    const goal = await prisma.goal.findUnique({ where: { userId: req.userId! } });
    if (!goal) throw new HttpError(404, "Set a goal first.");

    const direction = isGoalDirection(goal.direction) ? goal.direction : "recomposition";
    const targetCalories = dailyTarget(goal.maintenanceCalories, direction, goal.ratePerWeek);
    const macroTargets = defaultMacroTargets(targetCalories);

    const { start, end } = dateOnlyRange(date);
    const dbEntries = await prisma.entry.findMany({
      where: { userId: req.userId!, loggedAt: { gte: start, lt: end } },
      orderBy: { loggedAt: "asc" },
    });

    const eatenCalories = dbEntries
      .filter((e) => e.kind !== "exercise")
      .reduce((sum, e) => sum + e.calories, 0);
    const burnCalories = dbEntries
      .filter((e) => e.kind === "exercise")
      .reduce((sum, e) => sum + e.calories, 0);
    const proteinGrams = dbEntries.reduce((sum, e) => sum + (e.proteinGrams ?? 0), 0);
    const carbsGrams = dbEntries.reduce((sum, e) => sum + (e.carbsGrams ?? 0), 0);
    const fatGrams = dbEntries.reduce((sum, e) => sum + (e.fatGrams ?? 0), 0);

    const entries: FoodEntry[] = dbEntries.map((entry) => ({
      id: entry.id,
      kind: toFoodEntryKind(entry.kind),
      title: entry.title,
      time: formatTime(entry.loggedAt),
      calories: entry.calories,
      macros:
        entry.proteinGrams != null && entry.carbsGrams != null && entry.fatGrams != null
          ? {
              proteinGrams: entry.proteinGrams,
              carbsGrams: entry.carbsGrams,
              fatGrams: entry.fatGrams,
            }
          : undefined,
    }));

    // The "one day over doesn't move the trend" narrative on the
    // over-budget screen needs a real 7-day-average computation — left as
    // a TODO rather than faked here (insightNote stays undefined).
    const dayLog: DayLog = {
      id: `${req.userId}-${date}`,
      date,
      targetCalories,
      eatenCalories,
      burnCalories,
      proteinGrams,
      proteinTarget: macroTargets.proteinGrams,
      carbsGrams,
      carbsTarget: macroTargets.carbsGrams,
      fatGrams,
      fatTarget: macroTargets.fatGrams,
      entries,
    };

    res.json({
      ...dayLog,
      weekdayLabel: weekdayLabel(date),
      remainingCalories: remainingCalories(dayLog),
      isOverBudget: isOverBudget(dayLog),
      consumedFraction: consumedFraction(dayLog),
      burnFraction: burnFraction(dayLog),
    });
  }),
);

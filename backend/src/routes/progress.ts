import { Router } from "express";
import { dailyTarget, formatSignedDecimal, isGoalDirection } from "@mauit/shared";
import { prisma } from "../db";
import { asyncHandler } from "../lib/asyncHandler";
import { toDateOnly } from "../lib/dateOnly";

export const progressRouter = Router();

interface MinimalEntry {
  kind: string;
  calories: number;
  loggedAt: Date;
}

/** `?weeks=12` (default) bounds both the weight trend and the adherence
 * stats to the same window.
 *
 * Deliberately doesn't fabricate a projection sentence — the design's
 * "reach 75 kg around 14 November" needs a target weight, which nothing
 * collects yet. Every field here is either a real aggregate or `null`,
 * never invented text. */
progressRouter.get(
  "/summary",
  asyncHandler(async (req, res) => {
    const weeksParam = typeof req.query.weeks === "string" ? Number(req.query.weeks) : NaN;
    const weeks = Number.isFinite(weeksParam) && weeksParam > 0 ? weeksParam : 12;
    const since = new Date(Date.now() - weeks * 7 * 24 * 60 * 60 * 1000);

    const checkIns = await prisma.weightCheckIn.findMany({
      where: { userId: req.userId!, recordedAt: { gte: since } },
      orderBy: { recordedAt: "asc" },
    });
    const readings = checkIns.map((c) => ({ date: toDateOnly(c.recordedAt), kg: c.kg }));

    let currentWeightKg: number | null = null;
    let deltaLabel: string | null = null;
    if (checkIns.length > 0) {
      const first = checkIns[0]!;
      const last = checkIns[checkIns.length - 1]!;
      currentWeightKg = last.kg;
      if (first.id !== last.id) {
        const deltaKg = first.kg - last.kg;
        const spanWeeks = Math.max(
          1,
          Math.round(
            (last.recordedAt.getTime() - first.recordedAt.getTime()) / (7 * 24 * 60 * 60 * 1000),
          ),
        );
        deltaLabel = `${formatSignedDecimal(-deltaKg)} kg / ${spanWeeks} w`;
      }
    }

    const entries: MinimalEntry[] = await prisma.entry.findMany({
      where: { userId: req.userId!, loggedAt: { gte: since } },
      select: { kind: true, calories: true, loggedAt: true },
    });
    const entriesByDay = new Map<string, MinimalEntry[]>();
    for (const entry of entries) {
      const key = toDateOnly(entry.loggedAt);
      const bucket = entriesByDay.get(key);
      if (bucket) bucket.push(entry);
      else entriesByDay.set(key, [entry]);
    }

    let percentWithinTarget: number | null = null;
    let averageDailyBalance: number | null = null;
    const goal = await prisma.goal.findUnique({ where: { userId: req.userId! } });
    if (goal) {
      const direction = isGoalDirection(goal.direction) ? goal.direction : "recomposition";
      const target = dailyTarget(goal.maintenanceCalories, direction, goal.ratePerWeek);

      const dailyBalances = Array.from(entriesByDay.values()).map((dayEntries) => {
        const eaten = dayEntries
          .filter((e) => e.kind !== "exercise")
          .reduce((sum, e) => sum + e.calories, 0);
        const burn = dayEntries
          .filter((e) => e.kind === "exercise")
          .reduce((sum, e) => sum + e.calories, 0);
        return eaten - burn - target;
      });

      if (dailyBalances.length > 0) {
        const withinTarget = dailyBalances.filter((balance) => balance <= 0).length;
        percentWithinTarget = Math.round((withinTarget / dailyBalances.length) * 100);
        averageDailyBalance = Math.round(
          dailyBalances.reduce((sum, balance) => sum + balance, 0) / dailyBalances.length,
        );
      }
    }

    res.json({
      readings,
      currentWeightKg,
      deltaLabel,
      daysLogged: entriesByDay.size,
      percentWithinTarget,
      averageDailyBalance,
    });
  }),
);

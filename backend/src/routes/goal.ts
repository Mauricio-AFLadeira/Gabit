import { Router } from "express";
import { z } from "zod";
import { dailyTarget, GoalDirection, isGoalDirection } from "@mauit/shared";
import { prisma } from "../db";
import { asyncHandler } from "../lib/asyncHandler";
import { HttpError } from "../middleware/errorHandler";

export const goalRouter = Router();

interface GoalRow {
  direction: string;
  ratePerWeek: number;
  maintenanceCalories: number;
}

function goalResponse(goal: GoalRow) {
  const direction: GoalDirection = isGoalDirection(goal.direction) ? goal.direction : "recomposition";
  return {
    direction: goal.direction,
    ratePerWeek: goal.ratePerWeek,
    maintenanceCalories: goal.maintenanceCalories,
    dailyTargetCalories: dailyTarget(goal.maintenanceCalories, direction, goal.ratePerWeek),
  };
}

goalRouter.get(
  "/",
  asyncHandler(async (req, res) => {
    const goal = await prisma.goal.findUnique({ where: { userId: req.userId! } });
    if (!goal) throw new HttpError(404, "No goal set yet.");
    res.json(goalResponse(goal));
  }),
);

const goalSchema = z.object({
  direction: z.enum(["loseFat", "recomposition", "buildMass"]),
  ratePerWeek: z.number().positive(),
  maintenanceCalories: z.number().int().positive(),
});

goalRouter.put(
  "/",
  asyncHandler(async (req, res) => {
    const input = goalSchema.parse(req.body);
    const goal = await prisma.goal.upsert({
      where: { userId: req.userId! },
      update: input,
      create: { ...input, userId: req.userId! },
    });
    res.json(goalResponse(goal));
  }),
);

import { Router } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { asyncHandler } from "../lib/asyncHandler";

export const weightCheckInsRouter = Router();

function serializeCheckIn(checkIn: { id: string; kg: number; recordedAt: Date }) {
  return { id: checkIn.id, kg: checkIn.kg, recordedAt: checkIn.recordedAt.toISOString() };
}

/** `?weeks=12` limits to the last N weeks; omitted returns everything. */
weightCheckInsRouter.get(
  "/",
  asyncHandler(async (req, res) => {
    const weeksParam = typeof req.query.weeks === "string" ? Number(req.query.weeks) : NaN;
    let recordedAtFilter: { gte: Date } | undefined;
    if (Number.isFinite(weeksParam) && weeksParam > 0) {
      recordedAtFilter = { gte: new Date(Date.now() - weeksParam * 7 * 24 * 60 * 60 * 1000) };
    }

    const checkIns = await prisma.weightCheckIn.findMany({
      where: {
        userId: req.userId!,
        ...(recordedAtFilter ? { recordedAt: recordedAtFilter } : {}),
      },
      orderBy: { recordedAt: "asc" },
    });
    res.json(checkIns.map(serializeCheckIn));
  }),
);

const createCheckInSchema = z.object({
  kg: z.number().gt(0).lt(500),
  /** Defaults to "now" when omitted. */
  recordedAt: z.string().datetime().optional(),
});

weightCheckInsRouter.post(
  "/",
  asyncHandler(async (req, res) => {
    const input = createCheckInSchema.parse(req.body);
    const checkIn = await prisma.weightCheckIn.create({
      data: {
        userId: req.userId!,
        kg: input.kg,
        recordedAt: input.recordedAt ? new Date(input.recordedAt) : new Date(),
      },
    });
    res.status(201).json(serializeCheckIn(checkIn));
  }),
);

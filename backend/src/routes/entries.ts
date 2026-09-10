import { Router } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { asyncHandler } from "../lib/asyncHandler";
import { dateOnlyRange, isValidDateOnly } from "../lib/dateOnly";
import { HttpError } from "../middleware/errorHandler";

export const entriesRouter = Router();

interface EntryRow {
  id: string;
  kind: string;
  title: string;
  calories: number;
  proteinGrams: number | null;
  carbsGrams: number | null;
  fatGrams: number | null;
  loggedAt: Date;
}

function serializeEntry(entry: EntryRow) {
  return {
    id: entry.id,
    kind: entry.kind,
    title: entry.title,
    calories: entry.calories,
    proteinGrams: entry.proteinGrams,
    carbsGrams: entry.carbsGrams,
    fatGrams: entry.fatGrams,
    loggedAt: entry.loggedAt.toISOString(),
  };
}

entriesRouter.get(
  "/",
  asyncHandler(async (req, res) => {
    const dateParam = typeof req.query.date === "string" ? req.query.date : undefined;
    let loggedAtFilter: { gte: Date; lt: Date } | undefined;
    if (dateParam) {
      if (!isValidDateOnly(dateParam)) {
        throw new HttpError(400, "`date` must be formatted yyyy-MM-dd.");
      }
      const { start, end } = dateOnlyRange(dateParam);
      loggedAtFilter = { gte: start, lt: end };
    }

    const entries = await prisma.entry.findMany({
      where: { userId: req.userId!, ...(loggedAtFilter ? { loggedAt: loggedAtFilter } : {}) },
      orderBy: { loggedAt: "desc" },
    });
    res.json(entries.map(serializeEntry));
  }),
);

const createEntrySchema = z.object({
  kind: z.enum(["breakfast", "lunch", "dinner", "snack", "exercise"]),
  title: z.string().min(1),
  calories: z.number().int().min(0),
  proteinGrams: z.number().int().min(0).optional(),
  carbsGrams: z.number().int().min(0).optional(),
  fatGrams: z.number().int().min(0).optional(),
  /** Defaults to "now" when omitted. */
  loggedAt: z.string().datetime().optional(),
});

entriesRouter.post(
  "/",
  asyncHandler(async (req, res) => {
    const input = createEntrySchema.parse(req.body);
    const isExercise = input.kind === "exercise";

    const entry = await prisma.entry.create({
      data: {
        userId: req.userId!,
        kind: input.kind,
        title: input.title,
        calories: input.calories,
        proteinGrams: isExercise ? null : (input.proteinGrams ?? null),
        carbsGrams: isExercise ? null : (input.carbsGrams ?? null),
        fatGrams: isExercise ? null : (input.fatGrams ?? null),
        loggedAt: input.loggedAt ? new Date(input.loggedAt) : new Date(),
      },
    });
    res.status(201).json(serializeEntry(entry));
  }),
);

/** Backs the quick-add screen's "recent — tap to log as is" chips. */
entriesRouter.get(
  "/recent",
  asyncHandler(async (req, res) => {
    const requested = typeof req.query.limit === "string" ? Number(req.query.limit) : NaN;
    const limit = Math.min(Number.isFinite(requested) && requested > 0 ? requested : 8, 25);

    const entries = await prisma.entry.findMany({
      where: { userId: req.userId!, kind: { not: "exercise" } },
      orderBy: { loggedAt: "desc" },
      take: limit,
    });
    res.json(entries.map(serializeEntry));
  }),
);

entriesRouter.delete(
  "/:entryId",
  asyncHandler(async (req, res) => {
    const entry = await prisma.entry.findFirst({
      where: { id: req.params.entryId, userId: req.userId! },
    });
    if (!entry) throw new HttpError(404, "Entry not found.");
    await prisma.entry.delete({ where: { id: entry.id } });
    res.status(204).send();
  }),
);

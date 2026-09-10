import { Router } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { asyncHandler } from "../lib/asyncHandler";
import { signAuthToken } from "../lib/jwt";
import { HttpError } from "../middleware/errorHandler";
import { hashPassword, verifyPassword } from "../lib/password";

export const authRouter = Router();

const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

authRouter.post(
  "/signup",
  asyncHandler(async (req, res) => {
    const input = signupSchema.parse(req.body);
    const email = input.email.trim().toLowerCase();

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new HttpError(409, "An account with that email already exists.");
    }

    const passwordHash = await hashPassword(input.password);
    const user = await prisma.user.create({ data: { email, passwordHash } });

    res.status(201).json({
      token: signAuthToken(user.id),
      user: { id: user.id, email: user.email },
    });
  }),
);

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

authRouter.post(
  "/login",
  asyncHandler(async (req, res) => {
    const input = loginSchema.parse(req.body);
    const email = input.email.trim().toLowerCase();

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !(await verifyPassword(input.password, user.passwordHash))) {
      throw new HttpError(401, "Invalid email or password.");
    }

    res.json({
      token: signAuthToken(user.id),
      user: { id: user.id, email: user.email },
    });
  }),
);

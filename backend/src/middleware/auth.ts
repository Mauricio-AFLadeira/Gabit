import { RequestHandler } from "express";
import { verifyAuthToken } from "../lib/jwt";

export const requireAuth: RequestHandler = (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing bearer token." });
    return;
  }

  const token = header.slice("Bearer ".length);
  try {
    req.userId = verifyAuthToken(token).sub;
    next();
  } catch {
    res.status(401).json({ error: "Invalid or expired token." });
  }
};

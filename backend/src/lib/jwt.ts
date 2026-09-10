import jwt from "jsonwebtoken";
import { env } from "../env";

const EXPIRES_IN = "30d";

export interface AuthTokenPayload {
  sub: string;
}

export function signAuthToken(userId: string): string {
  const payload: AuthTokenPayload = { sub: userId };
  return jwt.sign(payload, env.jwtSecret, { expiresIn: EXPIRES_IN });
}

/** Throws if the token is missing, malformed, expired or has a bad
 * signature — callers (the `requireAuth` middleware) turn that into a 401. */
export function verifyAuthToken(token: string): AuthTokenPayload {
  const decoded = jwt.verify(token, env.jwtSecret);
  if (typeof decoded === "string" || typeof decoded.sub !== "string") {
    throw new Error("Malformed token payload.");
  }
  return { sub: decoded.sub };
}

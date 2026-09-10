import cors from "cors";
import express, { Express } from "express";
import { requireAuth } from "./middleware/auth";
import { errorHandler } from "./middleware/errorHandler";
import { authRouter } from "./routes/auth";
import { daysRouter } from "./routes/days";
import { entriesRouter } from "./routes/entries";
import { goalRouter } from "./routes/goal";
import { progressRouter } from "./routes/progress";
import { weightCheckInsRouter } from "./routes/weightCheckIns";

export function createApp(): Express {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get("/", (_req, res) => res.send("MauIt API is running."));
  app.get("/health", (_req, res) => res.sendStatus(200));

  const api = express.Router();
  api.use("/auth", authRouter);

  // Everything past this point requires a bearer token.
  api.use(requireAuth);
  api.use("/goal", goalRouter);
  api.use("/days", daysRouter);
  api.use("/entries", entriesRouter);
  api.use("/weight-check-ins", weightCheckInsRouter);
  api.use("/progress", progressRouter);

  app.use("/api", api);

  app.use(errorHandler);

  return app;
}

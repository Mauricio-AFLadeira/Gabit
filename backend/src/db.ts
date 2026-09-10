import { PrismaClient } from "@prisma/client";

// One client for the process — Prisma pools connections internally.
// Creating a fresh client per request (or per hot-reload module in dev)
// exhausts Postgres' connection limit fast.
export const prisma = new PrismaClient();

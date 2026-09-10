import { NextFunction, Request, RequestHandler, Response } from "express";

/** Express 4 doesn't catch rejected promises from async route handlers on
 * its own — wrap every async handler in this so a thrown/rejected error
 * reaches `errorHandler` instead of hanging the request. */
export function asyncHandler(
  handler: (req: Request, res: Response, next: NextFunction) => Promise<void>,
): RequestHandler {
  return (req, res, next) => {
    handler(req, res, next).catch(next);
  };
}

// Express's own `Request` type actually lives in express-serve-static-core;
// augmenting it there (not "express") is what makes this visible wherever
// `Request` is imported from "express".
import "express-serve-static-core";

declare module "express-serve-static-core" {
  interface Request {
    /** Set by `requireAuth` after verifying the bearer token. Every route
     * behind `requireAuth` can assume this is present. */
    userId?: string;
  }
}

import { createApp } from "./app";
import { env } from "./env";

const app = createApp();

app.listen(env.port, () => {
  console.log(`MauIt API listening on port ${env.port}`);
});

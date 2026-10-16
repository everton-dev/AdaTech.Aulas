import pg from "pg";
import { createApp } from "./app.js";
import { ProductRepository } from "./repository.js";

const pool = new pg.Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT ?? 5432),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  max: 10,
  idleTimeoutMillis: 30000
});

const port = Number(process.env.PORT ?? 3000);
const app = createApp(new ProductRepository(pool));
const server = app.listen(port, "0.0.0.0", () => {
  console.log(`Products API listening on port ${port}`);
});

const shutdown = () => {
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
};

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
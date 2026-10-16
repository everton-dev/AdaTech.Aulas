const express = require("express");
const helmet = require("helmet");

const app = express();
app.use(helmet());
app.get("/health", (_req, res) => res.json({ status: "ok" }));

if (require.main === module) {
  app.listen(3000, () => console.log("API em http://localhost:3000"));
}
module.exports = app;

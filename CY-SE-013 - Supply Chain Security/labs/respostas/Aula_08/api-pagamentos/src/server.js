const express = require("express");
const helmet = require("helmet");

const app = express();
app.use(helmet());
app.use(express.json({ limit: "10kb" }));

app.get("/health", (_req, res) => res.json({ status: "ok" }));

app.post("/pagamentos", (req, res) => {
  const { valor, moeda } = req.body ?? {};
  if (typeof valor !== "number" || valor <= 0 || !["BRL", "USD"].includes(moeda)) {
    return res.status(400).json({ erro: "payload invalido" });
  }
  res.status(201).json({ id: Date.now().toString(36), valor, moeda, status: "autorizado" });
});

if (require.main === module) {
  app.listen(3000, () => console.log("api-pagamentos em :3000"));
}
module.exports = app;

import express from "express";

const parseProductId = (value) => {
  const id = Number(value);
  return Number.isInteger(id) && id > 0 ? id : null;
};

const parseName = (value) => {
  if (typeof value !== "string") return null;
  const name = value.trim();
  return name.length > 0 && name.length <= 50 ? name : null;
};

export function createApp(repository) {
  const app = express();
  app.disable("x-powered-by");
  app.use(express.json({ limit: "16kb" }));

  app.get("/health", (_request, response) => response.json({ status: "ok" }));

  app.get("/api/products", async (_request, response, next) => {
    try {
      response.json(await repository.findAll());
    } catch (error) {
      next(error);
    }
  });

  app.get("/api/products/:id", async (request, response, next) => {
    const id = parseProductId(request.params.id);
    if (!id) return response.status(400).json({ error: "ID invalido." });

    try {
      const product = await repository.findById(id);
      return product
        ? response.json(product)
        : response.status(404).json({ error: "Produto nao encontrado." });
    } catch (error) {
      return next(error);
    }
  });

  app.post("/api/products", async (request, response, next) => {
    const name = parseName(request.body?.name);
    if (!name) return response.status(400).json({ error: "Nome deve ter entre 1 e 50 caracteres." });

    try {
      return response.status(201).json(await repository.create(name));
    } catch (error) {
      return next(error);
    }
  });

  app.put("/api/products/:id", async (request, response, next) => {
    const id = parseProductId(request.params.id);
    const name = parseName(request.body?.name);
    if (!id) return response.status(400).json({ error: "ID invalido." });
    if (!name) return response.status(400).json({ error: "Nome deve ter entre 1 e 50 caracteres." });

    try {
      const product = await repository.update(id, name);
      return product
        ? response.json(product)
        : response.status(404).json({ error: "Produto nao encontrado." });
    } catch (error) {
      return next(error);
    }
  });

  app.delete("/api/products/:id", async (request, response, next) => {
    const id = parseProductId(request.params.id);
    if (!id) return response.status(400).json({ error: "ID invalido." });

    try {
      const removed = await repository.remove(id);
      return removed
        ? response.status(204).send()
        : response.status(404).json({ error: "Produto nao encontrado." });
    } catch (error) {
      return next(error);
    }
  });

  app.use((_request, response) => response.status(404).json({ error: "Rota nao encontrada." }));
  app.use((error, _request, response, _next) => {
    console.error(error);
    response.status(500).json({ error: "Erro interno do servidor." });
  });

  return app;
}
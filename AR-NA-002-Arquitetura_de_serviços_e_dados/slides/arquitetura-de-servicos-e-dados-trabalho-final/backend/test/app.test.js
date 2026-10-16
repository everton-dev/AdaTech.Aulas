import assert from "node:assert/strict";
import { after, before, describe, it } from "node:test";
import { createApp } from "../src/app.js";

class MemoryRepository {
  constructor() {
    this.products = [{ id: 1, name: "Notebook" }];
    this.nextId = 2;
  }
  async findAll() { return this.products; }
  async findById(id) { return this.products.find((item) => item.id === id) ?? null; }
  async create(name) { const product = { id: this.nextId++, name }; this.products.push(product); return product; }
  async update(id, name) { const product = await this.findById(id); if (!product) return null; product.name = name; return product; }
  async remove(id) { const index = this.products.findIndex((item) => item.id === id); if (index < 0) return false; this.products.splice(index, 1); return true; }
}

describe("Products API", () => {
  let baseUrl;
  let server;

  before(async () => {
    server = createApp(new MemoryRepository()).listen(0, "127.0.0.1");
    await new Promise((resolve) => server.once("listening", resolve));
    baseUrl = `http://127.0.0.1:${server.address().port}`;
  });

  after(() => new Promise((resolve) => server.close(resolve)));

  it("creates, reads, updates and deletes products", async () => {
    const createdResponse = await fetch(`${baseUrl}/api/products`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ name: "Mouse" })
    });
    assert.equal(createdResponse.status, 201);
    const created = await createdResponse.json();

    const readResponse = await fetch(`${baseUrl}/api/products/${created.id}`);
    assert.equal(readResponse.status, 200);

    const updateResponse = await fetch(`${baseUrl}/api/products/${created.id}`, {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ name: "Mouse sem fio" })
    });
    assert.equal(updateResponse.status, 200);
    assert.equal((await updateResponse.json()).name, "Mouse sem fio");

    const deleteResponse = await fetch(`${baseUrl}/api/products/${created.id}`, { method: "DELETE" });
    assert.equal(deleteResponse.status, 204);
  });

  it("rejects invalid product names", async () => {
    const response = await fetch(`${baseUrl}/api/products`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ name: "" })
    });
    assert.equal(response.status, 400);
  });
});
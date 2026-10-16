export class ProductRepository {
  constructor(pool) {
    this.pool = pool;
  }

  async findAll() {
    const result = await this.pool.query("SELECT id, name FROM product ORDER BY id");
    return result.rows;
  }

  async findById(id) {
    const result = await this.pool.query("SELECT id, name FROM product WHERE id = $1", [id]);
    return result.rows[0] ?? null;
  }

  async create(name) {
    const result = await this.pool.query(
      "INSERT INTO product (name) VALUES ($1) RETURNING id, name",
      [name]
    );
    return result.rows[0];
  }

  async update(id, name) {
    const result = await this.pool.query(
      "UPDATE product SET name = $1 WHERE id = $2 RETURNING id, name",
      [name, id]
    );
    return result.rows[0] ?? null;
  }

  async remove(id) {
    const result = await this.pool.query("DELETE FROM product WHERE id = $1", [id]);
    return result.rowCount > 0;
  }
}
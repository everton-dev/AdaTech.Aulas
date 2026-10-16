CREATE TABLE IF NOT EXISTS product (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL CHECK (length(trim(name)) > 0)
);

INSERT INTO product (name)
SELECT seed.name
FROM (VALUES ('Notebook'), ('Monitor'), ('Teclado mecanico')) AS seed(name)
WHERE NOT EXISTS (SELECT 1 FROM product);
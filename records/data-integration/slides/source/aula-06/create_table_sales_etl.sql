DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    order_id UNIQUEIDENTIFIER,
    product_id UNIQUEIDENTIFIER,
    timestamp DATETIME,
    product_name VARCHAR(255),
    quantity SMALLINT,
    unit_price DECIMAL(10, 2)
);

SELECT * FROM sales;
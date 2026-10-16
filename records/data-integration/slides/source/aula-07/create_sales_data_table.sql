-- CREATE TABLE script for Sales_15k.csv
-- Generated based on the structure and data types found in the CSV file

DROP TABLE IF EXISTS Sales;

CREATE TABLE Sales (
    sale_id UNIQUEIDENTIFIER NOT NULL,
    customer_id UNIQUEIDENTIFIER NOT NULL,
    product_id UNIQUEIDENTIFIER NOT NULL,
    sale_date DATETIME NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    discount_percentage INT NOT NULL,
    final_price DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    sales_rep VARCHAR(50) NOT NULL,
    region VARCHAR(20) NOT NULL,
    
    -- Primary key constraint
    CONSTRAINT PK_Sales PRIMARY KEY (sale_id)
);

-- Optional: Add indexes for frequently queried columns
CREATE INDEX IX_Sales_customer_id ON Sales (customer_id);
CREATE INDEX IX_Sales_product_id ON Sales (product_id);
CREATE INDEX IX_Sales_sale_date ON Sales (sale_date);
CREATE INDEX IX_Sales_region ON Sales (region);
CREATE INDEX IX_Sales_sales_rep ON Sales (sales_rep);

-- Optional: Add comments to describe the table
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Sales data table containing transaction records with customer, product, and financial details',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'Sales';

SELECT * FROM Sales WHERE sale_id = 'ba9b67d1-951a-468f-bffc-6fbf341fa5c9';
GO
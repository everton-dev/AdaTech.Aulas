/* =============================================================================
   Ada - Arquitetura de Servicos e Dados / Aula 06
   Script 02 - Seed 10 random products
   Target   : Azure SQL Database
   Usage    : Run after 01_create_products_table.sql. Every execution inserts a
              new batch of 10 rows with randomly picked names and prices.
   ============================================================================= */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.products', N'U') IS NULL
BEGIN
    RAISERROR('Table dbo.products does not exist. Run 01_create_products_table.sql first.', 16, 1);
    RETURN;
END
GO

WITH candidate_products AS
(
    SELECT product_name
    FROM (VALUES
        ('Mechanical Keyboard'),
        ('Wireless Mouse'),
        ('Noise Cancelling Headphones'),
        ('27 inch 4K Monitor'),
        ('USB-C Docking Station'),
        ('Ergonomic Office Chair'),
        ('Height Adjustable Desk'),
        ('1TB NVMe SSD'),
        ('32GB DDR5 Memory Kit'),
        ('Full HD Webcam'),
        ('Condenser Microphone'),
        ('Wi-Fi 6 Router'),
        ('Portable Power Bank'),
        ('Bluetooth Speaker'),
        ('Laptop Cooling Pad'),
        ('Graphics Tablet'),
        ('Smart LED Desk Lamp'),
        ('Cable Management Kit'),
        ('Thunderbolt 4 Cable'),
        ('External Blu-ray Drive')
    ) AS source_names (product_name)
)
INSERT INTO dbo.products (name, price)
SELECT TOP (10)
       product_name,
       /* Random price between 10.00 and 1999.99 with two decimal places. */
       CAST(ROUND(10.0 + (ABS(CHECKSUM(NEWID())) % 199000) / 100.0, 2) AS DECIMAL(10, 2))
FROM candidate_products
ORDER BY NEWID();
GO

PRINT 'Seed completed. Current catalog:';
SELECT id, name, price
FROM dbo.products
ORDER BY id;
GO

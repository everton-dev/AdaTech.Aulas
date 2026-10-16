-- Create SalesWarehouse Table
-- This script creates a comprehensive SalesWarehouse table combining all columns from Customer, Inventory, and Sales tables
-- Duplicate columns are not repeated

-- Drop table if it exists
IF OBJECT_ID('dbo.SalesWarehouse', 'U') IS NOT NULL
    DROP TABLE dbo.SalesWarehouse;
GO

-- Create SalesWarehouse table with all unique columns from Customer, Inventory, and Sales tables
CREATE TABLE dbo.SalesWarehouse (
    -- Primary identifier for warehouse record
    warehouse_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    -- Sales-related columns
    sale_id UNIQUEIDENTIFIER NOT NULL,
    sale_date DATETIME NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    discount_percentage INT NOT NULL,
    final_price DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    sales_rep VARCHAR(50) NOT NULL,
    region VARCHAR(20) NOT NULL,
    
    -- Customer-related columns
    customer_id UNIQUEIDENTIFIER NOT NULL,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    phone NVARCHAR(20),
    date_of_birth DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    address_line1 NVARCHAR(255),
    city NVARCHAR(100),
    state_province NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100) DEFAULT 'USA',
    registration_date DATETIME2,
    customer_tier NVARCHAR(20) DEFAULT 'Bronze',
    credit_limit DECIMAL(10,2) DEFAULT 1000.00,
    loyalty_points INT DEFAULT 0,
    preferred_contact_method NVARCHAR(20) DEFAULT 'Email',
    marketing_consent BIT DEFAULT 0,
    
    -- Inventory/Product-related columns
    inventory_id UNIQUEIDENTIFIER,
    product_id UNIQUEIDENTIFIER NOT NULL,
    product_name NVARCHAR(255) NOT NULL,
    category NVARCHAR(100) NOT NULL,
    brand NVARCHAR(100) NOT NULL,
    supplier_name NVARCHAR(255) NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL,
    reorder_level INT NOT NULL,
    warehouse_location NVARCHAR(100) NOT NULL,
    date_added DATETIME2,
    weight_kg DECIMAL(8,3),
    dimensions_cm NVARCHAR(50),
    barcode NVARCHAR(50),
    warranty_months INT DEFAULT 12,
    
    -- Common columns (avoiding duplication)
    is_active BIT DEFAULT 1,
    created_date DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE()
);
GO

-- Create indexes for better performance on frequently queried columns
-- Sales-related indexes
CREATE INDEX IX_SalesWarehouse_SaleId ON dbo.SalesWarehouse(sale_id);
CREATE INDEX IX_SalesWarehouse_SaleDate ON dbo.SalesWarehouse(sale_date);
CREATE INDEX IX_SalesWarehouse_PaymentMethod ON dbo.SalesWarehouse(payment_method);
CREATE INDEX IX_SalesWarehouse_SalesRep ON dbo.SalesWarehouse(sales_rep);
CREATE INDEX IX_SalesWarehouse_Region ON dbo.SalesWarehouse(region);

-- Customer-related indexes
CREATE INDEX IX_SalesWarehouse_CustomerId ON dbo.SalesWarehouse(customer_id);
CREATE INDEX IX_SalesWarehouse_Email ON dbo.SalesWarehouse(email);
CREATE INDEX IX_SalesWarehouse_LastName ON dbo.SalesWarehouse(last_name);
CREATE INDEX IX_SalesWarehouse_City ON dbo.SalesWarehouse(city);
CREATE INDEX IX_SalesWarehouse_CustomerTier ON dbo.SalesWarehouse(customer_tier);
CREATE INDEX IX_SalesWarehouse_RegistrationDate ON dbo.SalesWarehouse(registration_date);

-- Product-related indexes
CREATE INDEX IX_SalesWarehouse_ProductId ON dbo.SalesWarehouse(product_id);
CREATE INDEX IX_SalesWarehouse_ProductName ON dbo.SalesWarehouse(product_name);
CREATE INDEX IX_SalesWarehouse_Category ON dbo.SalesWarehouse(category);
CREATE INDEX IX_SalesWarehouse_Brand ON dbo.SalesWarehouse(brand);
CREATE INDEX IX_SalesWarehouse_StockQuantity ON dbo.SalesWarehouse(stock_quantity);
CREATE INDEX IX_SalesWarehouse_WarehouseLocation ON dbo.SalesWarehouse(warehouse_location);

-- Composite indexes for common query patterns
CREATE INDEX IX_SalesWarehouse_CustomerProduct ON dbo.SalesWarehouse(customer_id, product_id);
CREATE INDEX IX_SalesWarehouse_SaleDateRegion ON dbo.SalesWarehouse(sale_date, region);
CREATE INDEX IX_SalesWarehouse_CategoryBrand ON dbo.SalesWarehouse(category, brand);
GO

-- Add table description
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Comprehensive sales warehouse table combining customer, product, and sales transaction data for analytics and reporting',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'SalesWarehouse';
GO

-- Add column descriptions for key fields
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Unique identifier for each warehouse record',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'SalesWarehouse',
    @level2type = N'COLUMN', @level2name = N'warehouse_id';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'References the original sale transaction',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'SalesWarehouse',
    @level2type = N'COLUMN', @level2name = N'sale_id';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Customer identifier linking to customer information',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'SalesWarehouse',
    @level2type = N'COLUMN', @level2name = N'customer_id';

EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Product identifier linking to inventory information',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE', @level1name = N'SalesWarehouse',
    @level2type = N'COLUMN', @level2name = N'product_id';
GO

PRINT 'SalesWarehouse table created successfully';
PRINT 'Table includes all unique columns from Customer, Inventory, and Sales tables';
PRINT 'Comprehensive indexes created for optimal query performance';
GO

-- Optional: Create a view for easy data access and analysis
CREATE VIEW dbo.SalesWarehouseSummaryView AS
SELECT 
    warehouse_id,
    sale_id,
    sale_date,
    customer_id,
    CONCAT(first_name, ' ', last_name) AS customer_full_name,
    email,
    customer_tier,
    product_id,
    product_name,
    category,
    brand,
    quantity,
    unit_price,
    total_price,
    discount_percentage,
    final_price,
    payment_method,
    region,
    warehouse_location,
    is_active
FROM dbo.SalesWarehouse
WHERE is_active = 1;
GO

PRINT 'SalesWarehouseSummaryView created for easy data access and reporting';
GO

SELECT * FROM dbo.SalesWarehouse  WHERE sale_id = 'ba9b67d1-951a-468f-bffc-6fbf341fa5c9';
GO
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'analytics_db')
BEGIN
    CREATE DATABASE analytics_db;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'everton')
BEGIN
    CREATE LOGIN [everton] WITH PASSWORD = '@da123*', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
END;
GO

USE analytics_db;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'everton')
BEGIN
    CREATE USER [everton] FOR LOGIN [everton];
END;
GO

IF IS_ROLEMEMBER(N'db_owner', N'everton') <> 1
BEGIN
    ALTER ROLE db_owner ADD MEMBER [everton];
END;
GO

IF OBJECT_ID(N'dbo.DimDate', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimDate (
        DateKey INT NOT NULL CONSTRAINT PK_DimDate PRIMARY KEY,
        FullDate DATE NOT NULL CONSTRAINT UQ_DimDate_FullDate UNIQUE,
        CalendarYear SMALLINT NOT NULL,
        CalendarQuarter TINYINT NOT NULL,
        CalendarMonth TINYINT NOT NULL,
        MonthName NVARCHAR(20) NOT NULL,
        DayOfMonth TINYINT NOT NULL,
        DayOfWeekNumber TINYINT NOT NULL,
        DayOfWeekName NVARCHAR(20) NOT NULL,
        IsWeekend BIT NOT NULL,
        ISOWeekNumber TINYINT NOT NULL
    );
END;
GO

IF OBJECT_ID(N'dbo.DimClient', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimClient (
        ClientKey INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_DimClient PRIMARY KEY,
        ClientBusinessKey INT NOT NULL CONSTRAINT UQ_DimClient_BusinessKey UNIQUE,
        FullName NVARCHAR(120) NOT NULL,
        Email NVARCHAR(160) NOT NULL,
        BirthDate DATE NOT NULL,
        CurrentAgeBand NVARCHAR(20) NOT NULL,
        LoadedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DimClient_LoadedAt DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.DimProduct', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimProduct (
        ProductKey INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_DimProduct PRIMARY KEY,
        ProductBusinessKey INT NOT NULL CONSTRAINT UQ_DimProduct_BusinessKey UNIQUE,
        ProductName NVARCHAR(160) NOT NULL,
        ProductTypeName NVARCHAR(80) NOT NULL,
        UnitPrice DECIMAL(12, 2) NOT NULL,
        PriceBand NVARCHAR(20) NOT NULL,
        IsActive BIT NOT NULL,
        LoadedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DimProduct_LoadedAt DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.DimPaymentType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimPaymentType (
        PaymentTypeKey INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_DimPaymentType PRIMARY KEY,
        PaymentTypeBusinessKey INT NOT NULL CONSTRAINT UQ_DimPaymentType_BusinessKey UNIQUE,
        PaymentTypeName NVARCHAR(40) NOT NULL,
        LoadedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DimPaymentType_LoadedAt DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'dbo.FactOrder', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.FactOrder (
        OrderBusinessKey INT NOT NULL CONSTRAINT PK_FactOrder PRIMARY KEY,
        DateKey INT NOT NULL,
        ClientKey INT NOT NULL,
        PaymentTypeKey INT NOT NULL,
        OrderTimestamp DATETIME2(0) NOT NULL,
        PaymentTimestamp DATETIME2(0) NOT NULL,
        CustomerAgeAtOrder TINYINT NOT NULL,
        CustomerAgeGroup NVARCHAR(20) NOT NULL,
        ItemCount TINYINT NOT NULL,
        TotalQuantity SMALLINT NOT NULL,
        OrderTotal DECIMAL(14, 2) NOT NULL,
        PaymentAmount DECIMAL(14, 2) NOT NULL,
        LoadedAt DATETIME2(0) NOT NULL CONSTRAINT DF_FactOrder_LoadedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_FactOrder_Age CHECK (CustomerAgeAtOrder BETWEEN 0 AND 120),
        CONSTRAINT CK_FactOrder_ItemCount CHECK (ItemCount > 0),
        CONSTRAINT CK_FactOrder_Amounts CHECK (OrderTotal >= 0 AND PaymentAmount >= 0),
        CONSTRAINT FK_FactOrder_Date FOREIGN KEY (DateKey) REFERENCES dbo.DimDate (DateKey),
        CONSTRAINT FK_FactOrder_Client FOREIGN KEY (ClientKey) REFERENCES dbo.DimClient (ClientKey),
        CONSTRAINT FK_FactOrder_PaymentType FOREIGN KEY (PaymentTypeKey) REFERENCES dbo.DimPaymentType (PaymentTypeKey)
    );
END;
GO

IF OBJECT_ID(N'dbo.FactOrderItem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.FactOrderItem (
        OrderItemBusinessKey INT NOT NULL CONSTRAINT PK_FactOrderItem PRIMARY KEY,
        OrderBusinessKey INT NOT NULL,
        DateKey INT NOT NULL,
        ClientKey INT NOT NULL,
        ProductKey INT NOT NULL,
        Quantity INT NOT NULL,
        UnitPrice DECIMAL(12, 2) NOT NULL,
        LineAmount DECIMAL(14, 2) NOT NULL,
        LoadedAt DATETIME2(0) NOT NULL CONSTRAINT DF_FactOrderItem_LoadedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_FactOrderItem_Quantity CHECK (Quantity > 0),
        CONSTRAINT CK_FactOrderItem_Amounts CHECK (UnitPrice >= 0 AND LineAmount >= 0),
        CONSTRAINT FK_FactOrderItem_Order FOREIGN KEY (OrderBusinessKey) REFERENCES dbo.FactOrder (OrderBusinessKey),
        CONSTRAINT FK_FactOrderItem_Date FOREIGN KEY (DateKey) REFERENCES dbo.DimDate (DateKey),
        CONSTRAINT FK_FactOrderItem_Client FOREIGN KEY (ClientKey) REFERENCES dbo.DimClient (ClientKey),
        CONSTRAINT FK_FactOrderItem_Product FOREIGN KEY (ProductKey) REFERENCES dbo.DimProduct (ProductKey)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactOrder_DateKey' AND object_id = OBJECT_ID(N'dbo.FactOrder'))
    CREATE INDEX IX_FactOrder_DateKey ON dbo.FactOrder (DateKey);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactOrder_ClientKey' AND object_id = OBJECT_ID(N'dbo.FactOrder'))
    CREATE INDEX IX_FactOrder_ClientKey ON dbo.FactOrder (ClientKey);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactOrderItem_ProductKey' AND object_id = OBJECT_ID(N'dbo.FactOrderItem'))
    CREATE INDEX IX_FactOrderItem_ProductKey ON dbo.FactOrderItem (ProductKey);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_FactOrderItem_Date_Product' AND object_id = OBJECT_ID(N'dbo.FactOrderItem'))
    CREATE INDEX IX_FactOrderItem_Date_Product ON dbo.FactOrderItem (DateKey, ProductKey);
GO

CREATE OR ALTER VIEW dbo.vw_ClientPurchasesByAge AS
SELECT
    sales_order.CustomerAgeGroup,
    sales_order.CustomerAgeAtOrder,
    COUNT(*) AS OrderCount,
    SUM(sales_order.OrderTotal) AS Revenue,
    AVG(sales_order.OrderTotal) AS AverageTicket
FROM dbo.FactOrder AS sales_order
GROUP BY sales_order.CustomerAgeGroup, sales_order.CustomerAgeAtOrder;
GO

CREATE OR ALTER VIEW dbo.vw_WeekdaySalesFlow AS
SELECT
    calendar.DayOfWeekNumber,
    calendar.DayOfWeekName,
    COUNT(sales_order.OrderBusinessKey) AS OrderCount,
    SUM(sales_order.OrderTotal) AS Revenue,
    AVG(sales_order.OrderTotal) AS AverageTicket
FROM dbo.DimDate AS calendar
LEFT JOIN dbo.FactOrder AS sales_order ON sales_order.DateKey = calendar.DateKey
GROUP BY calendar.DayOfWeekNumber, calendar.DayOfWeekName;
GO

CREATE OR ALTER VIEW dbo.vw_SalesKpis AS
SELECT
    COUNT(*) AS OrderCount,
    COUNT(DISTINCT ClientKey) AS UniqueCustomers,
    SUM(OrderTotal) AS Revenue,
    AVG(OrderTotal) AS AverageTicket,
    SUM(TotalQuantity) AS UnitsSold
FROM dbo.FactOrder;
GO

CREATE OR ALTER VIEW dbo.vw_ProductPerformance AS
SELECT
    product.ProductTypeName,
    product.ProductName,
    SUM(order_item.Quantity) AS UnitsSold,
    SUM(order_item.LineAmount) AS Revenue,
    COUNT(DISTINCT order_item.OrderBusinessKey) AS OrderCount
FROM dbo.FactOrderItem AS order_item
INNER JOIN dbo.DimProduct AS product ON product.ProductKey = order_item.ProductKey
GROUP BY product.ProductTypeName, product.ProductName;
GO

CREATE OR ALTER VIEW dbo.vw_PaymentMethodPerformance AS
SELECT
    payment_type.PaymentTypeName,
    COUNT(*) AS OrderCount,
    SUM(sales_order.PaymentAmount) AS PaidAmount,
    AVG(sales_order.OrderTotal) AS AverageTicket
FROM dbo.FactOrder AS sales_order
INNER JOIN dbo.DimPaymentType AS payment_type ON payment_type.PaymentTypeKey = sales_order.PaymentTypeKey
GROUP BY payment_type.PaymentTypeName;
GO
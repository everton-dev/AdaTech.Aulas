USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'transaction_db')
BEGIN
    CREATE DATABASE transaction_db;
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'everton')
BEGIN
    CREATE LOGIN [everton] WITH PASSWORD = '@da123*', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
END;
GO

USE transaction_db;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
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

IF OBJECT_ID(N'dbo.ProductType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductType (
        ProductTypeId INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_ProductType PRIMARY KEY,
        ProductTypeName NVARCHAR(80) NOT NULL CONSTRAINT UQ_ProductType_ProductTypeName UNIQUE,
        Description NVARCHAR(250) NOT NULL
    );
END;
GO

IF OBJECT_ID(N'dbo.Product', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Product (
        ProductId INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Product PRIMARY KEY,
        ProductTypeId INT NOT NULL,
        ProductName NVARCHAR(160) NOT NULL,
        UnitPrice DECIMAL(12, 2) NOT NULL,
        StockQuantity INT NOT NULL CONSTRAINT DF_Product_StockQuantity DEFAULT 0,
        IsActive BIT NOT NULL CONSTRAINT DF_Product_IsActive DEFAULT 1,
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Product_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_Product_ProductName UNIQUE (ProductName),
        CONSTRAINT CK_Product_UnitPrice CHECK (UnitPrice >= 0),
        CONSTRAINT CK_Product_StockQuantity CHECK (StockQuantity >= 0),
        CONSTRAINT FK_Product_ProductType FOREIGN KEY (ProductTypeId) REFERENCES dbo.ProductType (ProductTypeId)
    );
END;
GO

IF OBJECT_ID(N'dbo.Client', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Client (
        ClientId INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Client PRIMARY KEY,
        FullName NVARCHAR(120) NOT NULL,
        Email NVARCHAR(160) NOT NULL,
        BirthDate DATE NOT NULL,
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Client_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_Client_Email UNIQUE (Email),
        CONSTRAINT CK_Client_BirthDate CHECK (BirthDate >= '1940-01-01' AND BirthDate < '2020-01-01')
    );
END;
GO

IF OBJECT_ID(N'dbo.PaymentType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PaymentType (
        PaymentTypeId INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_PaymentType PRIMARY KEY,
        PaymentTypeName NVARCHAR(40) NOT NULL CONSTRAINT UQ_PaymentType_PaymentTypeName UNIQUE
    );
END;
GO

IF OBJECT_ID(N'dbo.[Order]', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.[Order] (
        OrderId INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Order PRIMARY KEY,
        ExternalOrderCode NVARCHAR(30) NOT NULL CONSTRAINT UQ_Order_ExternalOrderCode UNIQUE,
        ClientId INT NOT NULL,
        OrderDate DATETIME2(0) NOT NULL,
        Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Order_Status DEFAULT N'PAID',
        TotalAmount DECIMAL(14, 2) NOT NULL CONSTRAINT DF_Order_TotalAmount DEFAULT 0,
        CONSTRAINT CK_Order_Status CHECK (Status IN (N'PAID', N'CANCELLED', N'REFUNDED')),
        CONSTRAINT CK_Order_TotalAmount CHECK (TotalAmount >= 0),
        CONSTRAINT FK_Order_Client FOREIGN KEY (ClientId) REFERENCES dbo.Client (ClientId)
    );
END;
GO

IF OBJECT_ID(N'dbo.OrderItem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderItem (
        OrderItemId INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_OrderItem PRIMARY KEY,
        OrderId INT NOT NULL,
        ProductId INT NOT NULL,
        Quantity INT NOT NULL,
        UnitPrice DECIMAL(12, 2) NOT NULL,
        LineTotal AS CONVERT(DECIMAL(14, 2), Quantity * UnitPrice) PERSISTED,
        CONSTRAINT UQ_OrderItem_Order_Product UNIQUE (OrderId, ProductId),
        CONSTRAINT CK_OrderItem_Quantity CHECK (Quantity BETWEEN 1 AND 20),
        CONSTRAINT CK_OrderItem_UnitPrice CHECK (UnitPrice >= 0),
        CONSTRAINT FK_OrderItem_Order FOREIGN KEY (OrderId) REFERENCES dbo.[Order] (OrderId),
        CONSTRAINT FK_OrderItem_Product FOREIGN KEY (ProductId) REFERENCES dbo.Product (ProductId)
    );
END;
GO

IF OBJECT_ID(N'dbo.Payment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payment (
        PaymentId INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_Payment PRIMARY KEY,
        OrderId INT NOT NULL,
        PaymentTypeId INT NOT NULL,
        PaymentDate DATETIME2(0) NOT NULL,
        Amount DECIMAL(14, 2) NOT NULL,
        PaymentReference NVARCHAR(50) NOT NULL,
        CONSTRAINT UQ_Payment_OrderId UNIQUE (OrderId),
        CONSTRAINT UQ_Payment_PaymentReference UNIQUE (PaymentReference),
        CONSTRAINT CK_Payment_Amount CHECK (Amount >= 0),
        CONSTRAINT FK_Payment_Order FOREIGN KEY (OrderId) REFERENCES dbo.[Order] (OrderId),
        CONSTRAINT FK_Payment_PaymentType FOREIGN KEY (PaymentTypeId) REFERENCES dbo.PaymentType (PaymentTypeId)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Product_ProductTypeId' AND object_id = OBJECT_ID(N'dbo.Product'))
    CREATE INDEX IX_Product_ProductTypeId ON dbo.Product (ProductTypeId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Order_ClientId_OrderDate' AND object_id = OBJECT_ID(N'dbo.[Order]'))
    CREATE INDEX IX_Order_ClientId_OrderDate ON dbo.[Order] (ClientId, OrderDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Order_OrderDate' AND object_id = OBJECT_ID(N'dbo.[Order]'))
    CREATE INDEX IX_Order_OrderDate ON dbo.[Order] (OrderDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_OrderItem_ProductId' AND object_id = OBJECT_ID(N'dbo.OrderItem'))
    CREATE INDEX IX_OrderItem_ProductId ON dbo.OrderItem (ProductId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Payment_PaymentTypeId' AND object_id = OBJECT_ID(N'dbo.Payment'))
    CREATE INDEX IX_Payment_PaymentTypeId ON dbo.Payment (PaymentTypeId);
GO
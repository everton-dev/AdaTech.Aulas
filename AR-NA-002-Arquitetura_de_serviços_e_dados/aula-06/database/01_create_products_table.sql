/* =============================================================================
   Ada - Arquitetura de Servicos e Dados / Aula 06
   Script 01 - Create the "products" table
   Target   : Azure SQL Database
   Usage    : Run once against the database consumed by the Products Function App.
   ============================================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.products', N'U') IS NOT NULL
BEGIN
    PRINT 'Table dbo.products already exists. Nothing to do.';
END
ELSE
BEGIN
    /* id is an IDENTITY primary key so that POST /api/products can generate the key
       and GET/PUT/DELETE /api/products/{id} can address a single row unambiguously. */
    CREATE TABLE dbo.products
    (
        id    INT            IDENTITY(1, 1) NOT NULL,
        name  VARCHAR(50)    NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        CONSTRAINT PK_products PRIMARY KEY CLUSTERED (id),
        CONSTRAINT CK_products_price_non_negative CHECK (price >= 0)
    );

    PRINT 'Table dbo.products created.';
END
GO

/* Speeds up lookups by product name. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_products_name' AND object_id = OBJECT_ID(N'dbo.products'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_products_name ON dbo.products (name);
    PRINT 'Index IX_products_name created.';
END
GO

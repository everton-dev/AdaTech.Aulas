USE analytics_db;
GO

SET XACT_ABORT ON;

BEGIN TRANSACTION;

ALTER TABLE dbo.FactOrderItem DROP CONSTRAINT FK_FactOrderItem_Order;
ALTER TABLE dbo.FactOrderItem DROP CONSTRAINT FK_FactOrderItem_Date;
ALTER TABLE dbo.FactOrderItem DROP CONSTRAINT FK_FactOrderItem_Client;
ALTER TABLE dbo.FactOrderItem DROP CONSTRAINT FK_FactOrderItem_Product;
ALTER TABLE dbo.FactOrder DROP CONSTRAINT FK_FactOrder_Date;
ALTER TABLE dbo.FactOrder DROP CONSTRAINT FK_FactOrder_Client;
ALTER TABLE dbo.FactOrder DROP CONSTRAINT FK_FactOrder_PaymentType;

TRUNCATE TABLE dbo.FactOrderItem;
TRUNCATE TABLE dbo.FactOrder;
TRUNCATE TABLE dbo.DimDate;
TRUNCATE TABLE dbo.DimClient;
TRUNCATE TABLE dbo.DimProduct;
TRUNCATE TABLE dbo.DimPaymentType;

ALTER TABLE dbo.FactOrder WITH CHECK ADD CONSTRAINT FK_FactOrder_Date
    FOREIGN KEY (DateKey) REFERENCES dbo.DimDate (DateKey);
ALTER TABLE dbo.FactOrder WITH CHECK ADD CONSTRAINT FK_FactOrder_Client
    FOREIGN KEY (ClientKey) REFERENCES dbo.DimClient (ClientKey);
ALTER TABLE dbo.FactOrder WITH CHECK ADD CONSTRAINT FK_FactOrder_PaymentType
    FOREIGN KEY (PaymentTypeKey) REFERENCES dbo.DimPaymentType (PaymentTypeKey);

ALTER TABLE dbo.FactOrderItem WITH CHECK ADD CONSTRAINT FK_FactOrderItem_Order
    FOREIGN KEY (OrderBusinessKey) REFERENCES dbo.FactOrder (OrderBusinessKey);
ALTER TABLE dbo.FactOrderItem WITH CHECK ADD CONSTRAINT FK_FactOrderItem_Date
    FOREIGN KEY (DateKey) REFERENCES dbo.DimDate (DateKey);
ALTER TABLE dbo.FactOrderItem WITH CHECK ADD CONSTRAINT FK_FactOrderItem_Client
    FOREIGN KEY (ClientKey) REFERENCES dbo.DimClient (ClientKey);
ALTER TABLE dbo.FactOrderItem WITH CHECK ADD CONSTRAINT FK_FactOrderItem_Product
    FOREIGN KEY (ProductKey) REFERENCES dbo.DimProduct (ProductKey);

COMMIT TRANSACTION;
GO

-- select * from DimProduct;
-- select * from DimClient;
-- select * from DimDate;
-- select * from DimPaymentType;
-- select * from FactOrder;
-- select * from FactOrderItem;
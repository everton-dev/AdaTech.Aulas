USE transaction_db;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

WITH Numbers AS (
    SELECT TOP (225) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS OrderNumber
    FROM sys.all_objects AS first_object
    CROSS JOIN sys.all_objects AS second_object
),
Clients AS (
    SELECT ClientId, ROW_NUMBER() OVER (ORDER BY ClientId) AS ClientNumber
    FROM dbo.Client
),
SourceOrders AS (
    SELECT
        CONCAT(N'GEEK-', RIGHT(CONCAT(N'0000', number_set.OrderNumber), 4)) AS ExternalOrderCode,
        client.ClientId,
        DATEADD(MINUTE, (number_set.OrderNumber * 37) % 600,
            DATEADD(DAY, -((number_set.OrderNumber * 7) % 180), CAST('2026-08-20T09:00:00' AS DATETIME2))) AS OrderDate
    FROM Numbers AS number_set
    INNER JOIN Clients AS client ON client.ClientNumber = ((number_set.OrderNumber - 1) % 50) + 1
)
MERGE dbo.[Order] AS target
USING SourceOrders AS source
ON target.ExternalOrderCode = source.ExternalOrderCode
WHEN MATCHED THEN UPDATE SET ClientId = source.ClientId, OrderDate = source.OrderDate, Status = N'PAID'
WHEN NOT MATCHED THEN INSERT (ExternalOrderCode, ClientId, OrderDate, Status) VALUES (source.ExternalOrderCode, source.ClientId, source.OrderDate, N'PAID');
GO

WITH OrderRequirements AS (
    SELECT OrderId, 2 + ((OrderId * 7) % 49) AS RequiredItemCount
    FROM dbo.[Order]
),
ItemNumbers AS (
    SELECT requirement.OrderId, generated.ItemNumber
    FROM OrderRequirements AS requirement
    CROSS APPLY (
        SELECT TOP (requirement.RequiredItemCount)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ItemNumber
        FROM sys.all_objects AS first_object
        CROSS JOIN sys.all_objects AS second_object
    ) AS generated
),
ProductNumbers AS (
    SELECT ProductId, UnitPrice, ROW_NUMBER() OVER (ORDER BY ProductId) AS ProductNumber
    FROM dbo.Product
),
CandidateItems AS (
    SELECT
        item_number.OrderId,
        product.ProductId,
        1 + ((item_number.OrderId + item_number.ItemNumber * 3) % 5) AS Quantity,
        product.UnitPrice
    FROM ItemNumbers AS item_number
    INNER JOIN ProductNumbers AS product
        ON product.ProductNumber = ((item_number.OrderId * 31 + item_number.ItemNumber * 17) % 200) + 1
)
INSERT INTO dbo.OrderItem (OrderId, ProductId, Quantity, UnitPrice)
SELECT candidate.OrderId, candidate.ProductId, candidate.Quantity, candidate.UnitPrice
FROM CandidateItems AS candidate
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.OrderItem AS existing_item
    WHERE existing_item.OrderId = candidate.OrderId
      AND existing_item.ProductId = candidate.ProductId
);
GO

UPDATE sales_order
SET TotalAmount = totals.TotalAmount
FROM dbo.[Order] AS sales_order
INNER JOIN (
    SELECT OrderId, SUM(LineTotal) AS TotalAmount
    FROM dbo.OrderItem
    GROUP BY OrderId
) AS totals ON totals.OrderId = sales_order.OrderId;
GO

WITH PaymentTypeNumbers AS (
    SELECT PaymentTypeId, ROW_NUMBER() OVER (ORDER BY PaymentTypeId) AS PaymentTypeNumber
    FROM dbo.PaymentType
),
SourcePayments AS (
    SELECT
        sales_order.OrderId,
        payment_type.PaymentTypeId,
        DATEADD(MINUTE, 3, sales_order.OrderDate) AS PaymentDate,
        sales_order.TotalAmount AS Amount,
        CONCAT(N'PAY-', RIGHT(CONCAT(N'000000', sales_order.OrderId), 6)) AS PaymentReference
    FROM dbo.[Order] AS sales_order
    INNER JOIN PaymentTypeNumbers AS payment_type
        ON payment_type.PaymentTypeNumber = ((sales_order.OrderId - 1) % 4) + 1
)
MERGE dbo.Payment AS target
USING SourcePayments AS source
ON target.OrderId = source.OrderId
WHEN MATCHED THEN UPDATE SET
    PaymentTypeId = source.PaymentTypeId,
    PaymentDate = source.PaymentDate,
    Amount = source.Amount,
    PaymentReference = source.PaymentReference
WHEN NOT MATCHED THEN INSERT (OrderId, PaymentTypeId, PaymentDate, Amount, PaymentReference)
    VALUES (source.OrderId, source.PaymentTypeId, source.PaymentDate, source.Amount, source.PaymentReference);
GO

IF (SELECT COUNT(*) FROM dbo.Product) <> 200
    THROW 51000, 'Expected exactly 200 geek products.', 1;
IF (SELECT COUNT(*) FROM dbo.Client) <> 50
    THROW 51000, 'Expected exactly 50 geek clients.', 1;
IF (SELECT COUNT(*) FROM dbo.[Order]) < 201
    THROW 51000, 'Expected more than 200 orders.', 1;
IF EXISTS (
    SELECT 1
    FROM dbo.[Order] AS sales_order
    OUTER APPLY (SELECT COUNT(*) AS ItemCount FROM dbo.OrderItem WHERE OrderId = sales_order.OrderId) AS item_count
    WHERE item_count.ItemCount NOT BETWEEN 2 AND 50
)
    THROW 51000, 'Each order must have between 2 and 50 items.', 1;
IF (SELECT COUNT(*) FROM dbo.Payment) <> (SELECT COUNT(*) FROM dbo.[Order])
    THROW 51000, 'Each order must have exactly one payment.', 1;
GO
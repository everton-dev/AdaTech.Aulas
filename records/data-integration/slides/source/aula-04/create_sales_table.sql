-- SQL Server script to create Sales table and insert sample data

DROP TABLE IF EXISTS Sales;

-- Create the Sales table
CREATE TABLE Sales (
    ProductId UNIQUEIDENTIFIER NOT NULL,
    ProductName NVARCHAR(200),
    Quantity NVARCHAR(200),
    UnitPrice DECIMAL(10, 2),
    TotalAmount DECIMAL(10, 2),
    FileName NVARCHAR(255),
    TotalFileRows INT,
    TimeStamp DATETIME
);

SELECT * FROM Sales;

SELECT * 
FROM Sales
WHERE [FileName] = 'products_02.csv';

SELECT [ProductName], 
       COUNT(*) AS TotalSales, 
       SUM(TotalAmount) AS TotalAmount 
FROM Sales
GROUP BY [ProductName]
ORDER BY TotalSales DESC;


SELECT [FileName], 
       COUNT(*) AS TotalRows, 
       SUM(TotalAmount) AS TotalAmount 
FROM Sales
GROUP BY [FileName]


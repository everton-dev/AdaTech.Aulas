-- SQL Server script to create Customer table and insert sample data

-- Create the Customer table
CREATE TABLE Customer (
    id INT PRIMARY KEY,
    name NVARCHAR(50),
    email NVARCHAR(50),
    timestamp DATE
);

-- Insert 3 sample rows
INSERT INTO Customer (id, name, email, timestamp) VALUES
(1, 'João Silva', 'joao.silva@email.com', '2025-01-15'),
(2, 'Maria Santos', 'maria.santos@email.com', '2025-02-20'),
(3, 'Pedro Oliveira', 'pedro.oliveira@email.com', '2025-03-10');

-- Query to verify the data
SELECT * FROM Customer;

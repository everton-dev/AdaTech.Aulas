IF OBJECT_ID('dbo.Car') IS NULL
BEGIN
	CREATE TABLE dbo.Car (
		  Id		INT PRIMARY KEY IDENTITY(1,1)
		, Brand		VARCHAR(50)
		, Model		VARCHAR(50)
		, Year		INT
	);

	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Toyota', 'Corolla', 2015);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Toyota', 'Camry', 2016);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Toyota', 'RAV4', 2017);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Toyota', 'Highlander', 2018);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Ferrari', 'Portofino', 2018);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Ferrari', '488 GTB', 2019);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Ferrari', '812 Superfast', 2020);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Ferrari', 'SF90 Stradale', 2021);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Jaguar', 'F-Type', 2019);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Jaguar', 'F‑PACE', 2020);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Jaguar', 'E‑PACE', 2021);
	INSERT INTO dbo.Car (Brand, Model, Year) VALUES ('Jaguar', 'F‑TYPE', 2022);
END
GO

SELECT * FROM dbo.Car;
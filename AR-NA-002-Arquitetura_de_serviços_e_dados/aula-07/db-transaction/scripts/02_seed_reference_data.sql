USE transaction_db;
GO

MERGE dbo.ProductType AS target
USING (VALUES
    (N'Action Figure', N'Articulated figures and collector statues.'),
    (N'Manga', N'Graphic novels and manga-inspired editions.'),
    (N'Cosplay', N'Costumes, props, and wearable character items.'),
    (N'Funk Pop', N'Vinyl collectible figures.'),
    (N'Board Game', N'Tabletop and strategy games.'),
    (N'Collectible', N'Cards, replicas, and collectible accessories.'),
    (N'Gaming', N'Gaming accessories and themed equipment.'),
    (N'Apparel', N'Geek clothing and apparel.')
) AS source (ProductTypeName, Description)
ON target.ProductTypeName = source.ProductTypeName
WHEN MATCHED THEN UPDATE SET Description = source.Description
WHEN NOT MATCHED THEN INSERT (ProductTypeName, Description) VALUES (source.ProductTypeName, source.Description);
GO

MERGE dbo.PaymentType AS target
USING (VALUES (N'Cash'), (N'Debit Card'), (N'Credit Card'), (N'Pix')) AS source (PaymentTypeName)
ON target.PaymentTypeName = source.PaymentTypeName
WHEN NOT MATCHED THEN INSERT (PaymentTypeName) VALUES (source.PaymentTypeName);
GO

WITH Franchises AS (
    SELECT * FROM (VALUES
        (1, N'Star Wars'), (2, N'Marvel'), (3, N'DC Comics'), (4, N'Harry Potter'),
        (5, N'Lord of the Rings'), (6, N'Star Trek'), (7, N'Dragon Ball'), (8, N'Naruto'),
        (9, N'One Piece'), (10, N'Pokemon'), (11, N'Zelda'), (12, N'Mario'),
        (13, N'Cyberpunk'), (14, N'The Witcher'), (15, N'Stranger Things'), (16, N'Dune'),
        (17, N'Alien'), (18, N'Fallout'), (19, N'Arcane'), (20, N'Doctor Who')
    ) AS value_set (FranchiseNumber, FranchiseName)
),
ItemTemplates AS (
    SELECT * FROM (VALUES
        (1, N'Action Figure', N'Action Figure'),
        (2, N'Action Figure', N'Collector Statue'),
        (3, N'Manga', N'Manga Edition'),
        (4, N'Cosplay', N'Cosplay Costume'),
        (5, N'Funk Pop', N'Funk Pop Vinyl'),
        (6, N'Board Game', N'Board Game'),
        (7, N'Collectible', N'Trading Card Set'),
        (8, N'Gaming', N'Gaming Mousepad'),
        (9, N'Apparel', N'Graphic T-Shirt'),
        (10, N'Collectible', N'Replica Keychain')
    ) AS value_set (TemplateNumber, ProductTypeName, ItemName)
),
SourceProducts AS (
    SELECT
        CONCAT(franchise.FranchiseName, N' ', template.ItemName) AS ProductName,
        template.ProductTypeName,
        CAST(9.99 + ((franchise.FranchiseNumber * 13 + template.TemplateNumber * 17) % 180) * 2.75 AS DECIMAL(12, 2)) AS UnitPrice,
        10 + ((franchise.FranchiseNumber * 19 + template.TemplateNumber * 11) % 91) AS StockQuantity
    FROM Franchises AS franchise
    CROSS JOIN ItemTemplates AS template
)
MERGE dbo.Product AS target
USING (
    SELECT product.ProductName, product.UnitPrice, product.StockQuantity, product_type.ProductTypeId
    FROM SourceProducts AS product
    INNER JOIN dbo.ProductType AS product_type ON product_type.ProductTypeName = product.ProductTypeName
) AS source
ON target.ProductName = source.ProductName
WHEN MATCHED THEN UPDATE SET
    ProductTypeId = source.ProductTypeId,
    UnitPrice = source.UnitPrice,
    StockQuantity = source.StockQuantity,
    IsActive = 1
WHEN NOT MATCHED THEN INSERT (ProductTypeId, ProductName, UnitPrice, StockQuantity)
    VALUES (source.ProductTypeId, source.ProductName, source.UnitPrice, source.StockQuantity);
GO

MERGE dbo.Client AS target
USING (VALUES
    (N'Luke Skywalker', N'luke.skywalker@geekshop.local', '1977-05-25'),
    (N'Leia Organa', N'leia.organa@geekshop.local', '1978-10-21'),
    (N'Han Solo', N'han.solo@geekshop.local', '1972-07-14'),
    (N'Rey Skywalker', N'rey.skywalker@geekshop.local', '1996-12-15'),
    (N'Din Djarin', N'din.djarin@geekshop.local', '1984-02-11'),
    (N'Ahsoka Tano', N'ahsoka.tano@geekshop.local', '1988-01-27'),
    (N'Tony Stark', N'tony.stark@geekshop.local', '1970-05-29'),
    (N'Pepper Potts', N'pepper.potts@geekshop.local', '1976-08-19'),
    (N'Peter Parker', N'peter.parker@geekshop.local', '1999-08-10'),
    (N'Natasha Romanoff', N'natasha.romanoff@geekshop.local', '1983-11-22'),
    (N'Steve Rogers', N'steve.rogers@geekshop.local', '1975-07-04'),
    (N'Bruce Banner', N'bruce.banner@geekshop.local', '1974-12-18'),
    (N'Diana Prince', N'diana.prince@geekshop.local', '1985-03-22'),
    (N'Clark Kent', N'clark.kent@geekshop.local', '1979-06-18'),
    (N'Bruce Wayne', N'bruce.wayne@geekshop.local', '1973-02-19'),
    (N'Barry Allen', N'barry.allen@geekshop.local', '1992-09-30'),
    (N'Arthur Curry', N'arthur.curry@geekshop.local', '1981-01-29'),
    (N'Wanda Maximoff', N'wanda.maximoff@geekshop.local', '1990-02-10'),
    (N'Hermione Granger', N'hermione.granger@geekshop.local', '1994-09-19'),
    (N'Harry Potter', N'harry.potter@geekshop.local', '1993-07-31'),
    (N'Ron Weasley', N'ron.weasley@geekshop.local', '1993-03-01'),
    (N'Luna Lovegood', N'luna.lovegood@geekshop.local', '1995-02-13'),
    (N'Frodo Baggins', N'frodo.baggins@geekshop.local', '1980-09-22'),
    (N'Samwise Gamgee', N'samwise.gamgee@geekshop.local', '1981-04-06'),
    (N'Aragorn Elessar', N'aragorn.elessar@geekshop.local', '1976-03-01'),
    (N'Galadriel Noldor', N'galadriel.noldor@geekshop.local', '1971-10-08'),
    (N'Neo Anderson', N'neo.anderson@geekshop.local', '1987-03-11'),
    (N'Trinity Moss', N'trinity.moss@geekshop.local', '1987-09-23'),
    (N'Ellen Ripley', N'ellen.ripley@geekshop.local', '1970-01-07'),
    (N'Sarah Connor', N'sarah.connor@geekshop.local', '1972-12-13'),
    (N'TChalla Wakanda', N'tchalla.wakanda@geekshop.local', '1986-05-26'),
    (N'Shuri Wakanda', N'shuri.wakanda@geekshop.local', '1998-04-11'),
    (N'Miles Morales', N'miles.morales@geekshop.local', '2001-08-03'),
    (N'Gwen Stacy', N'gwen.stacy@geekshop.local', '1998-11-18'),
    (N'Lara Croft', N'lara.croft@geekshop.local', '1989-02-14'),
    (N'Nathan Drake', N'nathan.drake@geekshop.local', '1985-06-20'),
    (N'Master Chief', N'master.chief@geekshop.local', '1979-03-07'),
    (N'Cortana Halo', N'cortana.halo@geekshop.local', '1997-10-16'),
    (N'Mario Mario', N'mario.mario@geekshop.local', '1982-09-13'),
    (N'Princess Peach', N'princess.peach@geekshop.local', '1987-05-07'),
    (N'Link Hyrule', N'link.hyrule@geekshop.local', '1994-02-21'),
    (N'Zelda Hyrule', N'zelda.hyrule@geekshop.local', '1992-12-24'),
    (N'Geralt Rivia', N'geralt.rivia@geekshop.local', '1976-05-01'),
    (N'Ciri Cintra', N'ciri.cintra@geekshop.local', '1999-05-10'),
    (N'Eleven Hopper', N'eleven.hopper@geekshop.local', '2002-02-17'),
    (N'Wednesday Addams', N'wednesday.addams@geekshop.local', '2000-10-31'),
    (N'Spock Vulcan', N'spock.vulcan@geekshop.local', '1975-01-06'),
    (N'Nyota Uhura', N'nyota.uhura@geekshop.local', '1984-07-23'),
    (N'Dana Scully', N'dana.scully@geekshop.local', '1978-02-24'),
    (N'Fox Mulder', N'fox.mulder@geekshop.local', '1976-10-13')
) AS source (FullName, Email, BirthDate)
ON target.Email = source.Email
WHEN MATCHED THEN UPDATE SET FullName = source.FullName, BirthDate = source.BirthDate
WHEN NOT MATCHED THEN INSERT (FullName, Email, BirthDate) VALUES (source.FullName, source.Email, source.BirthDate);
GO
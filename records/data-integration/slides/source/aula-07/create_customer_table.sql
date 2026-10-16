-- Create Customer Table and Insert Data from CSV
-- This script creates the Customer table and provides instructions for data import

-- Drop table if it exists
IF OBJECT_ID('dbo.Customer', 'U') IS NOT NULL
    DROP TABLE dbo.Customer;
GO

-- Create Customer table
CREATE TABLE dbo.Customer (
    customer_id UNIQUEIDENTIFIER PRIMARY KEY,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
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
    is_active BIT DEFAULT 1,
    created_date DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE()
);
GO

-- Create indexes for better performance
CREATE INDEX IX_Customer_Email ON dbo.Customer(email);
CREATE INDEX IX_Customer_LastName ON dbo.Customer(last_name);
CREATE INDEX IX_Customer_City ON dbo.Customer(city);
CREATE INDEX IX_Customer_CustomerTier ON dbo.Customer(customer_tier);
CREATE INDEX IX_Customer_RegistrationDate ON dbo.Customer(registration_date);
GO

PRINT 'Customer table created successfully';
PRINT 'Table structure ready for CSV import';
GO

-- Insert all customer data
INSERT INTO dbo.Customer (
    customer_id, first_name, last_name, email, phone, date_of_birth,
    gender, address_line1, city, state_province, postal_code, country,
    registration_date, customer_tier, credit_limit, loyalty_points,
    preferred_contact_method, marketing_consent, is_active
)
VALUES
    ('b9566e8f-c0e6-4c5c-85f3-790d86086039', 'Walter', 'Allen', 'walter.allen001@hotmail.com', '+17916423752', '1977-01-12', 'M', '8440 Elm Dr', 'El Paso', 'TX', '77382', 'USA', '2023-09-16 14:06:07', 'Silver', 8935.11, 1097, 'Email', 0, 1),
    ('63a1868b-0448-4b5e-a5c9-319fd308fcc2', 'Paul', 'Young', 'paul.young002@yahoo.com', '+17734630810', '1995-10-09', 'F', '4068 Maple St', 'Louisville', 'KY', '37463', 'USA', '2024-05-29 14:06:07', 'Bronze', 2311.83, 531, 'SMS', 1, 1),
    ('c8f009fa-b763-47b6-b929-d8ccb35c70bf', 'Michael', 'Lewis', 'michael.lewis003@yahoo.com', '+14035081052', '1991-06-14', 'M', '1897 Main St', 'Detroit', 'MI', '61333', 'USA', '2024-01-30 14:06:07', 'Diamond', 2278.37, 5749, 'SMS', 0, 1),
    ('d2d2bd06-f096-46c1-94cb-3cc07808f56a', 'Lisa', 'Reed', 'lisa.reed004@live.com', '+13097305609', '1989-05-14', 'F', '2564 Elm Dr', 'Denver', 'CO', '47857', 'USA', '2023-02-01 14:06:07', 'Diamond', 3938.17, 7756, 'SMS', 1, 1),
    ('41562c2b-5138-4cf8-86c9-ffdc99e7b5ca', 'William', 'Thomas', 'william.thomas005@protonmail.com', '+15322835976', '1982-11-27', 'F', '476 Cedar Ln', 'New York', 'NY', '46356', 'USA', '2024-10-12 14:06:07', 'Gold', 2624.44, 3482, 'SMS', 1, 1),
    ('0ab77398-de5a-4ba4-9a0c-2ef90816e568', 'Emma', 'Cox', 'emma.cox006@yahoo.com', '+16255372199', '1981-05-21', 'M', '1050 Maple St', 'New York', 'NY', '24573', 'USA', '2023-09-12 14:06:07', 'Platinum', 5859.97, 2035, 'Phone', 1, 1),
    ('105cbdac-a2c4-44d8-9087-e0caa5bd5560', 'Sharon', 'Young', 'sharon.young007@outlook.com', '+13565868400', '1960-12-13', 'M', '5876 Elm Dr', 'Jacksonville', 'FL', '14246', 'USA', '2023-10-25 14:06:07', 'Diamond', 6690.58, 3317, 'SMS', 0, 1),
    ('ce66173a-9aa4-425b-9ca6-c84eb393419f', 'Cynthia', 'Smith', 'cynthia.smith008@protonmail.com', '+14230572790', '1996-12-07', 'F', '2391 Elm Dr', 'Los Angeles', 'CA', '95912', 'USA', '2023-05-24 14:06:07', 'Gold', 1090.88, 282, 'Phone', 1, 0),
    ('8871cc26-3b05-4802-9aae-48bce6cdde4f', 'Matthew', 'Martinez', 'matthew.martinez009@icloud.com', '+19301785230', '1994-01-25', 'M', '9801 Pine Rd', 'Las Vegas', 'NV', '36723', 'USA', '2024-03-28 14:06:07', 'Platinum', 4437.31, 9444, 'Email', 0, 1),
    ('b718e985-ac21-49e3-9c59-33693b3517fc', 'Kevin', 'Bailey', 'kevin.bailey010@gmail.com', '+15285663789', '1985-05-31', 'M', '6864 Pine Rd', 'Fort Worth', 'TX', '93277', 'USA', '2025-04-20 14:06:07', 'Platinum', 4186.12, 6892, 'SMS', 1, 1),
    ('8d688e86-4f8b-422a-a68b-ee3c4ecbdbdd', 'Robert', 'Cooper', 'robert.cooper011@hotmail.com', '+12248771953', '1971-09-13', 'M', '9256 Elm Dr', 'Chicago', 'IL', '50232', 'USA', '2023-05-16 14:06:07', 'Diamond', 4910.77, 6862, 'SMS', 1, 1),
    ('82fb6409-dc34-4fad-ae1e-99c849a719d7', 'Jose', 'Parker', 'jose.parker012@live.com', '+16992668960', '2002-10-17', 'M', '5431 Pine Rd', 'Phoenix', 'AZ', '46982', 'USA', '2022-10-22 14:06:07', 'Gold', 9505.27, 3116, 'SMS', 1, 1),
    ('929f02d1-d918-49ab-a770-b4149df91246', 'Amy', 'Hill', 'amy.hill013@protonmail.com', '+12420652887', '1982-03-20', 'M', '8488 Cedar Ln', 'New York', 'NY', '80671', 'USA', '2023-03-10 14:06:07', 'Platinum', 8839.5, 5491, 'Phone', 1, 1),
    ('9ad3ef80-1634-4648-9f95-63dc2d6778a6', 'Emma', 'Reed', 'emma.reed014@live.com', '+16890937995', '1980-08-25', 'F', '5215 Cedar Ln', 'Seattle', 'WA', '49016', 'USA', '2025-02-23 14:06:07', 'Platinum', 4814.65, 9123, 'Phone', 1, 1),
    ('cd6f82c7-e202-444b-a813-d0ffbb81e447', 'Edward', 'Lewis', 'edward.lewis015@gmail.com', '+19519009123', '1968-02-12', 'F', '5567 Main St', 'Boston', 'MA', '86673', 'USA', '2024-12-23 14:06:07', 'Bronze', 9021.32, 1102, 'Phone', 0, 1),
    ('4b8c3769-8722-423a-9f0f-1eac37fe7914', 'Cynthia', 'Stewart', 'cynthia.stewart016@outlook.com', '+18835451787', '1991-10-20', 'F', '1295 Pine Rd', 'Los Angeles', 'CA', '15228', 'USA', '2025-04-02 14:06:07', 'Bronze', 9159.37, 9077, 'SMS', 1, 1),
    ('c2f9e9af-b355-43cd-ba0d-05aa8f675a96', 'Roger', 'Hall', 'roger.hall017@gmail.com', '+17818577527', '1994-06-30', 'M', '4420 Pine Rd', 'Denver', 'CO', '67459', 'USA', '2024-05-19 14:06:07', 'Gold', 2481.34, 9324, 'Email', 0, 0),
    ('5a1c9946-e006-45fe-bf8e-cce42cdbcc79', 'Susan', 'Edwards', 'susan.edwards018@protonmail.com', '+19224350966', '1976-08-19', 'M', '9104 Main St', 'Los Angeles', 'CA', '84691', 'USA', '2024-02-09 14:06:07', 'Silver', 3686.52, 624, 'Email', 0, 1),
    ('d06c3778-a802-41b7-99fd-cd7aea3aba68', 'Amy', 'Wilson', 'amy.wilson019@outlook.com', '+13927077589', '2000-07-24', 'M', '1461 Main St', 'San Antonio', 'TX', '24996', 'USA', '2025-02-07 14:06:07', 'Platinum', 9573.25, 5672, 'SMS', 1, 1),
    ('95a81a63-290b-4fe1-8ffe-bd7e410d1c23', 'Betty', 'Taylor', 'betty.taylor020@aol.com', '+15944585265', '1997-11-28', 'M', '5486 Elm Dr', 'Chicago', 'IL', '42630', 'USA', '2023-04-14 14:06:07', 'Gold', 7578.72, 808, 'Email', 1, 1),
    ('46821275-f2fc-4dc8-a31e-60782c7947e2', 'Paul', 'Carter', 'paul.carter021@hotmail.com', '+14006394372', '2004-03-01', 'M', '1635 Cedar Ln', 'New York', 'NY', '79539', 'USA', '2023-02-07 14:06:07', 'Bronze', 3599.08, 9103, 'Email', 0, 1),
    ('30bd3c6d-d818-4b12-ab04-7d9ff9eed3f8', 'Julie', 'Young', 'julie.young022@gmail.com', '+12409331087', '1989-02-06', 'F', '106 Main St', 'Houston', 'TX', '70569', 'USA', '2022-10-03 14:06:07', 'Bronze', 7032.64, 1482, 'Phone', 0, 1),
    ('d4112e97-d4b3-472d-af45-9ebca29bb4b9', 'Harold', 'Smith', 'harold.smith023@outlook.com', '+19416493747', '1995-01-05', 'F', '4065 Oak Ave', 'Portland', 'OR', '20542', 'USA', '2024-07-10 14:06:07', 'Silver', 8155.76, 4879, 'SMS', 1, 0),
    ('216dba21-d459-416a-b835-eedf9b245848', 'Lisa', 'Rodriguez', 'lisa.rodriguez024@hotmail.com', '+13417898598', '2002-09-20', 'F', '7087 Maple St', 'San Diego', 'CA', '83694', 'USA', '2025-07-17 14:06:07', 'Diamond', 4251.36, 2657, 'Email', 1, 0),
    ('6ac1ba33-1a7c-49b4-8d37-c134ea1c20bd', 'Jacob', 'Garcia', 'jacob.garcia025@icloud.com', '+16584298995', '1999-01-30', 'M', '8022 Cedar Ln', 'Oklahoma City', 'OK', '88783', 'USA', '2024-02-10 14:06:07', 'Gold', 2443.48, 3400, 'SMS', 0, 1),
    ('869ed930-7b05-4adb-ab98-9a49c8c59810', 'Harold', 'Nelson', 'harold.nelson026@live.com', '+12212088084', '1998-03-09', 'F', '8103 Oak Ave', 'Detroit', 'MI', '85693', 'USA', '2024-08-22 14:06:07', 'Silver', 3121.13, 5972, 'Phone', 1, 1),
    ('b5113ff3-f2b2-4c74-b6a7-3c765ada49d3', 'Joe', 'Perez', 'joe.perez027@live.com', '+13631585775', '1987-04-08', 'F', '6269 Pine Rd', 'Boston', 'MA', '36909', 'USA', '2025-06-29 14:06:07', 'Gold', 1340.88, 584, 'Email', 1, 0),
    ('42b12bca-8e91-4c56-bf62-b673ecc53715', 'Betty', 'Wilson', 'betty.wilson028@aol.com', '+18797017258', '1974-07-10', 'F', '7982 Main St', 'Las Vegas', 'NV', '20252', 'USA', '2024-01-16 14:06:07', 'Bronze', 4300.81, 6424, 'Email', 1, 1),
    ('cff1f454-08a9-4aff-9740-28f2d9cfcc96', 'Jacob', 'Taylor', 'jacob.taylor029@live.com', '+16628963449', '1990-03-20', 'M', '7502 Cedar Ln', 'San Francisco', 'CA', '13038', 'USA', '2024-03-28 14:06:07', 'Platinum', 7251.44, 8207, 'Email', 1, 1),
    ('0121ae59-8ba8-43eb-ae01-77059688c0af', 'Christopher', 'Howard', 'christopher.howard030@outlook.com', '+18892070342', '1971-10-05', 'F', '8160 Oak Ave', 'Nashville', 'TN', '58731', 'USA', '2024-04-04 14:06:07', 'Silver', 1812.06, 7826, 'Phone', 0, 1),
    ('e4521e7b-59bb-4c30-913d-b66432b71053', 'James', 'Lewis', 'james.lewis031@gmail.com', '+18188623974', '1995-06-16', 'F', '1925 Oak Ave', 'Phoenix', 'AZ', '53940', 'USA', '2023-12-09 14:06:07', 'Gold', 4971.18, 5177, 'Email', 0, 1),
    ('19a0dc28-fc02-43db-9e7b-c7acbd6aeb78', 'Emma', 'Cook', 'emma.cook032@hotmail.com', '+13622257179', '1962-01-13', 'F', '166 Oak Ave', 'San Diego', 'CA', '11770', 'USA', '2023-04-07 14:06:07', 'Diamond', 7958.03, 7631, 'SMS', 0, 0),
    ('d98731bd-3157-46a9-ac09-48b17b8d9721', 'Linda', 'Parker', 'linda.parker033@protonmail.com', '+18220961156', '2004-10-26', 'M', '1559 Maple St', 'San Francisco', 'CA', '70353', 'USA', '2023-12-11 14:06:07', 'Platinum', 5498.41, 9727, 'SMS', 1, 0),
    ('e3e8b62b-513c-4f84-a71e-778bd391e633', 'Angela', 'Reed', 'angela.reed034@protonmail.com', '+16823561397', '1969-04-16', 'M', '1130 Pine Rd', 'Houston', 'TX', '91220', 'USA', '2024-06-21 14:06:07', 'Diamond', 2040.14, 8371, 'SMS', 1, 0),
    ('4c70693c-b210-4fdb-ac84-94a561510b83', 'Joyce', 'Phillips', 'joyce.phillips035@hotmail.com', '+15076364161', '1992-03-16', 'M', '3774 Elm Dr', 'Memphis', 'TN', '13352', 'USA', '2024-06-09 14:06:07', 'Platinum', 6982.15, 3485, 'Email', 1, 1),
    ('6151460e-9744-4cfb-a121-e8fa1ad8b82b', 'Jessica', 'Martinez', 'jessica.martinez036@hotmail.com', '+15567176257', '1998-02-04', 'F', '8703 Pine Rd', 'New York', 'NY', '25751', 'USA', '2024-07-02 14:06:07', 'Bronze', 1912.82, 8777, 'Email', 0, 0),
    ('5c1df3e9-8ef4-4631-b3ff-c32f89c1d520', 'Daniel', 'Lopez', 'daniel.lopez037@aol.com', '+14410012106', '2001-03-19', 'M', '1066 Cedar Ln', 'El Paso', 'TX', '79422', 'USA', '2025-05-08 14:06:07', 'Gold', 6149.91, 1102, 'SMS', 0, 0),
    ('73d6975d-aa37-4d1c-9e4f-40b054691532', 'Mark', 'Harris', 'mark.harris038@yahoo.com', '+14169654384', '2000-03-13', 'F', '7008 Oak Ave', 'Indianapolis', 'IN', '26058', 'USA', '2025-06-20 14:06:07', 'Gold', 1326.09, 8323, 'Phone', 1, 1),
    ('b8da96b2-1dac-40e0-b921-7f3333160eda', 'Anthony', 'Adams', 'anthony.adams039@hotmail.com', '+14445469731', '1983-02-09', 'F', '308 Maple St', 'Philadelphia', 'PA', '59986', 'USA', '2022-09-07 14:06:07', 'Diamond', 7561.84, 130, 'Phone', 1, 1),
    ('63c90fa6-b4b8-477c-b4f6-f6c7838c6ddf', 'Jose', 'Brown', 'jose.brown040@live.com', '+17038724790', '2004-08-20', 'F', '5035 Elm Dr', 'Boston', 'MA', '41253', 'USA', '2023-01-07 14:06:07', 'Platinum', 7876.15, 4376, 'SMS', 0, 1),
    ('e1a819ec-f63c-4be4-a493-55eb54b37363', 'Barbara', 'Green', 'barbara.green041@hotmail.com', '+15631352423', '1989-02-06', 'M', '2588 Maple St', 'Portland', 'OR', '63352', 'USA', '2024-09-01 14:06:07', 'Bronze', 7362.12, 4867, 'SMS', 1, 0),
    ('fb6a49de-7375-43de-9d35-35e62e60035e', 'Arthur', 'Brown', 'arthur.brown042@yahoo.com', '+19106446603', '1977-08-01', 'M', '9295 Main St', 'Fort Worth', 'TX', '80075', 'USA', '2023-01-09 14:06:07', 'Platinum', 9089.67, 864, 'Email', 1, 0),
    ('de7c7d3c-b14e-414b-8936-8721ea2cc9c3', 'Sharon', 'Thomas', 'sharon.thomas043@outlook.com', '+17580022012', '1973-12-10', 'F', '8073 Elm Dr', 'Fort Worth', 'TX', '85809', 'USA', '2024-01-17 14:06:07', 'Diamond', 6888.57, 4413, 'Email', 0, 1),
    ('fcdc176d-4022-456a-9531-200c794b26ee', 'Michelle', 'Moore', 'michelle.moore044@protonmail.com', '+19196539748', '2004-05-13', 'M', '5328 Oak Ave', 'San Francisco', 'CA', '87541', 'USA', '2023-03-25 14:06:07', 'Silver', 8027.24, 3545, 'SMS', 0, 0),
    ('c2cdc4e2-7df5-4811-82ca-868c921b9283', 'Steven', 'Edwards', 'steven.edwards045@live.com', '+13438760397', '1961-03-21', 'M', '6355 Main St', 'Portland', 'OR', '69977', 'USA', '2023-04-09 14:06:07', 'Gold', 6237.67, 6163, 'Email', 0, 1),
    ('3c3768ed-4b90-4ab2-bdce-bdef0b8dd0f6', 'Angela', 'Edwards', 'angela.edwards046@aol.com', '+16296599186', '1999-03-21', 'F', '5436 Main St', 'Memphis', 'TN', '12065', 'USA', '2024-01-30 14:06:07', 'Gold', 5025.59, 8234, 'Email', 1, 1),
    ('896d3219-a0be-4a1d-8b56-d742249e0416', 'Mark', 'Howard', 'mark.howard047@yahoo.com', '+18475275720', '2003-11-10', 'F', '5613 Pine Rd', 'Denver', 'CO', '63882', 'USA', '2024-04-14 14:06:07', 'Gold', 9855.63, 3404, 'Email', 1, 0),
    ('1c9b5b79-dad2-4102-8c81-b540f797f006', 'Barbara', 'Campbell', 'barbara.campbell048@aol.com', '+12630033551', '1998-04-11', 'F', '6108 Main St', 'Indianapolis', 'IN', '99532', 'USA', '2024-04-19 14:06:07', 'Diamond', 4269.83, 6214, 'SMS', 0, 0),
    ('6e5143d1-aa64-43ea-a463-0994528ead8f', 'Betty', 'Baker', 'betty.baker049@outlook.com', '+12524491429', '1992-12-08', 'M', '5234 Main St', 'Jacksonville', 'FL', '98137', 'USA', '2024-06-08 14:06:07', 'Silver', 3179.93, 2104, 'Phone', 0, 1),
    ('29db84c1-c5c3-47fd-b3ed-34e9335a07ab', 'Betty', 'Green', 'betty.green050@live.com', '+18911420742', '1970-06-15', 'M', '4236 Maple St', 'Washington', 'DC', '99844', 'USA', '2022-10-28 14:06:07', 'Bronze', 3330.68, 5399, 'Email', 1, 0),
    ('4046c124-3fb7-4a08-bd41-0dc8a64549b0', 'Harold', 'Jackson', 'harold.jackson051@hotmail.com', '+18513785421', '1992-11-29', 'M', '8802 Maple St', 'Nashville', 'TN', '23000', 'USA', '2024-11-21 14:06:07', 'Platinum', 1372.97, 4266, 'SMS', 0, 1),
    ('b64b0730-07b7-4fe4-8a7e-95ed6f8fefe5', 'James', 'Cook', 'james.cook052@icloud.com', '+19816843204', '1978-03-11', 'F', '6041 Pine Rd', 'Portland', 'OR', '20827', 'USA', '2023-12-05 14:06:07', 'Diamond', 5151.82, 8849, 'SMS', 1, 1),
    ('1f004a71-8b4f-4d5f-ab93-fbe563f7524b', 'Mark', 'Moore', 'mark.moore053@hotmail.com', '+13104738968', '1969-09-23', 'F', '6797 Elm Dr', 'New York', 'NY', '67126', 'USA', '2025-07-01 14:06:07', 'Gold', 5604.51, 5333, 'Email', 1, 0),
    ('34621c02-16b2-4122-bbac-427483d14946', 'Sarah', 'Cook', 'sarah.cook054@hotmail.com', '+15554243788', '1971-09-22', 'F', '2636 Elm Dr', 'Philadelphia', 'PA', '14096', 'USA', '2022-11-10 14:06:07', 'Gold', 8870.85, 2408, 'SMS', 1, 1),
    ('808053ef-b1a9-46b2-8205-9eb9e7838f74', 'Timothy', 'Mitchell', 'timothy.mitchell055@icloud.com', '+19826503732', '1983-03-18', 'F', '7963 Maple St', 'Boston', 'MA', '35016', 'USA', '2025-06-27 14:06:07', 'Diamond', 8988.51, 9967, 'SMS', 1, 1),
    ('6107b67f-ee81-4708-bb36-b367dca6db8a', 'Carol', 'Taylor', 'carol.taylor056@icloud.com', '+13306048244', '1991-05-19', 'M', '9701 Maple St', 'San Antonio', 'TX', '51717', 'USA', '2024-03-07 14:06:07', 'Platinum', 6235.54, 8933, 'Email', 1, 1),
    ('0aa3d9ab-2e4d-4de1-888c-748966ddd905', 'Sharon', 'Morris', 'sharon.morris057@protonmail.com', '+18833701541', '1972-03-07', 'F', '2413 Maple St', 'San Francisco', 'CA', '22303', 'USA', '2024-07-19 14:06:07', 'Platinum', 6714.29, 7862, 'Phone', 1, 1),
    ('0c9c1e85-a642-4523-8412-9de94d873b09', 'Mary', 'Campbell', 'mary.campbell058@aol.com', '+18623731827', '1980-03-14', 'F', '7458 Main St', 'New York', 'NY', '57783', 'USA', '2024-11-24 14:06:07', 'Diamond', 4122.19, 8692, 'SMS', 0, 1),
    ('a00270f9-1429-45b8-bdb4-c4faf86adcc1', 'Nancy', 'Cox', 'nancy.cox059@aol.com', '+15449429111', '2007-02-26', 'F', '565 Pine Rd', 'Philadelphia', 'PA', '94343', 'USA', '2024-03-08 14:06:07', 'Bronze', 3285.9, 3394, 'Email', 0, 1),
    ('f9700ea7-f195-463b-8290-444f3b08c3ff', 'Cynthia', 'Scott', 'cynthia.scott060@outlook.com', '+16021378542', '1979-09-07', 'F', '7473 Maple St', 'San Jose', 'CA', '23980', 'USA', '2024-08-19 14:06:07', 'Bronze', 6856.46, 101, 'SMS', 0, 0),
    ('34317c39-2524-43c3-b5f0-e60fbc142dd5', 'Sarah', 'Parker', 'sarah.parker061@aol.com', '+16450943591', '1965-02-23', 'M', '1543 Elm Dr', 'New York', 'NY', '16671', 'USA', '2025-02-25 14:06:07', 'Gold', 3331.68, 4893, 'SMS', 0, 0),
    ('6bd372f3-055e-4479-a6b7-686c1b8481f5', 'Olivia', 'Green', 'olivia.green062@yahoo.com', '+13786864509', '1990-02-13', 'M', '4837 Cedar Ln', 'San Diego', 'CA', '79135', 'USA', '2023-05-21 14:06:07', 'Diamond', 1160.4, 177, 'Phone', 1, 0),
    ('41063c6b-75be-431d-a51d-1f28198ea838', 'Michael', 'Johnson', 'michael.johnson063@protonmail.com', '+12614635120', '1998-04-23', 'M', '6642 Oak Ave', 'Columbus', 'OH', '96187', 'USA', '2024-03-22 14:06:07', 'Bronze', 1749.83, 9362, 'Phone', 0, 1),
    ('83b43ae6-f2c5-4be1-9ee2-ba03910c40aa', 'Olivia', 'Morris', 'olivia.morris064@aol.com', '+18282511856', '1964-04-21', 'M', '2255 Oak Ave', 'Phoenix', 'AZ', '35490', 'USA', '2024-02-02 14:06:07', 'Platinum', 5480.54, 200, 'SMS', 1, 1),
    ('9a561218-39ee-44b6-a3d2-2843604608c8', 'Olivia', 'Moore', 'olivia.moore065@icloud.com', '+13805523758', '2000-01-14', 'M', '8928 Maple St', 'Washington', 'DC', '35367', 'USA', '2025-06-26 14:06:07', 'Silver', 5784.83, 6672, 'Email', 0, 1),
    ('52a8df44-61bd-42a9-8f39-050ee4ef1af2', 'Jessica', 'Hall', 'jessica.hall066@hotmail.com', '+14856327477', '1997-04-18', 'M', '6775 Main St', 'Fort Worth', 'TX', '47652', 'USA', '2025-07-06 14:06:07', 'Gold', 6101.91, 6907, 'SMS', 1, 0),
    ('e94e4525-7fd6-4bdf-8139-5014b736cf48', 'Mary', 'Howard', 'mary.howard067@icloud.com', '+17823525284', '1970-09-28', 'F', '5762 Elm Dr', 'Portland', 'OR', '69872', 'USA', '2024-06-10 14:06:07', 'Gold', 6503.12, 509, 'Phone', 1, 1),
    ('b1138a2b-215b-4d2a-af85-a557b1a28818', 'Joyce', 'Walker', 'joyce.walker068@yahoo.com', '+15152835367', '1977-12-14', 'M', '8007 Maple St', 'Charlotte', 'NC', '94382', 'USA', '2022-08-07 14:06:07', 'Bronze', 2634.73, 8196, 'SMS', 1, 1),
    ('ef54aa43-c669-417d-9ba0-e19acfcce532', 'Ruth', 'Roberts', 'ruth.roberts069@icloud.com', '+19174281313', '2002-09-09', 'M', '5735 Oak Ave', 'Washington', 'DC', '17145', 'USA', '2023-05-11 14:06:07', 'Gold', 9724.77, 7596, 'SMS', 1, 1),
    ('a46b49f7-e12b-4b01-abae-8f76c6c4814e', 'Amanda', 'Stewart', 'amanda.stewart070@outlook.com', '+13135441068', '1987-11-28', 'F', '5375 Elm Dr', 'San Francisco', 'CA', '30788', 'USA', '2023-12-20 14:06:07', 'Bronze', 4580.99, 3903, 'Phone', 1, 1),
    ('592f8ee4-3bbb-4062-98ce-941f656574b1', 'Olivia', 'Rodriguez', 'olivia.rodriguez071@hotmail.com', '+18390130919', '1970-03-23', 'M', '6719 Pine Rd', 'Portland', 'OR', '48133', 'USA', '2025-03-14 14:06:07', 'Bronze', 2661.19, 1368, 'Phone', 1, 1),
    ('2bc548f0-f69c-4106-9ff4-d3b796fa3564', 'Joyce', 'Garcia', 'joyce.garcia072@yahoo.com', '+12798625064', '1970-09-24', 'M', '8179 Cedar Ln', 'Baltimore', 'MD', '62180', 'USA', '2024-01-08 14:06:07', 'Silver', 8994.71, 2304, 'Phone', 1, 0),
    ('de0ea5f2-6102-46b3-9306-dd928a7e2a39', 'Michael', 'Reed', 'michael.reed073@aol.com', '+13352635365', '1966-09-08', 'F', '9954 Pine Rd', 'Austin', 'TX', '87125', 'USA', '2025-07-02 14:06:07', 'Gold', 9839.19, 5296, 'SMS', 0, 0),
    ('d11bad83-30b2-44d3-b14a-b9417b498b58', 'Patricia', 'Lee', 'patricia.lee074@aol.com', '+15515439983', '1961-06-09', 'F', '2629 Main St', 'Indianapolis', 'IN', '44621', 'USA', '2022-10-08 14:06:07', 'Silver', 4222.28, 7993, 'Phone', 1, 1),
    ('becaa6dc-d7d4-44b4-85bd-f3fb6d731e49', 'Paul', 'Turner', 'paul.turner075@protonmail.com', '+16732208112', '1970-06-21', 'F', '6653 Pine Rd', 'Austin', 'TX', '75153', 'USA', '2022-09-14 14:06:07', 'Silver', 4764.46, 6911, 'Email', 0, 1),
    ('0a331a2d-4df5-4f4b-87e5-986c8b3dc08c', 'Barbara', 'White', 'barbara.white076@icloud.com', '+12923601146', '2001-07-28', 'M', '6822 Cedar Ln', 'Detroit', 'MI', '67690', 'USA', '2025-03-03 14:06:07', 'Gold', 4231.53, 6632, 'SMS', 0, 0),
    ('3157e914-4d67-4605-878d-61582f4e1425', 'Ruth', 'Scott', 'ruth.scott077@gmail.com', '+18016419034', '1983-06-20', 'F', '1001 Cedar Ln', 'Detroit', 'MI', '80914', 'USA', '2024-09-24 14:06:07', 'Platinum', 8751.13, 639, 'Email', 1, 1),
    ('c53da4d4-dff1-47a9-b774-613cacee47dd', 'William', 'Thomas', 'william.thomas078@protonmail.com', '+13046946934', '1976-04-25', 'M', '9993 Pine Rd', 'Jacksonville', 'FL', '60568', 'USA', '2022-09-22 14:06:07', 'Gold', 4386.47, 8320, 'Phone', 1, 0),
    ('e657f341-85e9-497d-b82d-d38e27fb4eb4', 'Paul', 'Collins', 'paul.collins079@live.com', '+19873907039', '1995-11-08', 'F', '6054 Maple St', 'Louisville', 'KY', '75981', 'USA', '2024-03-07 14:06:07', 'Platinum', 9957.37, 4709, 'SMS', 0, 1),
    ('6de64fe0-d4b3-4f9d-bf17-2c9afd064d7e', 'Steven', 'Mitchell', 'steven.mitchell080@yahoo.com', '+17869062294', '1986-03-07', 'F', '2794 Maple St', 'Dallas', 'TX', '22491', 'USA', '2024-10-11 14:06:07', 'Bronze', 1545.32, 4425, 'SMS', 0, 1),
    ('1ce7ddcf-d99e-4fa8-8608-64e149f1860a', 'John', 'Mitchell', 'john.mitchell081@live.com', '+16076253243', '1992-12-25', 'M', '6764 Maple St', 'Columbus', 'OH', '43040', 'USA', '2023-02-19 14:06:07', 'Silver', 5890.7, 1335, 'Email', 1, 1),
    ('4e301ae7-d8ea-4642-99cb-81a507bbe46f', 'Michael', 'Richardson', 'michael.richardson082@outlook.com', '+17336434445', '1961-05-07', 'M', '9216 Maple St', 'Seattle', 'WA', '99796', 'USA', '2024-12-12 14:06:07', 'Silver', 5184.13, 3540, 'Email', 1, 1),
    ('2791a330-0bce-40b7-a13d-e0cd29b14804', 'Emma', 'Rogers', 'emma.rogers083@aol.com', '+13303556702', '1970-10-02', 'M', '737 Cedar Ln', 'Columbus', 'OH', '18564', 'USA', '2022-08-19 14:06:07', 'Diamond', 2441.66, 8171, 'SMS', 0, 1),
    ('080399a0-3a1c-49e5-be65-d9d15336f1e1', 'Lisa', 'Cooper', 'lisa.cooper084@icloud.com', '+18412124739', '1963-12-31', 'M', '1251 Cedar Ln', 'Las Vegas', 'NV', '28098', 'USA', '2024-06-13 14:06:07', 'Platinum', 1184.22, 4636, 'Phone', 1, 1),
    ('4614ff15-21b2-476f-a96b-675438667b77', 'Henry', 'Phillips', 'henry.phillips085@hotmail.com', '+19972383290', '2006-10-15', 'F', '332 Main St', 'El Paso', 'TX', '74113', 'USA', '2023-06-27 14:06:07', 'Bronze', 6630.34, 5651, 'SMS', 1, 1),
    ('3d133600-f231-491f-8a20-29eeff213065', 'Helen', 'Roberts', 'helen.roberts086@aol.com', '+17140508776', '1973-08-01', 'F', '9425 Pine Rd', 'Indianapolis', 'IN', '67226', 'USA', '2023-01-19 14:06:07', 'Gold', 6353.69, 2658, 'SMS', 1, 1),
    ('df4ba397-208b-4066-b973-e6e69f779327', 'Angela', 'Lopez', 'angela.lopez087@aol.com', '+16326479924', '2000-01-17', 'F', '7771 Cedar Ln', 'Seattle', 'WA', '22517', 'USA', '2024-11-20 14:06:07', 'Diamond', 2799.92, 46, 'Email', 0, 1),
    ('d73e8ecf-70b6-43e6-a4b4-195b3d3c065b', 'Donna', 'Hall', 'donna.hall088@gmail.com', '+12371441331', '1992-02-24', 'F', '7806 Cedar Ln', 'Nashville', 'TN', '97700', 'USA', '2023-09-28 14:06:07', 'Silver', 3716.6, 5268, 'Phone', 0, 1),
    ('c860be39-5916-4fd1-970d-843bfb0ea8d3', 'Andrew', 'Parker', 'andrew.parker089@protonmail.com', '+18755373875', '1988-09-04', 'F', '1620 Pine Rd', 'Houston', 'TX', '18523', 'USA', '2023-03-01 14:06:07', 'Diamond', 6950.92, 2302, 'SMS', 1, 1),
    ('c408c543-f87b-40e0-b115-ae942f3c23df', 'Brian', 'Morris', 'brian.morris090@outlook.com', '+19309285380', '1976-12-11', 'F', '8336 Cedar Ln', 'Charlotte', 'NC', '27386', 'USA', '2023-03-20 14:06:07', 'Silver', 5463.49, 506, 'SMS', 0, 1),
    ('2b528c24-bfca-41ff-bc9d-10fd44116f46', 'Nancy', 'Roberts', 'nancy.roberts091@live.com', '+13319329159', '1971-06-07', 'M', '8369 Main St', 'Portland', 'OR', '69985', 'USA', '2025-03-19 14:06:07', 'Platinum', 8493.08, 1464, 'Phone', 1, 1),
    ('e4811ca3-19da-449b-bedd-a1936a67ab93', 'Arthur', 'Harris', 'arthur.harris092@live.com', '+17434433085', '2001-01-26', 'M', '9533 Cedar Ln', 'Columbus', 'OH', '21230', 'USA', '2024-06-04 14:06:07', 'Diamond', 9404.42, 7038, 'Email', 1, 1),
    ('08dd8470-39ad-47c1-bf8b-3cd1241f5855', 'Amanda', 'Lee', 'amanda.lee093@aol.com', '+17100516922', '1972-10-09', 'F', '1806 Cedar Ln', 'Boston', 'MA', '18842', 'USA', '2024-08-29 14:06:07', 'Gold', 5698.01, 8960, 'Email', 1, 1),
    ('d8968988-d23e-4c8b-b591-67ff55472271', 'Steven', 'Edwards', 'steven.edwards094@outlook.com', '+18269656515', '2002-01-03', 'F', '7867 Oak Ave', 'Los Angeles', 'CA', '85706', 'USA', '2024-05-15 14:06:07', 'Bronze', 6212.33, 568, 'Email', 0, 1),
    ('286c5761-f1b8-4e12-b653-49a684f48ba1', 'John', 'Baker', 'john.baker095@gmail.com', '+16093604992', '1970-02-28', 'M', '5288 Main St', 'San Jose', 'CA', '74867', 'USA', '2023-07-29 14:06:07', 'Bronze', 5986.29, 7937, 'SMS', 0, 0),
    ('1f63b9c3-3eac-4203-80d8-c561eb2d2f69', 'Anthony', 'Reed', 'anthony.reed096@live.com', '+19783324955', '1996-02-14', 'M', '2616 Pine Rd', 'Boston', 'MA', '25605', 'USA', '2023-12-05 14:06:07', 'Diamond', 7732.25, 6574, 'Phone', 1, 0),
    ('f70a8de2-d19f-4c7e-962f-98dfa222bea1', 'Harold', 'Adams', 'harold.adams097@live.com', '+19202399289', '1992-11-17', 'F', '8342 Pine Rd', 'Columbus', 'OH', '21504', 'USA', '2025-04-17 14:06:07', 'Gold', 4180.23, 99, 'Phone', 0, 0),
    ('3a33809a-a11a-42f2-9ae0-2156993504fd', 'Daniel', 'Hall', 'daniel.hall098@outlook.com', '+17029666272', '1990-11-06', 'M', '8425 Pine Rd', 'El Paso', 'TX', '35934', 'USA', '2024-08-10 14:06:07', 'Bronze', 9147.13, 9949, 'Phone', 1, 1),
    ('b9b5a50e-8469-4e5b-8492-95851c3a4e21', 'Daniel', 'Roberts', 'daniel.roberts099@gmail.com', '+12209569815', '1967-05-03', 'F', '2058 Maple St', 'Los Angeles', 'CA', '82325', 'USA', '2023-10-01 14:06:07', 'Diamond', 2376.56, 5428, 'Email', 1, 1),
    ('ab46c0a6-b7db-4a85-b957-e2e738e91025', 'Paul', 'Davis', 'paul.davis100@yahoo.com', '+13332615291', '2001-01-10', 'F', '9791 Elm Dr', 'Las Vegas', 'NV', '80715', 'USA', '2024-06-27 14:06:07', 'Platinum', 8293.56, 1092, 'Email', 1, 1);

GO

PRINT 'Successfully inserted 100 customer records';
GO

-- Create a view for customer summary
CREATE VIEW dbo.CustomerSummaryView AS
SELECT 
    customer_id,
    first_name + ' ' + last_name as full_name,
    email,
    city + ', ' + state_province as location,
    customer_tier,
    credit_limit,
    loyalty_points,
    registration_date,
    is_active
FROM dbo.Customer;
GO

SELECT * FROM CustomerSummaryView

PRINT 'Created CustomerSummaryView for easy customer data access';
GO

SELECT * FROM dbo.Customer;
GO
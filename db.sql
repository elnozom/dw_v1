DROP DATABASE NozResturant;

CREATE DATABASE NozResturant;
USE NozResturant;

CREATE TABLE AccCustomerSt
(
    CustomerSerial INT  IDENTITY(1,1) NOT NULL,
    CustomerName varchar(255) NOT NULL,
    CustomerPhone varchar(255) NOT NULL,
    CustomerEmail varchar(255),
    CustomerImage varchar(255),
    CreatedAt DATETIME DEFAULT GETDATE()
) ON [PRIMARY]


CREATE TABLE AccCustomerDim
(
    CustomerDimSerial INT  IDENTITY(1,1) NOT NULL,
    CustomerSerial INT NOT NULL,
    CustomerName varchar(255) NOT NULL,
    CustomerPhone varchar(255) NOT NULL,
    CustomerEmail varchar(255),
    CustomerImage varchar(255),
    CreatedAt DATETIME DEFAULT GETDATE(),
    StartEffectiveDate DATETIME DEFAULT GETDATE(),
    EndEffectiveDate DATETIME,
) ON [PRIMARY]

-- # seed staging table
INSERT INTO AccCustomerSt
    (
    CustomerName,
    CustomerPhone
    )
VALUES
    (
        'Ahmed',
        '01022052546'
    ),
    (
        'Moustafa',
        '01122052546'
    ),
    (
        'Delete me',
        '01122052545'
    );

GO
CREATE PROC MergeCustomerDim 
AS
BEGIN
    -- handle values inserted on the staging table but not on defined on dim table

    INSERT INTO AccCustomerDim (
        CustomerSerial,
        CustomerName,
        CustomerPhone,
        CustomerEmail,
        CustomerImage,
        CreatedAt
    ) SELECT 
        s.CustomerSerial,
        s.CustomerName,
        s.CustomerPhone,
        s.CustomerEmail,
        s.CustomerImage,
        s.CreatedAt 
    FROM AccCustomerSt s 
    LEFT JOIN AccCustomerDim d ON s.CustomerSerial = d.CustomerSerial WHERE d.CustomerSerial IS NULL

    -- handle values delete from the staging table but not deleted on dim table
    UPDATE AccCustomerDim  
    SET EndEffectiveDate = GETDATE() 
    FROM AccCustomerDim d LEFT 
    JOIN AccCustomerSt s 
        ON d.CustomerSerial = s.CustomerSerial 
    WHERE s.CustomerSerial IS NULL

    -- handle values update from the staging table


    -- create temp table of updated customers
    SELECT
        d.CustomerDimSerial, s.CustomerSerial ,s.CustomerName , s.CustomerPhone , s.CustomerEmail , s.CustomerImage , s.CreatedAt
    INTO #updated_customers
    FROM
        AccCustomerDim d JOIN AccCustomerSt s ON d.CustomerSerial = s.CustomerSerial WHERE CONCAT(s.CustomerName , s.CustomerPhone , s.CustomerEmail , s.CustomerImage) != CONCAT(d.CustomerName , d.CustomerPhone , d.CustomerEmail , d.CustomerImage)


    UPDATE AccCustomerDim  
    SET EndEffectiveDate = GETDATE()
    FROM AccCustomerDim d
    JOIN #updated_customers u 
        ON d.CustomerDimSerial = u.CustomerDimSerial

    
    INSERT INTO AccCustomerDim (
        CustomerSerial,
        CustomerName,
        CustomerPhone,
        CustomerEmail,
        CustomerImage,
        CreatedAt
    ) SELECT 
        u.CustomerSerial,
        u.CustomerName,
        u.CustomerPhone,
        u.CustomerEmail,
        u.CustomerImage,
        u.CreatedAt 
    FROM #updated_customers u
END
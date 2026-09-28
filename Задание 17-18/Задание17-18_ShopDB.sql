/* ============================================================
   ДОМАШНЯЯ РАБОТА — УРОКИ 17-18
   База: ShopDB
   Источник данных: AdventureWorks2022

   Требования:
   1) 6 таблиц сущностей, в каждой >= 7 столбцов
   2) пользовательские таблицы НЕ создаются в PRIMARY
   3) создаётся отдельная файловая группа FG_SHOP
   4) данные переносятся через INSERT ... SELECT
   5) используются существующие данные AdventureWorks2022

   Запускайте скрипт целиком в SSMS от пользователя с правами
   CREATE DATABASE / ALTER DATABASE и доступом к AdventureWorks2022.
   ============================================================ */

SET NOCOUNT ON;
GO

/* ------------------------------------------------------------
   1. Создаём ShopDB, если её ещё нет.
   ------------------------------------------------------------ */
IF DB_ID(N'ShopDB') IS NULL
BEGIN
    CREATE DATABASE ShopDB;
END;
GO

USE ShopDB;
GO

/* ------------------------------------------------------------
   2. Создаём отдельную файловую группу FG_SHOP.
   Таблицы задания будут размещены в ней, а не в PRIMARY.
   ------------------------------------------------------------ */
IF NOT EXISTS
(
    SELECT 1
    FROM sys.filegroups
    WHERE name = N'FG_SHOP'
)
BEGIN
    ALTER DATABASE ShopDB ADD FILEGROUP FG_SHOP;
END;
GO

/* Добавляем .ndf рядом с основным файлом ShopDB.
   Путь определяется автоматически. */
IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_files
    WHERE name = N'ShopDB_FG_SHOP'
)
BEGIN
    DECLARE @DataPath nvarchar(4000);
    DECLARE @FileName nvarchar(4000);
    DECLARE @sql nvarchar(max);

    SELECT @DataPath = LEFT(physical_name,
                            LEN(physical_name) - CHARINDEX(N'\', REVERSE(physical_name)) + 1)
    FROM sys.master_files
    WHERE database_id = DB_ID(N'ShopDB')
      AND type_desc = N'ROWS'
      AND data_space_id = 1;

    IF @DataPath IS NULL
        THROW 51000, N'Не удалось определить путь к файлам ShopDB.', 1;

    SET @FileName = @DataPath + N'ShopDB_FG_SHOP.ndf';

    SET @sql = N'
        ALTER DATABASE ShopDB ADD FILE
        (
            NAME = N''ShopDB_FG_SHOP'',
            FILENAME = N''' + REPLACE(@FileName, N'''', N'''''') + N''',
            SIZE = 100MB,
            FILEGROWTH = 50MB
        ) TO FILEGROUP FG_SHOP;';

    EXEC sys.sp_executesql @sql;
END;
GO

/* ------------------------------------------------------------
   3. Проверяем файловую группу и файл.
   ------------------------------------------------------------ */
SELECT
    fg.name AS FileGroupName,
    df.name AS FileName,
    df.physical_name AS PhysicalName
FROM sys.filegroups AS fg
LEFT JOIN sys.database_files AS df
    ON df.data_space_id = fg.data_space_id
WHERE fg.name = N'FG_SHOP';
GO

/* ------------------------------------------------------------
   4. Удаляем только таблицы этого задания при повторном запуске.
   ------------------------------------------------------------ */
DROP TABLE IF EXISTS dbo.ShopOrderItems;
DROP TABLE IF EXISTS dbo.ShopOrders;
DROP TABLE IF EXISTS dbo.ShopProducts;
DROP TABLE IF EXISTS dbo.ShopCustomers;
DROP TABLE IF EXISTS dbo.ShopSuppliers;
DROP TABLE IF EXISTS dbo.ShopOffers;
GO

/* ============================================================
   5. СОЗДАНИЕ 6 ТАБЛИЦ
   Все таблицы явно размещены ON FG_SHOP.
   В каждой таблице 7+ столбцов.
   ============================================================ */

CREATE TABLE dbo.ShopCustomers
(
    CustomerID INT NOT NULL PRIMARY KEY,
    PersonID INT NULL,
    StoreID INT NULL,
    TerritoryID INT NULL,
    AccountNumber VARCHAR(20) NOT NULL,
    CustomerRowGuid UNIQUEIDENTIFIER NOT NULL,
    ModifiedDate DATETIME NOT NULL
) ON FG_SHOP;
GO

CREATE TABLE dbo.ShopProducts
(
    ProductID INT NOT NULL PRIMARY KEY,
    ProductName NVARCHAR(50) NOT NULL,
    ProductNumber NVARCHAR(25) NOT NULL,
    MakeFlag BIT NOT NULL,
    FinishedGoodsFlag BIT NOT NULL,
    Color NVARCHAR(15) NULL,
    SafetyStockLevel SMALLINT NOT NULL,
    ReorderPoint SMALLINT NOT NULL,
    StandardCost MONEY NOT NULL,
    ListPrice MONEY NOT NULL,
    ModifiedDate DATETIME NOT NULL
) ON FG_SHOP;
GO

CREATE TABLE dbo.ShopSuppliers
(
    SupplierID INT NOT NULL PRIMARY KEY,
    AccountNumber NVARCHAR(15) NOT NULL,
    SupplierName NVARCHAR(50) NOT NULL,
    CreditRating TINYINT NOT NULL,
    PreferredVendorStatus BIT NOT NULL,
    ActiveFlag BIT NOT NULL,
    PurchasingWebServiceURL NVARCHAR(1024) NULL,
    ModifiedDate DATETIME NOT NULL
) ON FG_SHOP;
GO

CREATE TABLE dbo.ShopOffers
(
    SpecialOfferID INT NOT NULL PRIMARY KEY,
    Description NVARCHAR(255) NOT NULL,
    DiscountPct SMALLMONEY NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    MinQty INT NOT NULL,
    MaxQty INT NULL,
    ModifiedDate DATETIME NOT NULL
) ON FG_SHOP;
GO

CREATE TABLE dbo.ShopOrders
(
    SalesOrderID INT NOT NULL PRIMARY KEY,
    RevisionNumber TINYINT NOT NULL,
    OrderDate DATETIME NOT NULL,
    DueDate DATETIME NOT NULL,
    ShipDate DATETIME NULL,
    Status TINYINT NOT NULL,
    OnlineOrderFlag BIT NOT NULL,
    SalesOrderNumber NVARCHAR(25) NOT NULL,
    CustomerID INT NOT NULL,
    TerritoryID INT NULL,
    TotalDue MONEY NOT NULL,
    ModifiedDate DATETIME NOT NULL
) ON FG_SHOP;
GO

CREATE TABLE dbo.ShopOrderItems
(
    SalesOrderID INT NOT NULL,
    SalesOrderDetailID INT NOT NULL,
    OrderQty SMALLINT NOT NULL,
    ProductID INT NOT NULL,
    UnitPrice MONEY NOT NULL,
    UnitPriceDiscount MONEY NOT NULL,
    SpecialOfferID INT NOT NULL,
    CarrierTrackingNumber NVARCHAR(25) NULL,
    RowGuid UNIQUEIDENTIFIER NOT NULL,
    ModifiedDate DATETIME NOT NULL,
    CONSTRAINT PK_ShopOrderItems PRIMARY KEY (SalesOrderID, SalesOrderDetailID)
) ON FG_SHOP;
GO

/* ------------------------------------------------------------
   6. Проверяем наличие AdventureWorks2022.
   ------------------------------------------------------------ */
IF DB_ID(N'AdventureWorks2022') IS NULL
    THROW 51001, N'База AdventureWorks2022 не найдена на этом SQL Server.', 1;
GO

/* ------------------------------------------------------------
   7. Переносим данные через INSERT ... SELECT.
   Используются только поля, соответствующие сущностям ShopDB.
   ------------------------------------------------------------ */

INSERT INTO dbo.ShopCustomers
(
    CustomerID, PersonID, StoreID, TerritoryID, AccountNumber,
    CustomerRowGuid, ModifiedDate
)
SELECT
    CustomerID, PersonID, StoreID, TerritoryID, AccountNumber,
    rowguid, ModifiedDate
FROM AdventureWorks2022.Sales.Customer;
GO

INSERT INTO dbo.ShopProducts
(
    ProductID, ProductName, ProductNumber, MakeFlag, FinishedGoodsFlag,
    Color, SafetyStockLevel, ReorderPoint, StandardCost, ListPrice, ModifiedDate
)
SELECT
    ProductID, Name, ProductNumber, MakeFlag, FinishedGoodsFlag,
    Color, SafetyStockLevel, ReorderPoint, StandardCost, ListPrice, ModifiedDate
FROM AdventureWorks2022.Production.Product;
GO

INSERT INTO dbo.ShopSuppliers
(
    SupplierID, AccountNumber, SupplierName, CreditRating,
    PreferredVendorStatus, ActiveFlag, PurchasingWebServiceURL, ModifiedDate
)
SELECT
    BusinessEntityID, AccountNumber, Name, CreditRating,
    PreferredVendorStatus, ActiveFlag, PurchasingWebServiceURL, ModifiedDate
FROM AdventureWorks2022.Purchasing.Vendor;
GO

INSERT INTO dbo.ShopOffers
(
    SpecialOfferID, Description, DiscountPct, Type, Category,
    StartDate, EndDate, MinQty, MaxQty, ModifiedDate
)
SELECT
    SpecialOfferID, Description, DiscountPct, Type, Category,
    StartDate, EndDate, MinQty, MaxQty, ModifiedDate
FROM AdventureWorks2022.Sales.SpecialOffer;
GO

INSERT INTO dbo.ShopOrders
(
    SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate,
    Status, OnlineOrderFlag, SalesOrderNumber, CustomerID,
    TerritoryID, TotalDue, ModifiedDate
)
SELECT
    SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate,
    Status, OnlineOrderFlag, SalesOrderNumber, CustomerID,
    TerritoryID, TotalDue, ModifiedDate
FROM AdventureWorks2022.Sales.SalesOrderHeader;
GO

INSERT INTO dbo.ShopOrderItems
(
    SalesOrderID, SalesOrderDetailID, OrderQty, ProductID, UnitPrice,
    UnitPriceDiscount, SpecialOfferID, CarrierTrackingNumber,
    RowGuid, ModifiedDate
)
SELECT
    SalesOrderID, SalesOrderDetailID, OrderQty, ProductID, UnitPrice,
    UnitPriceDiscount, SpecialOfferID, CarrierTrackingNumber,
    rowguid, ModifiedDate
FROM AdventureWorks2022.Sales.SalesOrderDetail;
GO

/* ------------------------------------------------------------
   8. Проверка: 6 таблиц и количество столбцов.
   ------------------------------------------------------------ */
SELECT
    t.name AS TableName,
    COUNT(c.column_id) AS ColumnCount
FROM sys.tables AS t
INNER JOIN sys.columns AS c
    ON c.object_id = t.object_id
WHERE t.name IN
(
    N'ShopCustomers', N'ShopProducts', N'ShopSuppliers',
    N'ShopOffers', N'ShopOrders', N'ShopOrderItems'
)
GROUP BY t.name
ORDER BY t.name;
GO

/* ------------------------------------------------------------
   9. Проверка: все таблицы задания находятся в FG_SHOP,
      а не в PRIMARY.
   ------------------------------------------------------------ */
SELECT
    t.name AS TableName,
    ds.name AS FileGroupName
FROM sys.tables AS t
INNER JOIN sys.indexes AS i
    ON i.object_id = t.object_id
   AND i.index_id IN (0, 1)
INNER JOIN sys.data_spaces AS ds
    ON ds.data_space_id = i.data_space_id
WHERE t.name IN
(
    N'ShopCustomers', N'ShopProducts', N'ShopSuppliers',
    N'ShopOffers', N'ShopOrders', N'ShopOrderItems'
)
ORDER BY t.name;
GO

/* ------------------------------------------------------------
   10. Примеры перенесённых данных.
   ------------------------------------------------------------ */
SELECT TOP (10) * FROM dbo.ShopCustomers ORDER BY CustomerID;
SELECT TOP (10) * FROM dbo.ShopProducts ORDER BY ProductID;
SELECT TOP (10) * FROM dbo.ShopSuppliers ORDER BY SupplierID;
SELECT TOP (10) * FROM dbo.ShopOffers ORDER BY SpecialOfferID;
SELECT TOP (10) * FROM dbo.ShopOrders ORDER BY SalesOrderID;
SELECT TOP (10) * FROM dbo.ShopOrderItems ORDER BY SalesOrderID, SalesOrderDetailID;
GO

SET NOCOUNT OFF;
GO

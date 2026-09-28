/*
    ДОМАШНЯЯ РАБОТА — КЛАСТЕРНЫЕ ИНДЕКСЫ

    Проект: БД2
    Таблица: dbo.ClusterIndexTest
    В таблице 5 столбцов и 1 000 000 строк.

    Порядок выполнения:
    1. Запустить этот скрипт до блока "СОЗДАНИЕ КЛАСТЕРНОГО ИНДЕКСА".
    2. Для запроса SELECT включить "Включить фактический план выполнения"
       (Ctrl+M) в SSMS.
    3. Скопировать показатели STATISTICS IO из вкладки "Сообщения".
    4. Создать кластерный индекс.
    5. Повторить тот же SELECT и сравнить показатели.
*/

USE БД2;
GO

SET NOCOUNT ON;
GO

-- При повторном запуске удаляем старую таблицу.
IF OBJECT_ID(N'dbo.ClusterIndexTest', N'U') IS NOT NULL
    DROP TABLE dbo.ClusterIndexTest;
GO

-- 5 столбцов. IDENTITY нужен для автоматического заполнения ID.
-- Первичный ключ намеренно НЕ создаём, чтобы кластерный индекс
-- можно было создать отдельным запросом по заданию.
CREATE TABLE dbo.ClusterIndexTest
(
    ID INT IDENTITY(1,1) NOT NULL,
    ProductName NVARCHAR(50) NOT NULL,
    CategoryID INT NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    CreatedDate DATE NOT NULL
);
GO

-- 1 000 000 строк.
;WITH N AS
(
    SELECT TOP (1000000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
    FROM sys.all_objects AS A
    CROSS JOIN sys.all_objects AS B
)
INSERT INTO dbo.ClusterIndexTest
(
    ProductName,
    CategoryID,
    Price,
    CreatedDate
)
SELECT
    N'Product ' + CONVERT(NVARCHAR(20), Num),
    ((Num - 1) % 100) + 1,
    CONVERT(DECIMAL(10,2), ((Num * 37) % 100000) / 100.0),
    DATEADD(DAY, (Num - 1) % 3650, CONVERT(DATE, '2015-01-01'))
FROM N;
GO

-- Проверка количества строк.
SELECT COUNT(*) AS RowsCount
FROM dbo.ClusterIndexTest;
GO

/*
===========================================================
СОСТОЯНИЕ ДО КЛАСТЕРНОГО ИНДЕКСА
===========================================================
*/

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- ОДИН И ТОТ ЖЕ запрос используется до и после индекса.
SELECT
    ID,
    ProductName,
    CategoryID,
    Price,
    CreatedDate
FROM dbo.ClusterIndexTest
WHERE ID = 500000;
GO

SET STATISTICS TIME OFF;
GO

/*
    В SSMS откройте вкладку "Сообщения" и сохраните:
    - logical reads
    - physical reads
    - scan count
    - время выполнения.

    В "Плане выполнения" сохраните план этого SELECT.
*/


/*
===========================================================
СОЗДАНИЕ КЛАСТЕРНОГО ИНДЕКСА
===========================================================
*/

CREATE CLUSTERED INDEX IX_ClusterIndexTest_ID
ON dbo.ClusterIndexTest(ID);
GO


/*
===========================================================
СОСТОЯНИЕ ПОСЛЕ КЛАСТЕРНОГО ИНДЕКСА
===========================================================
*/

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- ТОЧНО ТА ЖЕ ВЫБОРКА.
SELECT
    ID,
    ProductName,
    CategoryID,
    Price,
    CreatedDate
FROM dbo.ClusterIndexTest
WHERE ID = 500000;
GO

SET STATISTICS TIME OFF;
GO

/*
    Снова сохраните:
    - logical reads
    - physical reads
    - scan count
    - время выполнения
    - фактический план выполнения.

    Сравните результаты до и после индекса.
*/


/*
===========================================================
ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА ИНДЕКСА
===========================================================
*/

SELECT
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName,
    ic.key_ordinal AS KeyOrdinal
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic
    ON i.object_id = ic.object_id
   AND i.index_id = ic.index_id
INNER JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.ClusterIndexTest')
ORDER BY i.index_id, ic.key_ordinal;
GO

SET STATISTICS IO OFF;
GO
SET NOCOUNT OFF;
GO

ЗАДАНИЕ 17-18 — ShopDB

Откройте файл «Задание17-18_ShopDB.sql» в SSMS и запустите целиком.

Что сделано:
- создаётся ShopDB, если её нет;
- создаётся отдельная файловая группа FG_SHOP и файл ShopDB_FG_SHOP.ndf;
- создаются 6 таблиц сущностей;
- в каждой таблице не менее 7 столбцов;
- таблицы размещаются ON FG_SHOP, а не в PRIMARY;
- данные переносятся из AdventureWorks2022 через INSERT ... SELECT;
- в конце есть проверки количества столбцов и файловой группы.

Источник данных:
AdventureWorks2022.Sales.Customer
AdventureWorks2022.Production.Product
AdventureWorks2022.Purchasing.Vendor
AdventureWorks2022.Sales.SpecialOffer
AdventureWorks2022.Sales.SalesOrderHeader
AdventureWorks2022.Sales.SalesOrderDetail

Если ShopDB уже существует, скрипт не удаляет чужие таблицы. При повторном запуске удаляются и заново создаются только таблицы Shop* из этого задания.

Для создания файловой группы нужны права ALTER DATABASE. AdventureWorks2022 должна быть установлена на том же экземпляре SQL Server.

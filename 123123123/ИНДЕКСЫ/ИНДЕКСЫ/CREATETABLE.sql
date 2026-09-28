USE БД1
go

CREATE PROCEDURE p_CreateOrdesNotSale2
	@Param1 varchar(20),
	@Param2 int,
	@Param3 float,
AS
INTO orders123 (number_order123, price, quantity)
VALUES (@Param1, @Param2, @Param3)

EXECUTE p_CreateOrdesNotSale3



SELECT *
FROM orders123


DROP TABLE orders123
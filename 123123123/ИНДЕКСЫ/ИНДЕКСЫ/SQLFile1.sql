USE БД1	
go	
CREATE TABLE orders(
	id uniqueidentifier,
	product_id uniqueidentifier,
	customer_id uniqueidentifier,
	price money
)
go 
INSERT INTO orders
VALUES (
	NewId(), NewId(), NewId(),	
	DATEPART(MILLISECOND, GETDATE())	
)
go 1000
USE БД1
go 

CREATE TABLE orders123(
	id int PRIMARY KEY IDENTITY(1,1),
	number_order123 varchar(20),
	price money,
	quantity int,
	sale float ,
	sum_price AS ((price * quantity) * sale),
	date_created datetime DEFAULT GetDate(),
	date_finish AS (date_created + Day(10)) 
)



INSERT INTO orders123 (number_order123, price, quantity)
VALUES ('ABC121212', 100, 2, 1),
('ABD121212', 150, 5, 0.4),
('ABI121212', 120, 6, 0.5)

INSERT INTO orders123 (number_order123, price, quantity, sale)
VALUES ('ABC121212', 100, 2, 1),
('ABD121212', 150, 1, 0.4),
('ABI121212', 120, 2, 0.5)


SELECT *
FROM orders123


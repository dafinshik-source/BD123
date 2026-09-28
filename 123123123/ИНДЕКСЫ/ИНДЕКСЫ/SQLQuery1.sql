USE БД1 
go

CREATE CLUSTERED INDEX pk_orders_1
	ON orders(id)
		-- = PK	

CREATE NONCLUSTERED INDEX fk_orders_2
	ON orders(id)

CREATE INDEX fk_orders_3
	ON orders(product_id, customer_id)

CREATE INDEX fk_orders_4
	ON orders(price)
	WHERE price <= 700.00

DROP INDEX fk_orders_5
ON orders

CREATE COLUMNSTORE INDEX fk_orders_5
	ON orders(price)
	WHERE price <= 800.00
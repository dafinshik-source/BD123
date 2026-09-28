USE БД1
GO 

--CREATE TABLE users(
--id int PRIMARY KEY IDENTITY(1,1)
--)

CREATE TABLE customers(
	id int PRIMARY KEY IDENTITY (1,1),	
	first_name varchar(50),
	orders_id int,

	CONSTRAINT fk_1
	FOREIGN KEY (orders_id) 
	REFERENCES users(id)
)
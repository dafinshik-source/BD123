SET STATISTICS IO ON

USE БД1

go

SELECT id, product_id, customer_id	
FROM orders			
WHERE price <= 700.00
--AND customer_id = 'CA11CEF6-5E3F-4CBC-82BC-159755D96FD3'

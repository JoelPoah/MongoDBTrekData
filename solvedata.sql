use BikeSalesMinions


-- Zero Stock got huge issues
-- This finds 8 product not found in Stock table
select p.product_id,p.product_name,b.brand_name,c.category_name,p.model_year,p.list_price from production.products as p
,Production.brands as b , Production.categories as c 
WHERE p.product_id not in (select product_id from Production.stocks) and b.brand_id = p.brand_id 
and c.category_id=p.category_id and p.product_id not in (select product_id from
Production.stocks group by product_id having SUM(Quantity) = 0)



/** SOLVING ABOVE **/
-- Finding in Stock got issues
select distinct p.product_id ,s.store_id,s.quantity from production.products as p
inner join Production.stocks as s on s.product_id = p.product_id
WHERE p.product_id in (s.product_id) and s.quantity > 0


-- Prove of problem
select * from Production.products as p ,Production.stocks as s
where p.product_id ='RDB59' and p.product_id=s.product_id
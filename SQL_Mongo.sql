
use BikeSalesMinions
/* Get table data in JSON format */

-- Get Unsold 43

select distinct p.product_id,p.product_name,b.brand_name,c.category_name,p.model_year,p.list_price
from Production.products as p ,production.brands as b , Production.categories as c 
where p.product_id not in (select s.product_id from Sales.order_items as s
inner join sales.orders o on o.order_id = s.order_id 
where o.order_status=4) and p.brand_id = b.brand_id and p.product_id not in (select s.product_id from Sales.order_items as s)
and p.category_id = c.category_id
        FOR JSON PATH, 
        INCLUDE_NULL_VALUES
GO



-- Zero Stock 8
use BikeSalesMinions
select p.product_id,p.product_name,b.brand_name,c.category_name,p.model_year,p.list_price from production.products as p
,Production.brands as b , Production.categories as c 
WHERE p.product_id not in (select product_id from Production.stocks) and b.brand_id = p.brand_id 
and c.category_id=p.category_id and p.product_id not in (select product_id from
Production.stocks group by product_id having SUM(Quantity) = 0)
		FOR JSON PATH, 
        INCLUDE_NULL_VALUES

GO
-- Finding in Stock 939
select distinct p.product_id ,s.store_id,s.quantity from production.products as p
inner join Production.stocks as s on s.product_id = p.product_id
WHERE p.product_id in (select product_id from
Production.stocks group by product_id having SUM(Quantity) > 0)
        FOR JSON PATH, 
        INCLUDE_NULL_VALUES



ss
/** MONGO CODE **/
If want to drop database
> use Bikes; 
> db.dropDatabase();
|| Drop collections
db.UnSold.drop()

use Bikes

show dbs 

show collections

db.UnSold.insertMany()

// make sure mongoImport is downloaded from mongotools unzipped and saved before running

cd C:\Program Files\MongoDB\Server\5.0\bin

mongoimport --db Bikes --collection ZeroStock --file C:\JSONDATA\ZeroStock.json --jsonArray

mongoimport --db Bikes --collection Stock --file C:\JSONDATA\Stock.json --jsonArray

language : MongoDB
find count of documents in each collection

db.UnSold.count() --14 
db.ZeroStock.count() --8
db.Stock.count() --939


Query 1:
find bike names from ZeroStock where list_price is less than $2000 and have category_name = "Road Bikes" :
db.ZeroStock.find( { list_price: { $lt: 2000 }, category_name: "Road Bikes"},{_id:0,product_name:1,list_price:1})
-- 3 count

Query 2: 
language : MongoDB
find unduplicated category_name,and brand_name from collection Unsold separately using addtoset
db.UnSold.aggregate([
        {$group:{
                _id:"category and brand", "category": {$addToSet :"$category_name"},
                          "brand_name":{$addToSet :"$brand_name"}
                }
        }
        ]).pretty()


db.UnSold.distinct("category_name") --4
db.UnSold.distinct("brand_name") -- 3


Query 3: 
language : MongoDB

use look up to join ZeroStock and UnSold and find distinct category_name and brand_name

-- 6 
db.UnSold.aggregate([{$lookup: {from: "ZeroStock", localField: "category_name", 
foreignField: "category_name", as: "UnSold"}},
{$group: {_id: {category_name: "$category_name", brand_name: "$brand_name"}}}])



^ this produces 6 rows of results,4 more sets as compared to left join ZeroStock.I Suppose its 
because UnSold has more rows and should be the left join here.  

/**
the commented code shows a left join ZeroStock
db.ZeroStock.aggregate(
        [
                {$lookup:
                         {from: "UnSold", localField: "category_name", 
                         foreignField: "category_name", as: "UnSold"}
                },
                {$group: 
                        {
                                _id: 
                                        {category_name: "$category_name", brand_name: "$brand_name"}
                        }
                }
        ]
                      )
**/


Query 4:
language : MongoDB
use lookup to join unsold and stock collections
--24 count 
db.UnSold.aggregate([
    { $lookup: { from: "Stock", localField: "product_id", foreignField: "product_id", as: "stock" } },
    { $match: { "stock.quantity": { $gt: 0 } } },
    { $unwind:'$stock'},
    { $project: { _id:0,product_id: 1, product_name: 1, brand_name: 1, category_name: 1, model_year: 1, list_price: 1, "stock.store_id":1,"stock.quantity": 1} }
]).pretty()

/** I assume this query is to get those products that are really not doing well**/

Query 5:
-- 23 count
language : MongoDB
use lookup to join unsold and stock collections and sum stock.quantity
db.UnSold.aggregate([
    { $lookup: { from: "Stock", localField: "product_id", foreignField: "product_id", as: "stock" } },
    { $match: { "stock.quantity": { $gt: 0 } } },
    { $unwind:'$stock'},
    { $group: { _id: { product_id: "$product_id", product_name: "$product_name", brand_name: "$brand_name", category_name: "$category_name", model_year: "$model_year", list_price: "$list_price" , TotalQty: { $sum: "$stock.quantity" }} } },
    { $sort: { TotalQty: -1 } }
]).pretty()


Query 6:
language : MongoDB
--count 2
Find all products that are in ZeroStock but not in UnSold collections.
db.ZeroStock.aggregate([
    { $lookup: { from: "UnSold", localField: "product_id", foreignField: "product_id", as: "UnSold" } },
    { $match: { "UnSold.product_id": { $exists: false } } },
    { $project: { _id:0,product_id: 1, product_name: 1, brand_name: 1, category_name: 1, model_year: 1, list_price: 1 } }
]).pretty()



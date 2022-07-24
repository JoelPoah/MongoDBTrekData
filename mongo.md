
/* Get table data in JSON format in mssql */
```sql
-- Get Unsold
select p.product_id,p.product_name,b.brand_name,c.category_name,p.model_year,p.list_price from Production.products as p ,production.brands as b , Production.categories as c 
where p.product_id not in (select s.product_id from Sales.order_items as s) and p.brand_id = b.brand_id
and p.category_id = c.category_id
        FOR JSON PATH, 
        INCLUDE_NULL_VALUES
GO
```

```sql
-- Zero Stock table
select p.product_id,p.product_name,b.brand_name,c.category_name,p.model_ar,p.list_price from production.products as p
,Production.brands as b , Production.categories as c 
WHERE p.product_id not in (select product_id from Production.stocks) and b.brand_id = p.brand_id 
and c.category_id=p.category_id and p.product_id not in (select product_id from
Production.stocks group by product_id having SUM(Quantity) = 0)
		FOR JSON PATH, 
        INCLUDE_NULL_VALUES
```
```sql
GO
-- Finding in Stock got issues
select distinct p.product_id ,s.store_id,s.quantity from production.products as p
inner join Production.stocks as s on s.product_id = p.product_id
WHERE p.product_id in (select product_id from Production.stocks) and p.product_id in (select product_id from
Production.stocks group by product_id having SUM(Quantity) > 0)
        FOR JSON PATH, 
        INCLUDE_NULL_VALUES
```



/** MONGO CODE **/
If want to drop database
```sql
> use Bikes; 
> db.dropDatabase();
|| Drop collections
```
```sql
db.UnSold.drop()
```
```sql
use Bikes

show dbs 

show collections
```
copy UnSold json data from sql and paste into () Below
```sql
db.UnSold.insertMany()
```

// Download MongoDB Database tools zip file from link below. 
<a>https://www.mongodb.com/try/download/database-tools</a>
//Extract all from bin folder and paste into where u stored Mongo.exe

cd C:\Program Files\MongoDB\Server\5.0\bin 

mongoimport --db Bikes --collection ZeroStock --file C:\JSONDATA\ZeroStock.json --jsonArray

mongoimport --db Bikes --collection Stock --file C:\JSONDATA\Stock.json --jsonArray

language : MongoDB
find count of documents in each collection

db.UnSold.count() --14 
db.ZeroStock.count() --8
db.Stock.count() --939


Query 1:
```sql
find bike names from ZeroStock where list_price is less than $2000 and have category_name = "Road Bikes" :
db.ZeroStock.find( { list_price: { $lt: 2000 }, category_name: "Road Bikes"},{_id:0,product_name:1,list_price:1} )
```
Query 2: 
language : MongoDB
```sql
find unduplicated category_name from collection Unsold
db.UnSold.distinct("category_name")
db.UnSold.distinct("brand_name")
```

Query 3: 
language : MongoDB

use look up to join ZeroStock and UnSold and find distinct category_name and brand_name
```sql
db.UnSold.aggregate([{$lookup: {from: "ZeroStock", localField: "category_name", 
foreignField: "category_name", as: "UnSold"}},
{$group: {_id: {category_name: "$category_name", brand_name: "$brand_name"}}}])
```
^ this produces 6 rows of results,4 more sets as compared to left join ZeroStock.I Suppose its 
because UnSold has more rows and should be the left join here.  

```sql
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
```


Query 4:
language : MongoDB
use lookup to join unsold and stock collections
```sql
db.UnSold.aggregate([
    { $lookup: { from: "Stock", localField: "product_id", foreignField: "product_id", as: "stock" } },
    { $match: { "stock.quantity": { $gt: 0 } } },
    { $unwind:'$stock'},
    { $project: { _id:0,product_id: 1, product_name: 1, brand_name: 1, category_name: 1, model_year: 1, list_price: 1, "stock.store_id":1,"stock.quantity": 1} }
]).pretty()

/** I assume this query is to get those products that are really not doing well**/
```
Query 5:

language : MongoDB
use lookup to join unsold and stock collections and sum stock.quantity
```sql
db.UnSold.aggregate([
    { $lookup: { from: "Stock", localField: "product_id", foreignField: "product_id", as: "stock" } },
    { $match: { "stock.quantity": { $gt: 0 } } },
    { $unwind:'$stock'},
    { $group: { _id: { product_id: "$product_id", product_name: "$product_name", brand_name: "$brand_name", category_name: "$category_name", model_year: "$model_year", list_price: "$list_price" , TotalQty: { $sum: "$stock.quantity" }} } },
    { $sort: { TotalQty: -1 } }
]).pretty()
```

Query 6:
language : MongoDB
Find all products that are in ZeroStock but not in UnSold collections.
```sql
db.ZeroStock.aggregate([
    { $lookup: { from: "UnSold", localField: "product_id", foreignField: "product_id", as: "UnSold" } },
    { $match: { "UnSold.product_id": { $exists: false } } },
    { $project: { _id:0,product_id: 1, product_name: 1, brand_name: 1, category_name: 1, model_year: 1, list_price: 1 } }
]).pretty()
```


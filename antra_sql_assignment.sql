--List of Persons’ full name, all their fax and phone numbers, 
--as well as the phone number and fax of the company they are working for (if any). 
SELECT 
	ap.FullName, ap.PhoneNumber, ap.FaxNumber, 
	SUBSTRING(
		ap.EmailAddress,
		CHARINDEX('@',ap.EmailAddress)+1, 
		LEN(ap.EmailAddress)-4-CHARINDEX('@',ap.EmailAddress)
		) AS Company
FROM Application.People ap

--If the customer's primary contact person has the same phone number as the customer’s phone number, list the customer companies. 
SELECT DISTINCT 
	SUBSTRING(
		ap.EmailAddress,
		CHARINDEX('@',ap.EmailAddress)+1, 
		LEN(ap.EmailAddress)-4-CHARINDEX('@',ap.EmailAddress)
		) AS Company
FROM Sales.Customers sc
INNER JOIN Application.People ap ON ap.PersonID = sc.PrimaryContactPersonID
WHERE sc.PhoneNumber= ap.PhoneNumber

--List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.
SELECT DISTINCT so.CustomerID
	FROM Sales.Orders so
	WHERE so.OrderDate <'2016-01-01' 
		AND 
		so.CustomerID NOT IN (
	SELECT DISTINCT so.CustomerID
	FROM Sales.Orders so
	WHERE so.OrderDate >='2016-01-01'
);

--List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.
SELECT 
	ws.StockItemName, SUM(sol.Quantity) AS 'total_quant'
FROM Sales.OrderLines sol
INNER JOIN Sales.Orders so ON so.OrderID = sol.OrderID
INNER JOIN Warehouse.StockItems ws ON ws.StockItemID = sol.StockItemID
WHERE LEFT(so.OrderDate, 4) = '2013'
GROUP BY ws.StockItemName
ORDER BY 2 DESC;

--List of stock items that have at least 10 characters in description.
SELECT 
	ws.StockItemName
FROM Sales.OrderLines sol
JOIN Warehouse.StockItems ws ON ws.StockItemID = sol.StockItemID
WHERE LEN(sol.Description)>=10
GROUP BY ws.StockItemName;

--List of stock items that are not sold to the state of Alabama and Georgia in 2014.
WITH loc_req AS (
	SELECT 
		aco.CountryID, aco.CountryName, asp.StateProvinceID, asp.StateProvinceName, asp.StateProvinceCode
	FROM Application.Countries aco
	INNER JOIN Application.StateProvinces asp ON 
		asp.CountryID = aco.CountryID and aco.CountryName = 'United States' 
	WHERE asp.StateProvinceName = 'Alabama' or asp.StateProvinceName = 'Georgia'
) 
SELECT 
	DISTINCT wsi.StockItemName
FROM Sales.OrderLines sol
INNER JOIN Sales.Orders so ON sol.OrderID = so.OrderID
INNER JOIN Warehouse.StockItems wsi ON wsi.StockItemID = sol.StockItemID
INNER JOIN Sales.Customers sc ON sc.CustomerID = so.CustomerID
INNER JOIN Application.Cities aci ON aci.CityID = sc.PostalCityID
WHERE LEFT(so.OrderDate, 4) = '2014' AND aci.StateProvinceID NOT IN (
	SELECT StateProvinceID 
	FROM loc_req
);

--List of States and Avg dates for processing (confirmed delivery date – order date).
SELECT 
	asp.StateProvinceName,AVG(DATEDIFF(DAY,so.OrderDate,si.ConfirmedDeliveryTime)) AS avg_diff_day
FROM Sales.Orders so 
INNER JOIN Sales.Invoices si ON so.OrderID = si.OrderID
INNER JOIN Sales.Customers sc on sc.CustomerID = so.CustomerID
INNER JOIN Application.Cities ac ON ac.CityID = sc.DeliveryCityID
INNER JOIN Application.StateProvinces asp ON asp.StateProvinceID = ac.StateProvinceID
GROUP BY asp.StateProvinceName 
ORDER BY 2 DESC;

--List of States and Avg dates for processing (confirmed delivery date – order date) by month.
SELECT 
	asp.StateProvinceName,MONTH(so.OrderDate) as order_month,
	AVG(DATEDIFF(DAY,so.OrderDate,si.ConfirmedDeliveryTime)) AS avg_diff_day
FROM Sales.Orders so 
INNER JOIN Sales.Invoices si ON so.OrderID = si.OrderID
INNER JOIN Sales.Customers sc on sc.CustomerID = so.CustomerID
INNER JOIN Application.Cities ac ON ac.CityID = sc.DeliveryCityID
INNER JOIN Application.StateProvinces asp ON asp.StateProvinceID = ac.StateProvinceID
GROUP BY asp.StateProvinceName, MONTH(so.OrderDate)
ORDER BY 1,2 DESC;

--List of StockItems that the company purchased more than sold in the year of 2015.
WITH cte1 AS (
	SELECT 
		pol.StockItemID, COUNT(pol.StockItemID) purchased_cnt
	FROM Purchasing.PurchaseOrderLines pol
	GROUP BY pol.StockItemID
), cte2 AS (
	SELECT 
		sol.StockItemID, COUNT(SOL.StockItemID) sold_cnt
	FROM Sales.OrderLines sol
	GROUP BY sol.StockItemID
) 
SELECT c1.purchased_cnt
FROM cte1 c1
FULL JOIN cte2 c2 ON c2.StockItemID = c1.StockItemID
where c1.purchased_cnt > c2.sold_cnt;

--List of Customers and their phone number, together with the primary contact person’s name, 
--to whom we did not sell more than 10  mugs (search by name) in the year 2016.
SELECT sc.CustomerID, sc.CustomerName, sc.PhoneNumber, ap.FullName
FROM Sales.OrderLines sol
INNER JOIN Sales.Orders so ON so.OrderID = sol.OrderID
INNER JOIN Sales.Customers sc ON sc.CustomerID = so.CustomerID
INNER JOIN Application.People ap ON ap.PersonID = sc.PrimaryContactPersonID
INNER JOIN Warehouse.StockItemStockGroups wsisg ON wsisg.StockItemID = sol.StockItemID
INNER JOIN Warehouse.StockGroups wsg ON wsg.StockGroupID = wsisg.StockGroupID
WHERE wsg.StockGroupName = 'Mugs' AND LEFT(SO.OrderDate, 4) = '2016'
GROUP BY sc.CustomerID, sc.CustomerName, sc.PhoneNumber, ap.FullName
HAVING COUNT(sc.CustomerID) <10

--List all the cities that were updated after 2015-01-01.
SELECT ac.CityName
FROM Application.Cities ac
WHERE ac.ValidFrom >'2015-01-01';

--List all the Order Detail (Stock Item name, delivery address, delivery state, city, 
--country, customer name, customer contact person name, customer phone, quantity) for the date of 2014-07-01. 
--Info should be relevant to that date.
SELECT 
	DISTINCT wsi.StockItemName,sc.DeliveryAddressLine2 AS 'Delivery_Address',
	ac.CityName, asp.StateProvinceName AS 'State', aco.CountryName AS 'Country',
	sc.CustomerName, ap.FullName AS 'Customer_Contact_Person_Name', 
	sc.PhoneNumber AS 'Customer_Phone', sol.Quantity
FROM Sales.OrderLines sol
INNER JOIN Sales.Orders so ON sol.OrderID = so.OrderID
INNER JOIN Sales.Customers sc ON sc.CustomerID = so.CustomerID
INNER JOIN Application.Cities ac ON ac.CityID = sc.PostalCityID
INNER JOIN Application.StateProvinces asp ON asp.StateProvinceID = ac.StateProvinceID
INNER JOIN Application.Countries aco ON aco.CountryID = asp.CountryID
INNER JOIN Application.People ap ON ap.PersonID = so.ContactPersonID
INNER JOIN Warehouse.StockItems wsi ON wsi.StockItemID = sol.StockItemID
WHERE so.OrderDate = '2014-07-01'

--List of stock item groups and total quantity purchased, total quantity sold, 
--and the remaining stock quantity (quantity purchased – quantity sold)
WITH purchase AS (
	SELECT 
		wsg.StockGroupName, SUM(ppo.ReceivedOuters) 'total_quantity_purchased'
	FROM Purchasing.PurchaseOrderLines ppo 
	INNER JOIN Warehouse.StockItemStockGroups wsisg ON wsisg.StockItemID = ppo.StockItemID
	INNER JOIN Warehouse.StockGroups wsg ON wsg.StockGroupID = wsisg.StockGroupID
	GROUP BY wsg.StockGroupName
), sales AS (
	SELECT 
		wsg.StockGroupName, SUM(sol.Quantity) 'total_quantity_sold'
	FROM Sales.OrderLines sol
	INNER JOIN Warehouse.StockItemStockGroups wsisg ON wsisg.StockItemID = sol.StockItemID
	INNER JOIN Warehouse.StockGroups wsg ON wsg.StockGroupID = wsisg.StockGroupID
	GROUP BY wsg.StockGroupName
)
SELECT 
	p.StockGroupName, p.total_quantity_purchased, s.total_quantity_sold,
	p.total_quantity_purchased-s.total_quantity_sold 'remaining'
FROM purchase p
INNER JOIN sales s ON s.StockGroupName = p.StockGroupName

--List of Cities in the US and the stock item that the city got the most deliveries in 2016. 
--If the city did not purchase any stock items in 2016, print “No Sales”.
WITH American_All_Cities AS (
	SELECT 
		DISTINCT aCities.CityName
	FROM Application.Countries aCountry
	INNER JOIN Application.StateProvinces asp ON 
		asp.CountryID = aCountry.CountryID 
		and 
		aCountry.CountryName = 'United States'
	INNER JOIN Application.Cities aCities ON aCities.StateProvinceID = asp.StateProvinceID
), Cities_Purchased AS (
	SELECT aCities.CityName, COUNT(aCities.CityName) total
	FROM Sales.Orders so
	INNER JOIN Sales.Customers sc ON sc.CustomerID = so.CustomerID
	INNER JOIN Application.Cities aCities ON aCities.CityID = sc.DeliveryCityID
	INNER JOIN Application.StateProvinces asp ON asp.StateProvinceID = aCities.StateProvinceID 
	INNER JOIN Application.Countries aCountry ON 
		aCountry.CountryID = asp.CountryID
		and 
		aCountry.CountryName = 'United States'
	WHERE LEFT(so.OrderDate, 4) = '2016'
	GROUP BY aCities.CityName
), Res AS (
	Select DISTINCT aac.CityName, 'No Sales' AS total
	From Cities_Purchased  cp
	RIGHT OUTER JOIN American_All_Cities aac ON aac.CityName = cp.CityName
	WHERE cp.total IS NULL
	UNION 
	SELECT TOP 1 CityName, str(total) AS total
	FROM Cities_Purchased
	ORDER BY total DESC
)
SELECT CityName, total FROM Res;

--List any orders that had more than one delivery attempt (located in invoice table).
SELECT si.OrderID 
FROM Sales.Invoices si
WHERE JSON_VALUE(si.ReturnedDeliveryData, '$.Events[1].Comment') = 'Receiver not present'

--List all stock items that are manufactured in China. (Country of Manufacture)
SELECT 
	ws.StockItemName
FROM Warehouse.StockItems ws
WHERE JSON_VALUE(ws.CustomFields, '$.CountryOfManufacture') = 'China';

--Total quantity of stock items sold in 2015, group by country of manufacturing.
SELECT 
	JSON_VALUE(wsi.CustomFields, '$.CountryOfManufacture') CountryOfManufacture, 
	SUM(sol.Quantity) total
FROM Sales.OrderLines sol
INNER JOIN Sales.Orders so ON sol.OrderID = so.OrderID AND LEFT(so.OrderDate, 4) = '2015'
INNER JOIN Warehouse.StockItems wsi ON wsi.StockItemID = sol.StockItemID
GROUP BY JSON_VALUE(wsi.CustomFields, '$.CountryOfManufacture');

--Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. 
--[Stock Group Name, 2013, 2014, 2015, 2016, 2017]
CREATE VIEW StockGroupName_Pivot AS (
	SELECT 
		StockGroupName, [2013],[2014],[2015], [2016]
	FROM (
		SELECT wsg.StockGroupName, CAST(YEAR(so.OrderDate) AS CHAR(4)) AS Order_Year, sol.Quantity AS Quantity
		FROM Sales.Orders so
		INNER JOIN Sales.OrderLines sol ON sol.OrderID = so.OrderID
		INNER JOIN Warehouse.StockItems wsi ON wsi.StockItemID = sol.StockItemID
		INNER JOIN Warehouse.StockItemStockGroups wsisg ON wsisg.StockItemID = wsi.StockItemID
		INNER JOIN Warehouse.StockGroups wsg ON wsg.StockGroupID = wsisg.StockGroupID
		WHERE LEFT(so.OrderDate, 4) BETWEEN '2013' AND '2017'
	) t1
	PIVOT (
		SUM(Quantity) FOR Order_Year IN ([2013],[2014],[2015], [2016])
	) AS pvt
)
SELECT *
FROM StockGroupName_Pivot;

--Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. 
--[Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, … , Stock Group Name10] 
CREATE VIEW Year_Pivot AS (
	SELECT 
		Order_Year, [T-Shirts] ,[USB Novelties],
		[Packaging Materials], [Clothing],
		[Novelty Items], [Furry Footwear],
		[Mugs], [Computing Novelties], [Toys]
	FROM (
		SELECT wsg.StockGroupName, CAST(YEAR(so.OrderDate) AS CHAR(4)) AS Order_Year, sol.Quantity AS Quantity
		FROM Sales.Orders so
		INNER JOIN Sales.OrderLines sol ON sol.OrderID = so.OrderID
		INNER JOIN Warehouse.StockItems wsi ON wsi.StockItemID = sol.StockItemID
		INNER JOIN Warehouse.StockItemStockGroups wsisg ON wsisg.StockItemID = wsi.StockItemID
		INNER JOIN Warehouse.StockGroups wsg ON wsg.StockGroupID = wsisg.StockGroupID
		WHERE LEFT(so.OrderDate, 4) BETWEEN '2013' AND '2017'
	) t1
	PIVOT (
		SUM(Quantity) FOR StockGroupName IN (
		[T-Shirts] ,[USB Novelties],
		[Packaging Materials], [Clothing],
		[Novelty Items], [Furry Footwear],
		[Mugs], [Computing Novelties], [Toys]
		)
	) t2
)
SELECT * FROM Year_Pivot;

--Create a function, input: order id; return: total of that order. 
--List invoices and use that function to attach the order total to the other fields of invoices. 
CREATE FUNCTION Total_Order (
	@Order_id INT
)
RETURNS INT AS
BEGIN
	DECLARE @Total_Order INT 
	SELECT 
		@Total_Order = ISNULL(SUM(sol.UnitPrice*sol.Quantity*(100-sol.TaxRate)/100),0)
	FROM Sales.OrderLines sol 
	WHERE sol.OrderID = @Order_id
	RETURN @Total_Order
END

SELECT si.InvoiceID, dbo.Total_Order(si.OrderID)
FROM Sales.Invoices si

--Create a new table called ods.Orders. Create a stored procedure, with proper error handling and transactions,
--that input is a date; when executed, it would find orders of that day, calculate order total, 
--and save the information (order id, order date, order total, customer id) into the new table. 
--If a given date is already existing in the new table, throw an error and roll back. 
--Execute the stored procedure 5 times using different dates. 
USE WideWorldImporters
CREATE TABLE ods.Orders_test (
	OrderID int,
	OrderDate DATETIME,
	Order_total INT,
	CustomerID INT
);

CREATE PROC usp_test( @input_date DATETIME)
AS 
BEGIN
	BEGIN TRANSACTION
		IF @input_date NOT IN (SELECT OrderDate FROM ods.Orders_test)
			SELECT 
				so.OrderID, so.OrderDate, 
				SUM(sol.Quantity*sol.UnitPrice*(100-sol.TaxRate)/100) order_total, 
				so.CustomerID 
			INTO ods.Orders_test
			FROM Sales.Orders so 
			INNER JOIN Sales.OrderLines sol ON sol.OrderID = so.OrderID
			WHERE so.OrderDate = @input_date
			GROUP BY so.OrderID, so.OrderDate, so.CustomerID 
		ELSE
			THROW 51000, 'Date already existed in the table',1
			ROLLBACK TRANSACTION
	COMMIT TRANSACTION 
end
EXEC usp_test @input_date='2013-01-03'
SELECT * FROM ods.Order_test


--Create a new table called ods.StockItem. It has following columns: 
--[StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,[Brand] ,[Size] ,
--[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,
--[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], [CountryOfManufacture], [Range], 
--[Shelflife]. Migrate all the data in the original stock item table.

CREATE SCHEMA ods;
GO
SELECT 
	wsi.StockItemID, wsi.StockItemName ,wsi.SupplierID ,wsi.ColorID ,wsi.UnitPackageID, wsi.OuterPackageID, 
	wsi.Brand, wsi.Size, wsi.LeadTimeDays, wsi.QuantityPerOuter, wsi.IsChillerStock, wsi.Barcode, wsi.TaxRate,
	wsi.UnitPrice, wsi.RecommendedRetailPrice,wsi.TypicalWeightPerUnit, wsi.MarketingComments, wsi.InternalComments,
	aco.CountryName AS CountryOfManufacture
INTO ods.StockItem_TEST
FROM Warehouse.StockItems wsi 
INNER JOIN Purchasing.Suppliers ps ON ps.SupplierID = wsi.SupplierID
INNER JOIN Application.Cities aci On aci.CityID = ps.DeliveryCityID
INNER JOIN Application.StateProvinces asp ON asp.StateProvinceID = aci.StateProvinceID
INNER JOIN Application.Countries aco ON aco.CountryID = asp.CountryID

select * from ods.StockItem_TEST

--Rewrite your stored procedure in (21). Now with a given date, it should wipe out all 
--the order data prior to the input date and load the order data that was placed in the next 7 days following the input date.
CREATE PROC usp_test_1( @input_date DATETIME)
AS 
BEGIN
	BEGIN TRANSACTION
		IF @input_date NOT IN (SELECT OrderDate FROM ods.Orders_test)
			SELECT 
				so.OrderID, so.OrderDate, 
				SUM(sol.Quantity*sol.UnitPrice*(100-sol.TaxRate)/100) order_total, 
				so.CustomerID 
			INTO ods.Orders_test
			FROM Sales.Orders so 
			INNER JOIN Sales.OrderLines sol ON sol.OrderID = so.OrderID
			WHERE so.OrderDate = @input_date
			GROUP BY so.OrderID, so.OrderDate, so.CustomerID 
		ELSE
			DELETE ods.Orders_test WHERE OrderDate<@input_date
			-- need to thank about what happened if the loaded date already in the table
	COMMIT TRANSACTION 
end;

-- Consider the JSON file:
DECLARE @info NVARCHAR(MAX) = '{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}'
--Looks like that it is our missed purchase orders. Migrate these data into Stock Item, Purchase Order and Purchase Order Lines tables. Of course, save the script.
SELECT * 
FROM OPENJSON(@info)
WITH(
	StockItemName NVARCHAR(100) '$.PurchaseOrders.StockItemName' ,
	SupplierID INT,
	UnitPackageID INT ,
	OuterPackageID INT ,
	Brand NVARCHAR(50),
	LeadTimeDays INT,
	QuantityPerOuter INT ,
	TaxRate DECIMAL(18,3),
	UnitPrice DECIMAL(18,2),
	RecommendedRetailPrice DECIMAL(18,2),
	TypicalWeightPerUnit DECIMAL(18,3),
	CustomFields NVARCHAR(MAX),
	[RANGE] NVARCHAR(100),
	OrderDate DATE,
	DeliveryMethodName NVARCHAR(50),
	ExpectedDeliveryDate DATE,
	SupplierReference NVARCHAR(20)
)
--Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.
SELECT * FROM dbo.Year_Pivot
FOR JSON AUTO

--Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.
SELECT * FROM dbo.Year_Pivot
FOR XML AUTO

--Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value) . 
--Create a stored procedure, input is a date. The logic would load invoice information 
--(all columns) as well as invoice line information (all columns) and forge them into a JSON string 
--and then insert into the new table just created. 
--Then write a query to run the stored procedure for each DATE that customer id 1 got something delivered to him.
CREATE TABLE ods.ConfirmedDeviveryJson (
	id INT,
	[date] DATETIME,
	[value] NVARCHAR(MAX)
);
CREATE FUNCTION udf_json_invoice (@date_requied DATETIME)
RETURNS NVARCHAR(MAX)
AS BEGIN RETURN(
	SELECT 
		*
	FROM Sales.Invoices si
	INNER JOIN Sales.InvoiceLines sol ON sol.InvoiceID = si.InvoiceID
	WHERE si.InvoiceDate = @date_requied
	FOR JSON AUTO
	)
END
CREATE PROCEDURE udp_json_invoice (
	@id INT,
	@input_date DATETIME
) 
AS BEGIN 
	INSERT INTO ods.ConfirmedDeviveryJson (
		id, [date], [value]
	)
	SELECT si.CustomerID, si.InvoiceDate, dbo.udf_json_invoice(@input_date)
	FROM Sales.Invoices si
	WHERE si.CustomerID = @id and si.InvoiceDate= @input_date 
END
EXEC dbo.udp_json_invoice 1, '2013-03-04'
SELECT * FROM ods.ConfirmedDeviveryJson;















--The first thing of all works pending would be to merge the user logon information, person information (including emails, phone numbers) and 
--products (of course, add category, colors) to WWI database

-- In the begining of the merge, we have to insert our bike products' info into the Warehouse.StockItems table. And then, we can assign these bike 
-- products into their group in StockGroups table. 
INSERT INTO Application.People (
	FullName, PreferredName, SearchName, IsPermittedToLogon, 
	LogonName, PhoneNumber, EmailAddress, FaxNumber, LastEditedBy,
	ValidFrom, ValidTo)
SELECT 
	aau.FullName, aau.PreferredName, aau.SearchName, aau.IsPermittedToLogon, 
	aau.LogonName, aau.PhoneNumber, aau.EmailAddress, aau.FaxNumber, 
	aau.LastEditedBy, aau.ValidFrom, aau.ValidTo
FROM [Adventure_works].Application.Users aau

--Insert basic new product info into WWI database
INSERT INTO Warehouse.StockItems (
	StockItemID, ColorID, StockItemName, Size, TaxRate, UnitPrice, Tags)
SELECT 
	aap.Product_id, aap.ColorID, aap.product_name, 
	aap.size, aap.TaxRate, aap.UnitPrice, aap.Category
FROM [Adventure_works].Application.Products aap

-- Assign product group into WWI stock_group
-- Firstly, a new StockGroupID, Stockname, LastEditedBy, ValidFrom, ValidTo info need in the [WWI].Warehouse.StockGroups needed
INSERT INTO Warehouse.StockGroups(StockGroupID, StockGroupName, LastEditedBy, ValidFrom, ValidTo)
VALUE (11, 'Bike', 1, '2022-08-03 00:00:00.0000000', '9999-12-31 23:59:59.9999999')

--Then we can assign different bike products into their groups in the StockItemStockGroup table
INSERT INTO Warehouse.StockItemStockGroups 
SELECT DISTINCT aap.Product_id, 11, 1, '2022-08-03 00:00:00.0000000'
FROM [Adventure_works].Application.Products aap
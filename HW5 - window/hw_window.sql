/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

SET STATISTICS TIME, IO ON

SELECT i.InvoiceID, c.CustomerName, i.InvoiceDate, ct.AmountExcludingTax,
	(SELECT SUM(InnerCT.AmountExcludingTax)
	 FROM Sales.Invoices AS InnerI
	 JOIN Sales.CustomerTransactions AS InnerCT
	  ON InnerI.InvoiceID = InnerCT.InvoiceID 
	 WHERE InnerI.InvoiceDate >= '2015-01-01'
	  AND (YEAR(InnerI.InvoiceDate) < YEAR(i.InvoiceDate) OR YEAR(InnerI.InvoiceDate) = YEAR(i.InvoiceDate)
	  AND MONTH(InnerI.InvoiceDate) <= MONTH(i.InvoiceDate))) AS RunningMonthTotal
FROM Sales.Invoices AS i
JOIN Sales.Customers as c
 ON i.CustomerID = c.CustomerID
JOIN Sales.CustomerTransactions AS ct
 ON i.InvoiceID = ct.InvoiceID
WHERE i.InvoiceDate >= '2015-01-01'
ORDER BY i.InvoiceID

/*
(затронуто строк: 31440)
Table 'Worktable'. Scan count 32326, logical reads 249779, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 2220, logical reads 499944, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Invoices'. Scan count 2, logical reads 22800, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Customers'. Scan count 1, logical reads 40, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 17826 ms,  elapsed time = 17858 ms.
*/

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

SELECT i.InvoiceID, c.CustomerName, i.InvoiceDate, ct.AmountExcludingTax,
	SUM(ct.AmountExcludingTax) OVER (ORDER BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)) AS MonthTotal
FROM Sales.Invoices AS i
JOIN Sales.Customers AS c
 ON i.CustomerID = c.CustomerID
JOIN Sales.CustomerTransactions AS ct
 ON i.InvoiceID = ct.InvoiceID
WHERE i.InvoiceDate >= '2015-01-01'
ORDER BY i.InvoiceID

/*
(затронуто строк: 31440)
Table 'Worktable'. Scan count 18, logical reads 73197, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 1126, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 11400, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Customers'. Scan count 1, logical reads 40, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 210 ms,  elapsed time = 249 ms.

Запрос с оконной функцией оказался значительно быстрее варианта с подзапросом.
Запрос с подзапросом производит намного больше операций со временной таблицей ('Worktable'), 
количество чтений из таблиц 'Invoices' и 'CustomerTransactions' тоже больше в разы.
*/

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

WITH MonthlyRankedItems AS
(
	SELECT MONTH(o.OrderDate) AS OrderMonth, ol.Description, SUM(ol.Quantity) AS TotalQuantity,
		ROW_NUMBER() OVER (PARTITION BY MONTH(o.OrderDate) ORDER BY SUM(ol.Quantity) DESC) AS ItemSalesRank
	FROM Sales.Orders AS o
	JOIN Sales.OrderLines AS ol
	 ON o.OrderID = ol.OrderID
	WHERE o.OrderDate BETWEEN '2016-01-01' AND '2016-12-31'
	GROUP BY MONTH(o.OrderDate), ol.Description
)
SELECT *
FROM MonthlyRankedItems
WHERE ItemSalesRank <= 2

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT si.StockItemID, si.StockItemName, si.Brand, si.UnitPrice,
	ROW_NUMBER() OVER (PARTITION BY SUBSTRING(si.StockItemName, 1, 1) ORDER BY si.StockItemName) AS FirstLetterNumber,
	SUM(sih.QuantityOnHand) OVER () AS TotalQuantity,
	SUM(sih.QuantityOnHand) OVER (PARTITION BY SUBSTRING(si.StockItemName, 1, 1)) AS FirstLetterTotalQuantity,
	LEAD(si.StockItemID) OVER (ORDER BY si.StockItemName) AS NextID,
	LAG(si.StockItemID) OVER (ORDER BY si.StockItemName) AS PreviousID,
	LAG(si.StockItemName, 2, 'No items') OVER (ORDER BY si.StockItemName) AS PreviousName,
	NTILE(30) OVER (ORDER BY si.TypicalWeightPerUnit) AS GroupNumber
FROM Warehouse.StockItems AS si
JOIN Warehouse.StockItemHoldings AS sih
 ON si.StockItemID = sih.StockItemID
ORDER BY si.StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

WITH PersonalSalesHistory AS
(
	SELECT p.PersonID, p.FullName, c.CustomerID, c.CustomerName, i.InvoiceDate, ct.AmountExcludingTax,
		LEAD(i.CustomerID) OVER (PARTITION BY p.PersonID ORDER BY i.InvoiceDate) AS NextCustomer
	FROM Application.People AS p
	JOIN Sales.Invoices AS i
	 ON p.PersonID = i.SalespersonPersonID AND p.IsSalesperson = 1
	JOIN Sales.Customers AS c
	 ON i.CustomerID = c.CustomerID
	JOIN Sales.CustomerTransactions AS ct
	 ON i.InvoiceID = ct.InvoiceID
)
SELECT PersonID, FullName, CustomerID, CustomerName, InvoiceDate, AmountExcludingTax
FROM PersonalSalesHistory
WHERE NextCustomer IS NULL

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

WITH RankedItemsByCustomer AS
(
	SELECT o.CustomerID, c.CustomerName, ol.StockItemID, ol.UnitPrice, o.OrderDate,
		DENSE_RANK() OVER (PARTITION BY o.CustomerID ORDER BY ol.UnitPrice DESC) AS PriceRank
	FROM Sales.OrderLines AS ol
	JOIN Sales.Orders AS o
	 ON ol.OrderID = o.OrderID
	JOIN Sales.Customers AS c
	 ON o.CustomerID = c.CustomerID
)
SELECT *
FROM RankedItemsByCustomer
WHERE PriceRank <= 2

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 
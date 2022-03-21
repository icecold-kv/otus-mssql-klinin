/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT p.PersonID, p.FullName
FROM Application.People AS p
WHERE p.IsSalesperson = 1 AND p.PersonID NOT IN (
	SELECT i.SalespersonPersonID
	FROM Sales.Invoices AS i
	WHERE i.InvoiceDate = '2015-07-04'
);

WITH SalespersonsSales AS
(
	SELECT i.SalespersonPersonID, i.CustomerID
	FROM Sales.Invoices AS i
	WHERE i.InvoiceDate = '2015-07-04'
)
SELECT p.PersonID, p.FullName
FROM Application.People AS p
LEFT JOIN SalespersonsSales AS sps
 ON p.PersonID = sps.SalespersonPersonID
WHERE p.IsSalesperson = 1 AND sps.CustomerID IS NULL

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT si.StockItemID, si.StockItemName, si.UnitPrice
FROM Warehouse.StockItems AS si
WHERE si.UnitPrice <= ALL(SELECT UnitPrice FROM Warehouse.StockItems);

SELECT si.StockItemID, si.StockItemName, si.UnitPrice
FROM Warehouse.StockItems AS si
WHERE si.UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems);

WITH MinPrice AS
(
	SELECT MIN(UnitPrice) AS Price FROM Warehouse.StockItems
)
SELECT si.StockItemID, si.StockItemName, si.UnitPrice
FROM Warehouse.StockItems AS si
JOIN MinPrice AS mp
 ON si.UnitPrice = mp.Price

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT * 
FROM Sales.Customers AS c
WHERE c.CustomerID IN (
	SELECT TOP 5 ct.CustomerID
	FROM Sales.CustomerTransactions AS ct
	ORDER BY ct.TransactionAmount DESC
);

WITH TopClients AS
(
	SELECT TOP 5 ct.CustomerID, ct.TransactionAmount
	FROM Sales.CustomerTransactions AS ct
	ORDER BY ct.TransactionAmount DESC
)
SELECT tc.TransactionAmount, c.*
FROM Sales.Customers AS c
JOIN TopClients as tc
 ON c.CustomerID = tc.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

SELECT sc.DeliveryCityID, ac.CityName, ap.FullName
FROM Sales.OrderLines AS sol
JOIN Sales.Invoices AS si ON sol.OrderID = si.OrderID
JOIN Sales.Customers AS sc ON si.CustomerID = sc.CustomerID
JOIN Application.Cities AS ac ON sc.DeliveryCityID = ac.CityID
JOIN Application.People AS ap ON si.PackedByPersonID = ap.PersonID
WHERE sol.StockItemID IN (
	SELECT TOP 3 si.StockItemID
	FROM Warehouse.StockItems AS si
	ORDER BY si.UnitPrice DESC
);

WITH TopItems AS (
	SELECT TOP 3 si.StockItemID
	FROM Warehouse.StockItems AS si
	ORDER BY si.UnitPrice DESC
)
SELECT sc.DeliveryCityID, ac.CityName, ap.FullName
FROM Sales.OrderLines AS sol
JOIN TopItems AS ti ON sol.StockItemID = ti.StockItemID
JOIN Sales.Invoices AS si ON sol.OrderID = si.OrderID
JOIN Sales.Customers AS sc ON si.CustomerID = sc.CustomerID
JOIN Application.Cities AS ac ON sc.DeliveryCityID = ac.CityID
JOIN Application.People AS ap ON si.PackedByPersonID = ap.PersonID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

-- --
-- Запрос выводит ID, дату, имя сотрудника совершившего продажу, общую сумму в счёте 
-- и общую стоимость проданных товаров (если присутствует дата комплектации всего заказа)
-- для счетов с общей суммой больше 27000

WITH SalesTotals AS (
	SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000
)
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	People.FullName AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		JOIN Sales.Orders ON Orders.OrderID = OrderLines.OrderID
		WHERE OrderLines.OrderId = Invoices.OrderId
			AND Orders.PickingCompletedWhen IS NOT NULL
	) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN Application.People
 ON People.PersonID = Invoices.SalespersonPersonID
JOIN SalesTotals
 ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- Немного улучшил читабельность запроса
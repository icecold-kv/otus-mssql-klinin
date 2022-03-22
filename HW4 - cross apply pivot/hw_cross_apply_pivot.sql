/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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

USE WideWorldImporters;

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

WITH MonhtlyOrderCounts AS (
	SELECT
	  FORMAT(DATEFROMPARTS(YEAR(so.OrderDate), MONTH(so.OrderDate), 1), '01.MM.yyyy') AS InvoiceMonth,
	  SUBSTRING(sc.CustomerName, CHARINDEX('(', sc.CustomerName)+1, CHARINDEX(')', sc.CustomerName)-CHARINDEX('(', sc.CustomerName)-1) AS DepartmentName,
	  COUNT(*) AS OrderCount
	FROM Sales.Orders AS so
	JOIN Sales.Customers AS sc ON so.CustomerID = sc.CustomerID AND so.CustomerID BETWEEN 2 AND 6
	GROUP BY YEAR(so.OrderDate), MONTH(so.OrderDate), sc.CustomerName
)
SELECT * FROM MonhtlyOrderCounts AS moc
PIVOT (
	SUM(moc.OrderCount)
	FOR moc.DepartmentName IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])
) AS pvt
ORDER BY Convert(DATETIME, pvt.InvoiceMonth, 104);

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT CustomerName, AddressLine
FROM (
	SELECT
		CustomerName,
		DeliveryAddressLine1,
		DeliveryAddressLine2,
		PostalAddressLine1,
		PostalAddressLine2
	FROM Sales.Customers
	WHERE CustomerName LIKE '%Tailspin Toys%'
) AS Addresses
UNPIVOT (AddressLine FOR SourceColumn IN (
	DeliveryAddressLine1,
	DeliveryAddressLine2,
	PostalAddressLine1,
	PostalAddressLine2
)) AS upvt

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT CountryId, CountryName, Code
FROM (
	SELECT
		CountryID,
		CountryName,
		IsoAlpha3Code,
		CAST(IsoNumericCode AS NVARCHAR(3)) AS IsoNumericCode
	FROM Application.Countries
) AS Codes
UNPIVOT (Code FOR SourceColumn IN (IsoAlpha3Code, IsoNumericCode)) AS upvt

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT sc.CustomerID, sc.CustomerName, ca.*
FROM Sales.Customers AS sc
CROSS APPLY (
	SELECT TOP 2
		sol.StockItemID,
		MAX(sol.UnitPrice) AS UnitPrice,
		MAX(so.OrderDate) AS OrderDate
	FROM Sales.Orders AS so
	JOIN Sales.OrderLines AS sol ON so.OrderID = sol.OrderID
	WHERE so.CustomerID = sc.CustomerID
	GROUP BY so.CustomerID, sol.StockItemID
	ORDER BY MAX(sol.UnitPrice) DESC
) AS ca

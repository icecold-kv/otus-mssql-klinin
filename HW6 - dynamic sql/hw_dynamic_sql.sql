/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

DECLARE @Query AS NVARCHAR(MAX)
DECLARE @Columns AS NVARCHAR(MAX)

-- больше 655 клиентов не влазят в максимально возможный размер строки
SELECT TOP 655 @Columns = ISNULL(@Columns + ',','') + QUOTENAME(CustomerName)
FROM (
	SELECT DISTINCT CustomerName
	FROM Sales.Customers
) AS Names
ORDER BY CustomerName

SELECT @Columns;

SET @Query = 
N'WITH MonhtlyOrderCounts AS (
	SELECT
	  FORMAT(DATEFROMPARTS(YEAR(so.OrderDate), MONTH(so.OrderDate), 1), ''01.MM.yyyy'') AS InvoiceMonth,
	  sc.CustomerName,
	  COUNT(*) AS OrderCount
	FROM Sales.Orders AS so
	JOIN Sales.Customers AS sc ON so.CustomerID = sc.CustomerID
	GROUP BY YEAR(so.OrderDate), MONTH(so.OrderDate), sc.CustomerName
)
SELECT * FROM MonhtlyOrderCounts AS moc
PIVOT (
	SUM(moc.OrderCount)
	FOR moc.CustomerName IN (' + @Columns + ')
) AS pvt
ORDER BY Convert(DATETIME, pvt.InvoiceMonth, 104);'

SELECT @Query

EXEC sp_executesql @Query

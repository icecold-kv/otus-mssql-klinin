/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

DROP FUNCTION IF EXISTS TopCustomer
GO

CREATE FUNCTION TopCustomer()
RETURNS nvarchar(100)
AS
BEGIN
	DECLARE @CustomerName nvarchar(100);
	
	SELECT TOP 1 @CustomerName = sc.CustomerName
	FROM Sales.Customers AS sc
	JOIN Sales.Invoices AS si ON si.CustomerID = sc.CustomerID
	JOIN Sales.InvoiceLines AS sil ON sil.InvoiceID = si.InvoiceID
	GROUP BY sc.CustomerName
	ORDER BY SUM(sil.Quantity * sil.UnitPrice) DESC

	RETURN @CustomerName
END
GO

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

DROP PROCEDURE IF EXISTS ClientTotalExpenses
GO

CREATE PROCEDURE ClientTotalExpenses
    @СustomerID int
AS
    SET NOCOUNT ON;
	
	SELECT SUM(sil.Quantity * sil.UnitPrice) AS TotalExpenses
	FROM Sales.Invoices AS si
	JOIN Sales.InvoiceLines AS sil ON sil.InvoiceID = si.InvoiceID
	WHERE si.CustomerID = @СustomerID
	GROUP BY si.CustomerID
GO

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

DROP PROCEDURE IF EXISTS ClientTotalExpensesProc
GO

CREATE PROCEDURE ClientTotalExpensesProc
    @СustomerID int
AS
    SET NOCOUNT ON;
	
	SELECT SUM(sil.Quantity * sil.UnitPrice) AS TotalExpenses
	FROM Sales.Invoices AS si
	JOIN Sales.InvoiceLines AS sil ON sil.InvoiceID = si.InvoiceID
	WHERE si.CustomerID = @СustomerID
	GROUP BY si.CustomerID
GO

SET STATISTICS TIME, IO ON
EXEC ClientTotalExpensesProc 25
/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
Table 'InvoiceLines'. Scan count 2, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 161, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'InvoiceLines'. Segment reads 1, segment skipped 0.
Table 'Invoices'. Scan count 1, logical reads 2, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Customers'. Scan count 0, logical reads 2, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 4 ms,  elapsed time = 6 ms.

 SQL Server Execution Times:
   CPU time = 4 ms,  elapsed time = 6 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
*/
GO

DROP FUNCTION IF EXISTS ClientTotalExpensesFunc
GO

CREATE FUNCTION ClientTotalExpensesFunc(@СustomerID int)
RETURNS decimal(18,2)
AS
BEGIN
	DECLARE @TotalExpenses decimal(18,2);
	
	SELECT @TotalExpenses = SUM(sil.Quantity * sil.UnitPrice)
	FROM Sales.Customers AS sc
	JOIN Sales.Invoices AS si ON si.CustomerID = sc.CustomerID
	JOIN Sales.InvoiceLines AS sil ON sil.InvoiceID = si.InvoiceID
	WHERE sc.CustomerID = @СustomerID
	GROUP BY sc.CustomerID

	RETURN @TotalExpenses
END
GO

SELECT dbo.ClientTotalExpensesFunc(32) AS TotalExpenses
/*
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 1 ms, elapsed time = 1 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

(затронута одна строка)

(затронута одна строка)

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 4 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
*/

-- В данном случае функция работает быстрее хранимой процедуры, что можно видеть по времени и плану выполнения
-- Предположу, что произошло это из-за кэширования результатов выполнения запроса, так как видно,
-- что в отличие от хранимой процедуры, функция не обращалась к таблицам базы данных
SET STATISTICS TIME, IO OFF
GO

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

DROP FUNCTION IF EXISTS ClientMostExpensiveItem
GO

CREATE FUNCTION ClientMostExpensiveItem(@СustomerID int)
RETURNS TABLE
AS
RETURN (
	SELECT TOP 1 si.CustomerID, sil.StockItemID, sil.Description
	FROM Sales.Invoices AS si
	JOIN Sales.InvoiceLines AS sil ON sil.InvoiceID = si.InvoiceID
	WHERE si.CustomerID = @СustomerID
	ORDER BY sil.UnitPrice DESC
)
GO

SELECT sc.CustomerID, sc.CustomerName, cmei.StockItemID, cmei.Description
FROM Sales.Customers AS sc
CROSS APPLY dbo.ClientMostExpensiveItem(sc.CustomerID) AS cmei

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/

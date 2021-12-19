/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName LIKE 'Animal%' OR StockItemName LIKE '%urgent%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, s.SupplierName
FROM Purchasing.Suppliers AS s
LEFT JOIN Purchasing.PurchaseOrders AS p
 ON s.SupplierID = p.SupplierID
WHERE p.PurchaseOrderID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT
 o.OrderID,
 FORMAT(o.OrderDate, 'dd.MM.yy') AS OrderDate,
 FORMAT(o.OrderDate, 'MMMM') AS OrderMonth,
 DATEPART(q, o.OrderDate) AS OrderQuarter,
 (MONTH(o.OrderDate) - 1) / 4 + 1 AS OrderTertile,
 c.CustomerName
FROM Sales.Orders AS o
JOIN Sales.OrderLines AS ol
 ON o.OrderID = ol.OrderID
JOIN Sales.Customers AS c
 ON o.CustomerID = c.CustomerID
WHERE (ol.UnitPrice > 100 OR ol.Quantity > 20) AND o.PickingCompletedWhen IS NOT NULL
GROUP BY o.OrderID, o.OrderDate, c.CustomerName
ORDER BY OrderQuarter, OrderTertile, OrderDate

SELECT
 o.OrderID,
 FORMAT(o.OrderDate, 'dd.MM.yy') AS OrderDate,
 FORMAT(o.OrderDate, 'MMMM') AS OrderMonth,
 DATEPART(q, o.OrderDate) AS OrderQuarter,
 (MONTH(o.OrderDate) - 1) / 4 + 1 AS OrderTertile,
 c.CustomerName
FROM Sales.Orders AS o
JOIN Sales.OrderLines AS ol
 ON o.OrderID = ol.OrderID
JOIN Sales.Customers AS c
 ON o.CustomerID = c.CustomerID
WHERE (ol.UnitPrice > 100 OR ol.Quantity > 20) AND o.PickingCompletedWhen IS NOT NULL
GROUP BY o.OrderID, o.OrderDate, c.CustomerName
ORDER BY OrderQuarter, OrderTertile, OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT
 dm.DeliveryMethodName,
 po.ExpectedDeliveryDate,
 s.SupplierName,
 p.FullName
FROM Application.DeliveryMethods AS dm
JOIN Purchasing.Suppliers AS s
 ON dm.DeliveryMethodID = s.DeliveryMethodID
JOIN Purchasing.PurchaseOrders AS po
 ON s.SupplierID = po.SupplierID
JOIN Application.People AS p
 ON po.ContactPersonID = p.PersonID
WHERE DeliveryMethodName LIKE '%Air Freight'
AND po.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
AND po.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 
 c.CustomerName,
 p.FullName
FROM Sales.Orders AS o
JOIN Sales.Customers AS c
 ON o.CustomerID = c.CustomerID
JOIN Application.People AS p
 ON o.SalespersonPersonID = p.PersonID
ORDER BY o.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT
 o.CustomerID,
 c.CustomerName,
 c.PhoneNumber
FROM Sales.Orders AS o
JOIN Sales.OrderLines AS ol
 ON o.OrderID = ol.OrderID
JOIN Warehouse.StockItems AS si
 ON ol.StockItemID = si.StockItemID
JOIN Sales.Customers AS c
 ON o.CustomerID = c.CustomerID
WHERE si.StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
 YEAR(i.InvoiceDate) AS [Year],
 MONTH(i.InvoiceDate) AS [Month],
 AVG(ol.UnitPrice) AS AveragePrice,
 SUM(ol.UnitPrice * ol.Quantity) AS Total
FROM Sales.Invoices AS i
JOIN Sales.OrderLines AS ol
 ON i.OrderID = ol.OrderID
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
 YEAR(i.InvoiceDate) AS [Year],
 MONTH(i.InvoiceDate) AS [Month],
 SUM(ol.UnitPrice * ol.Quantity) AS Total
FROM Sales.Invoices AS i
JOIN Sales.OrderLines AS ol
 ON i.OrderID = ol.OrderID
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
HAVING SUM(ol.UnitPrice * ol.Quantity) > 10000

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
 YEAR(i.InvoiceDate) AS [Year],
 MONTH(i.InvoiceDate) AS [Month],
 ol.Description,
 SUM(ol.UnitPrice * ol.Quantity) AS Total,
 MIN(i.InvoiceDate) AS FisrtSale,
 SUM(ol.Quantity) AS Quantity
FROM Sales.Invoices AS i
JOIN Sales.OrderLines AS ol
 ON i.OrderID = ol.OrderID
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate), ol.Description
HAVING SUM(ol.Quantity) < 50

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

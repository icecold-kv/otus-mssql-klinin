/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO Purchasing.Suppliers
(SupplierID,
 SupplierName,
 SupplierCategoryID,
 PrimaryContactPersonID,
 AlternateContactPersonID,
 DeliveryCityID,
 PostalCityID,
 PaymentDays,
 PhoneNumber,
 FaxNumber,
 WebsiteURL,
 DeliveryAddressLine1,
 DeliveryPostalCode,
 PostalAddressLine1,
 PostalPostalCode,
 LastEditedBy
) VALUES
(NEXT VALUE FOR Sequences.SupplierID, N'One Corp.', 1, 1, 11, 1, 1, 1, N'(847) 111-0100', N'(847) 111-0101', N'http://one.com', N'First Street', N'11111', N'PO Box 1', N'11111', 1),
(NEXT VALUE FOR Sequences.SupplierID, N'Two Corp.', 2, 2, 22, 22, 22, 2, N'(854) 222-0200', N'(854) 222-0201', N'http://two.com', N'Second Street', N'22222', N'PO Box 2', N'22222', 2),
(NEXT VALUE FOR Sequences.SupplierID, N'Three Corp.', 3, 3, 33, 3, 3, 3, N'(814) 333-0300', N'(814) 333-0301', N'http://three.com', N'Third Street', N'33333', N'PO Box 3', N'33333', 3),
(NEXT VALUE FOR Sequences.SupplierID, N'Four Corp.', 4, 4, 44, 4, 4, 4, N'(827) 444-0400', N'(827) 444-0401', N'http://four.com', N'Fourth Street', N'44444', N'PO Box 4', N'44444', 4),
(NEXT VALUE FOR Sequences.SupplierID, N'Five Corp.', 5, 5, 45, 5, 5, 5, N'(809) 555-0500', N'(809) 555-0501', N'http://five.com', N'Fifth Street', N'55555', N'PO Box 5', N'55555', 5)

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM Purchasing.Suppliers
WHERE SupplierName = N'One Corp.'

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE Purchasing.Suppliers
SET BankAccountName  = N'Two Corp',
	BankAccountBranch = N'Woodgrove Bank San Francisco',
	BankAccountCode = N'954269',
	BankAccountNumber = N'7125863879'
WHERE SupplierName = N'Two Corp.'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

DROP TABLE IF EXISTS #NewSuppliersInfo

SELECT TOP 4 *
INTO #NewSuppliersInfo
FROM Purchasing.Suppliers
ORDER BY SupplierID DESC

ALTER TABLE #NewSuppliersInfo DROP COLUMN ValidFrom, ValidTo

UPDATE #NewSuppliersInfo
SET DeliveryMethodID  = 4,
	SupplierReference = N'F23708032'
WHERE SupplierName = N'Four Corp.'

INSERT INTO #NewSuppliersInfo
(SupplierID,
 SupplierName,
 SupplierCategoryID,
 PrimaryContactPersonID,
 AlternateContactPersonID,
 DeliveryCityID,
 PostalCityID,
 PaymentDays,
 PhoneNumber,
 FaxNumber,
 WebsiteURL,
 DeliveryAddressLine1,
 DeliveryPostalCode,
 PostalAddressLine1,
 PostalPostalCode,
 LastEditedBy
) VALUES
(NEXT VALUE FOR Sequences.SupplierID, N'Six Corp.', 6, 6, 12, 6, 6, 6, N'(847) 666-0600', N'(847) 666-0601', N'http://six.com', N'Sixth Street', N'66666', N'PO Box 6', N'66666', 6)

MERGE Purchasing.Suppliers AS target 
USING (SELECT * FROM #NewSuppliersInfo) AS source
(SupplierID
,SupplierName
,SupplierCategoryID
,PrimaryContactPersonID
,AlternateContactPersonID
,DeliveryMethodID
,DeliveryCityID
,PostalCityID
,SupplierReference
,BankAccountName
,BankAccountBranch
,BankAccountCode
,BankAccountNumber
,BankInternationalCode
,PaymentDays
,InternalComments
,PhoneNumber
,FaxNumber
,WebsiteURL
,DeliveryAddressLine1
,DeliveryAddressLine2
,DeliveryPostalCode
,DeliveryLocation
,PostalAddressLine1
,PostalAddressLine2
,PostalPostalCode
,LastEditedBy)
ON (target.SupplierID = source.SupplierID) 
WHEN MATCHED 
  THEN UPDATE SET SupplierName = source.SupplierName
	,SupplierCategoryID = source.SupplierCategoryID
	,PrimaryContactPersonID = source.PrimaryContactPersonID
    ,AlternateContactPersonID = source.AlternateContactPersonID
    ,DeliveryMethodID = source.DeliveryMethodID
    ,DeliveryCityID = source.DeliveryCityID
    ,PostalCityID = source.PostalCityID
    ,SupplierReference = source.SupplierReference
    ,BankAccountName = source.BankAccountName
    ,BankAccountBranch = source.BankAccountBranch
    ,BankAccountCode = source.BankAccountCode
    ,BankAccountNumber = source.BankAccountNumber
    ,BankInternationalCode = source.BankInternationalCode
    ,PaymentDays = source.PaymentDays
    ,InternalComments = source.InternalComments
    ,PhoneNumber = source.PhoneNumber
    ,FaxNumber = source.FaxNumber
    ,WebsiteURL = source.WebsiteURL
    ,DeliveryAddressLine1 = source.DeliveryAddressLine1
    ,DeliveryAddressLine2 = source.DeliveryAddressLine2
    ,DeliveryPostalCode = source.DeliveryPostalCode
    ,DeliveryLocation = source.DeliveryLocation
    ,PostalAddressLine1 = source.PostalAddressLine1
    ,PostalAddressLine2 = source.PostalAddressLine2
    ,PostalPostalCode = source.PostalPostalCode
    ,LastEditedBy = source.LastEditedBy
WHEN NOT MATCHED 
  THEN INSERT (SupplierID
	,SupplierName
	,SupplierCategoryID
	,PrimaryContactPersonID
	,AlternateContactPersonID
	,DeliveryMethodID
	,DeliveryCityID
	,PostalCityID
	,SupplierReference
	,BankAccountName
	,BankAccountBranch
	,BankAccountCode
	,BankAccountNumber
	,BankInternationalCode
	,PaymentDays
	,InternalComments
	,PhoneNumber
	,FaxNumber
	,WebsiteURL
	,DeliveryAddressLine1
	,DeliveryAddressLine2
	,DeliveryPostalCode
	,DeliveryLocation
	,PostalAddressLine1
	,PostalAddressLine2
	,PostalPostalCode
	,LastEditedBy)
  VALUES (source.SupplierID
	,source.SupplierName
	,source.SupplierCategoryID
	,source.PrimaryContactPersonID
	,source.AlternateContactPersonID
	,source.DeliveryMethodID
	,source.DeliveryCityID
	,source.PostalCityID
	,source.SupplierReference
	,source.BankAccountName
	,source.BankAccountBranch
	,source.BankAccountCode
	,source.BankAccountNumber
	,source.BankInternationalCode
	,source.PaymentDays
	,source.InternalComments
	,source.PhoneNumber
	,source.FaxNumber
	,source.WebsiteURL
	,source.DeliveryAddressLine1
	,source.DeliveryAddressLine2
	,source.DeliveryPostalCode
	,source.DeliveryLocation
	,source.PostalAddressLine1
	,source.PostalAddressLine2
	,source.PostalPostalCode
	,source.LastEditedBy)
OUTPUT deleted.*, $action, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

EXEC master..xp_cmdshell 'bcp "WideWorldImporters.Purchasing.Suppliers" out  "/var/tmp/Suppliers.txt" -T -w -t"@!qq1&&", -S localhost'

DROP TABLE IF EXISTS #LoadedSuppliers
SELECT TOP 0 * INTO #LoadedSuppliers FROM Purchasing.Suppliers

BULK INSERT #LoadedSuppliers
FROM '/var/tmp/Suppliers.txt'
WITH (
	BATCHSIZE = 1000, 
	DATAFILETYPE = 'widechar',
	FIELDTERMINATOR = '@!qq1&&',
	ROWTERMINATOR ='\n',
	KEEPNULLS,
	TABLOCK
);

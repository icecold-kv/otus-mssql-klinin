/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "13 - CLR".
*/

USE WideWorldImporters

/*
2) Взять готовые исходники из какой-нибудь статьи, скомпилировать, подключить dll, продемонстрировать использование.
https://habr.com/ru/post/88396/

Результат ДЗ:
* исходники (если они есть), желательно проект Visual Studio
* откомпилированная сборка dll
* скрипт подключения dll
* демонстрация использования
*/

-- Включаем CLR
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;
EXEC sp_configure 'clr strict security', 0 
GO
RECONFIGURE;
GO

-- Для возможности создания сборок с EXTERNAL_ACCESS или UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

-- Подключаем dll 
CREATE ASSEMBLY SplitString
FROM '/var/tmp/CLR.dll'
WITH PERMISSION_SET = SAFE;
GO

-- Подключаем функцию из dll
CREATE FUNCTION SplitStringCLR(@text nvarchar(max), @delimiter nchar(1))
RETURNS TABLE (part nvarchar(max), ID_ODER int) WITH EXECUTE AS CALLER
AS EXTERNAL NAME SplitString.UserDefinedFunctions.SplitString
GO

-- Проверяем работу функции
SELECT part FROM SplitStringCLR('11,22,33,44', ',')

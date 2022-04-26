CREATE DATABASE [PowerOptimization]
GO

USE [PowerOptimization]
GO

CREATE SCHEMA [Application]
GO


-- Регионы
CREATE TABLE [Application].[Territories]
(
 [TerritoryID] int NOT NULL ,
 [Name]        nvarchar(50) NOT NULL ,

 CONSTRAINT [PK_Territories] PRIMARY KEY CLUSTERED ([TerritoryID] ASC)
);
GO


-- Приоритеты предполагаемых часов пиковой нагрузки
CREATE TABLE [Application].[Priorities]
(
 [PriorityID] int NOT NULL ,
 [Name]       varchar(50) NOT NULL ,

 CONSTRAINT [PK_Priorities] PRIMARY KEY CLUSTERED ([PriorityID] ASC)
);
GO


-- Предполагаемые часы пиковой нагрузки
CREATE TABLE [Application].[SupposedPeakHours]
(
 [SupposedPeakHourID] int NOT NULL ,
 [TerritoryID]        int NOT NULL ,
 [PriorityID]         int NOT NULL ,
 [Year]               smallint NOT NULL ,
 [Month]              tinyint NOT NULL ,
 [Hour]               tinyint NOT NULL ,
 [Probability]        tinyint NOT NULL ,

 CONSTRAINT [PK_SupposedPeakHours] PRIMARY KEY CLUSTERED ([SupposedPeakHourID] ASC),
 CONSTRAINT [FK_SupposedPeakHours_Territories] FOREIGN KEY ([TerritoryID])  REFERENCES [Application].[Territories]([TerritoryID]),
 CONSTRAINT [FK_SupposedPeakHours_Priorities] FOREIGN KEY ([PriorityID])  REFERENCES [Application].[Priorities]([PriorityID])
);
GO

CREATE NONCLUSTERED INDEX [IX_SupposedPeakHours_Territories] ON [Application].[SupposedPeakHours] 
 (
  [TerritoryID] ASC
 )
CREATE NONCLUSTERED INDEX [IX_SupposedPeakHours_Priorities] ON [Application].[SupposedPeakHours] 
 (
  [PriorityID] ASC
 )

GO


-- Выходные дни
CREATE TABLE [Application].[Weekends]
(
 [WeekendID]   int NOT NULL ,
 [TerritoryID] int NOT NULL ,
 [Date]        date NOT NULL ,
 [IsWeekend]   bit NOT NULL ,

 CONSTRAINT [PK_Weekends] PRIMARY KEY CLUSTERED ([WeekendID] ASC),
 CONSTRAINT [FK_Weekends_Territories] FOREIGN KEY ([TerritoryID])  REFERENCES [Application].[Territories]([TerritoryID]),
 -- В каждом регионе одному дню должна соответствовать только одна запись
 CONSTRAINT [UQ_Weekends_Date] UNIQUE ([TerritoryID], [Date])
);
GO

CREATE NONCLUSTERED INDEX [IX_Weekends_Territories] ON [Application].[Weekends] 
 (
  [TerritoryID] ASC
 )

GO


-- Фактические часы пиковой нагрузки
CREATE TABLE [Application].[FactPeakHours]
(
 [FactPeakHourID] int NOT NULL ,
 [TerritoryID]    int NOT NULL ,
 [Date]           date NOT NULL ,
 [Hour]           tinyint NOT NULL ,

 CONSTRAINT [PK_FactPeakHours] PRIMARY KEY CLUSTERED ([FactPeakHourID] ASC),
 CONSTRAINT [FK_FactPeakHours_Territories] FOREIGN KEY ([TerritoryID])  REFERENCES [Application].[Territories]([TerritoryID]),
 -- Для каждого региона может быть только один час пиковой нагрузки в день
 CONSTRAINT [UQ_FactPeakHours_Date] UNIQUE ([TerritoryID], [Date]) 
);
GO

CREATE NONCLUSTERED INDEX [IX_FactPeakHours_Territories] ON [Application].[FactPeakHours] 
 (
  [TerritoryID] ASC
 )

GO


-- Стоимость электроэнергии
CREATE TABLE [Application].[PowerCosts]
(
 [PowerCostID] int NOT NULL ,
 [TerritoryID] int NOT NULL ,
 [Year]        smallint NOT NULL ,
 [Month]       tinyint NOT NULL ,
 [Cost]        decimal(18,3) NOT NULL ,


 CONSTRAINT [PK_PowerCosts] PRIMARY KEY CLUSTERED ([PowerCostID] ASC),
 CONSTRAINT [FK_PowerCosts_Territories] FOREIGN KEY ([TerritoryID])  REFERENCES [Application].[Territories]([TerritoryID])
);
GO

CREATE NONCLUSTERED INDEX [IX_PowerCosts_Territories] ON [Application].[PowerCosts] 
 (
  [TerritoryID] ASC
 )

GO


-- Предприятия
CREATE TABLE [Application].[Enterprises]
(
 [EnterpriseID]       int NOT NULL ,
 [TerritoryID]        int NOT NULL ,
 [Name]               nvarchar(50) NOT NULL ,
 [PowerDecrementPlan] int NOT NULL ,

 CONSTRAINT [PK_Enterprises] PRIMARY KEY CLUSTERED ([EnterpriseID] ASC),
 CONSTRAINT [FK_Enterprises_Territories] FOREIGN KEY ([TerritoryID])  REFERENCES [Application].[Territories]([TerritoryID])
);
GO

CREATE NONCLUSTERED INDEX [IX_Enterprises_Territories] ON [Application].[Enterprises] 
 (
  [TerritoryID] ASC
 )

GO


-- Группы устройств-потребителей электроэнергии
CREATE TABLE [Application].[ConsumerGroups]
(
 [ConsumerGroupID] int NOT NULL ,
 [EnterpriseID]    int NOT NULL ,
 [Name]            nvarchar(100) NOT NULL ,

 CONSTRAINT [PK_ConsumerGroups] PRIMARY KEY CLUSTERED ([ConsumerGroupID] ASC),
 CONSTRAINT [FK_ConsumerGroups_Enterprises] FOREIGN KEY ([EnterpriseID])  REFERENCES [Application].[Enterprises]([EnterpriseID])
);
GO

CREATE NONCLUSTERED INDEX [IX_ConsumerGroups_Enterprises] ON [Application].[ConsumerGroups] 
 (
  [EnterpriseID] ASC
 )

GO


-- Устройства-потребители электроэнергии
CREATE TABLE [Application].[Consumers]
(
 [ConsumerID]      int NOT NULL ,
 [ConsumerGroupID] int NOT NULL ,
 [Name]            nvarchar(100) NOT NULL ,
 [SensorName]      varchar(50) NOT NULL ,
 [LastUpdateAt]    datetime2(7) NULL , -- пока нам не приходило данных от счётчиков может быть пустым

 CONSTRAINT [PK_Consumers] PRIMARY KEY CLUSTERED ([ConsumerID] ASC),
 CONSTRAINT [FK_Consumers_ConsumerGroups] FOREIGN KEY ([ConsumerGroupID])  REFERENCES [Application].[ConsumerGroups]([ConsumerGroupID]),
 CONSTRAINT [UQ_Consumers_SensorName] UNIQUE ([SensorName])
);
GO

CREATE NONCLUSTERED INDEX [IX_Consumers_ConsumerGroups] ON [Application].[Consumers] 
 (
  [ConsumerGroupID] ASC
 )

GO


-- Показания счётчиков электроэнергии
CREATE TABLE [Application].[SensorData]
(
 [SensorDataID]  bigint NOT NULL ,
 [ConsumerID]    int NOT NULL ,
 [PeriodStart]   datetime2(7) NOT NULL ,
 [PeriodEnd]     datetime2(7) NOT NULL ,
 [PowerConsumed] decimal(18,4) NOT NULL ,


 CONSTRAINT [PK_SensorData] PRIMARY KEY CLUSTERED ([SensorDataID] ASC),
 CONSTRAINT [FK_SensorData_Consumers] FOREIGN KEY ([ConsumerID])  REFERENCES [Application].[Consumers]([ConsumerID])
);
GO

CREATE NONCLUSTERED INDEX [IX_SensorData_Consumers] ON [Application].[SensorData] 
 (
  [ConsumerID] ASC
 )
-- Может часто использоваться для фильтрации, поэтому добавим индекс
CREATE NONCLUSTERED INDEX [IX_SensorData_PeriodStart] ON [Application].[SensorData] 
 (
  [PeriodStart] ASC
 )
GO


-- Комментарии пользователей
CREATE TABLE [Application].[Comments]
(
 [CommentID]    int NOT NULL ,
 [EnterpriseID] int NOT NULL ,
 [Author]       nvarchar(100) NOT NULL ,
 [Text]         nvarchar(max) NOT NULL ,
 [ForDate]      date NOT NULL ,


 CONSTRAINT [PK_Comments] PRIMARY KEY CLUSTERED ([CommentID] ASC),
 CONSTRAINT [FK_Comments_Enterprises] FOREIGN KEY ([EnterpriseID])  REFERENCES [Application].[Enterprises]([EnterpriseID])
);
GO

CREATE NONCLUSTERED INDEX [IX_Comments_Enterprises] ON [Application].[Comments] 
 (
  [EnterpriseID] ASC
 )

GO

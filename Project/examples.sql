USE [PowerOptimization]
GO


-- Потребление электроэнергии на предприятии за определённый промежуток времени (сутки)
SELECT 
	sd.PeriodStart,
	sd.PeriodEnd,
	sd.PowerConsumed,
	c.Name,
	cg.Name
FROM Application.Enterprises AS e
JOIN Application.ConsumerGroups AS cg ON e.EnterpriseID = cg.EnterpriseID
JOIN Application.Consumers AS c ON cg.ConsumerGroupID = c.ConsumerGroupID
LEFT JOIN Application.SensorData AS sd 
	ON c.ConsumerID = sd.ConsumerID AND 
	   sd.PeriodStart BETWEEN '2022-03-04 00:00:00' AND '2022-03-04 23:59:59'
WHERE e.Name = N'Шахта Восточная'
ORDER BY cg.ConsumerGroupID, c.ConsumerID, sd.PeriodStart


GO
-- Предположительные часы пиковой нагрузки для предприятия в месяце
CREATE FUNCTION Application.SupPeakHoursForEnterprise(@EnterpriseName nvarchar(50), @Month int)
RETURNS TABLE
AS
RETURN (
	SELECT Hour FROM Application.SupposedPeakHours AS sph
	JOIN Application.Enterprises AS e ON sph.TerritoryID = e.TerritoryID
	WHERE e.Name = @EnterpriseName AND sph.Month = @Month
)
GO

-- Среднее ежедневное потребление электроэнергии предприятием в месяце
CREATE FUNCTION Application.AvgDailyConsumption(@EnterpriseName nvarchar(50), @Month int)
RETURNS TABLE
AS
RETURN (
	SELECT
		DAY(sd.PeriodStart) AS DayNumber,
		AVG(sd.PowerConsumed) AS TotalConsumed
	FROM Application.Enterprises AS e
	JOIN Application.ConsumerGroups AS cg ON e.EnterpriseID = cg.EnterpriseID
	JOIN Application.Consumers AS c ON cg.ConsumerGroupID = c.ConsumerGroupID
	LEFT JOIN Application.SensorData AS sd
		ON c.ConsumerID = sd.ConsumerID AND MONTH(sd.PeriodStart) = @Month
	WHERE e.Name = @EnterpriseName
	GROUP BY DAY(sd.PeriodStart)
)
GO

-- Среднее ежедневное потребление электроэнергии предприятием в месяце в часы пиковой нагрузки
CREATE FUNCTION Application.AvgDailyConsumptionInPeaks(@EnterpriseName nvarchar(50), @Month int)
RETURNS TABLE
AS
RETURN (
	SELECT
		DAY(sd.PeriodStart) AS DayNumber,
		AVG(sd.PowerConsumed) AS TotalConsumedInPeak
	FROM Application.Enterprises AS e
	JOIN Application.ConsumerGroups AS cg ON e.EnterpriseID = cg.EnterpriseID
	JOIN Application.Consumers AS c ON cg.ConsumerGroupID = c.ConsumerGroupID
	LEFT JOIN Application.SensorData AS sd
		ON c.ConsumerID = sd.ConsumerID AND MONTH(sd.PeriodStart) = 3
	WHERE e.Name = @EnterpriseName AND
		  DATEPART(hour, sd.PeriodStart) IN (
			SELECT * FROM Application.SupPeakHoursForEnterprise(@EnterpriseName, @Month)
		  )
	GROUP BY DAY(sd.PeriodStart)
)
GO

-- Разница между средним потреблением за сутки и постреблением в пиковые часы
-- Чем больше, тем больше экономия
SELECT
	adc.DayNumber,
	adc.TotalConsumed,
	adcp.TotalConsumedInPeak,
	adc.TotalConsumed - adcp.TotalConsumedInPeak AS TotalDifference,
	c.Author,
	c.Text
FROM Application.AvgDailyConsumption(N'Завод Северный', 3) AS adc
JOIN Application.AvgDailyConsumptionInPeaks(N'Завод Северный', 3) AS adcp ON adc.DayNumber = adcp.DayNumber
LEFT JOIN Application.Comments AS c ON adc.DayNumber = DAY(c.ForDate) AND c.EnterpriseID = 1


SELECT
	adc.DayNumber,
	adc.TotalConsumed,
	adcp.TotalConsumedInPeak,
	adc.TotalConsumed - adcp.TotalConsumedInPeak AS TotalDifference,
	c.Author,
	c.Text
FROM Application.AvgDailyConsumption(N'Шахта Восточная', 3) AS adc
JOIN Application.AvgDailyConsumptionInPeaks(N'Шахта Восточная', 3) AS adcp ON adc.DayNumber = adcp.DayNumber
LEFT JOIN Application.Comments AS c ON adc.DayNumber = DAY(c.ForDate) AND c.EnterpriseID = 2

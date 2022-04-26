USE [PowerOptimization]
GO


-- Потребление электроэнергии на предприятии за определённый промежуток времени (в предполагаемые часы пиковой нагрузки)
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
	   sd.PeriodStart BETWEEN '2022-03-04 20:00:00' AND '2022-03-04 21:30:00'
WHERE e.Name = N'Шахта Восточная'
ORDER BY cg.ConsumerGroupID, c.ConsumerID, sd.PeriodStart

declare @from date = '2020-09-01'
declare @to date = '2021-01-31'


	select Aniomes, CAST( cast((COUNT(SpoolRechazados) * 100.0 ) as decimal) / COUNT(SPOOLID) AS numeric ) AS PaintQualityLevel
	from (
		SELECT C.SpoolID, FechaLiberadoPintura 
		,cast( cast(year(FechaLiberadoPintura) as nvarchar) +'-'+ cast(month(FechaLiberadoPintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes,
		D.SPOOLID as SpoolRechazados
		FROM WorkstatusSpool A
		INNER JOIN ORDENTRABAJOSPOOL B ON A.OrdenTrabajoSpoolID = B.OrdenTrabajoSpoolID and a.FechaLiberadoPintura is not null
		INNER JOIN SPOOL C ON B.SpoolID= C.SpoolID 
		LEFT JOIN SAM3.[STEELGO-SAM3].DBO.Sam3_Pintura_RechazoPintura D ON C.SpoolID = D.SPOOLID AND (D.ACTIVO=1 OR  D.HISTORICO=1) 
	)X WHERE FechaLiberadoPintura >= @from AND FechaLiberadoPintura <= @to group by Aniomes order by Aniomes
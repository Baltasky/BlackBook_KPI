declare @from date = '2020-09-01'
declare @to date = '2021-01-31'

create table #fechasOtEntrega
(
	spoolid int,
	fechaotentrega date
)

create table #fechaembarque 
(
	spoolid int,
	FechaEmbarque date,
	AnioMes date
)


create table #CicloOperaciones
(
	AnioMes date,
	CicloOperacion int,
	spooldormidos int
)


insert into #fechasOtEntrega (spoolid, fechaotentrega)
	select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
	from SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a with(nolock)
	inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
	INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
	INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
	inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	inner join Spool f with(nolock) on f.SpoolID = e.SpoolID
	where B.ZonaID=3031 group by e.SpoolID


insert into #fechaembarque (spoolid, FechaEmbarque, AnioMes)
select spoolid,   FechaEmbarque  , aniomes
from(
select spoolid, FechaEmbarque, aniomes  from (
	select A.spoolid
	, CONVERT(date, e.fechaenvio) as FechaEmbarque
	, cast( cast(year(e.fechaenvio) as nvarchar) +'-'+ cast(month(e.fechaenvio) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
	from spool A
	inner join OrdenTrabajospool B on A.SpoolID= B.SpoolID and a.campo7 != 'GRANEL' and a.campo7 != 'IWS' and a.campo7 != 'SOPORTE' 
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_DetalleCarga_Plana] C with(nolock) on a.spoolid = c.spoolid and (c.activo=1 or c.revisado=1)
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_Detalle] D  with(nolock) on d.CargaPlanaID = c.CargaPlanaID and d.activo=1
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_CapturaEnvio] E with(nolock) on e.EmbarqueID=d.EmbarqueID 
)x  where FechaEmbarque >= @FROM AND FechaEmbarque <= @TO 
) y


insert into #CicloOperaciones (AnioMes, CicloOperacion, spooldormidos)
select AnioMes
, cast( cast(sum(diferencia) as decimal) / count(spoolid) as numeric) AS CicloOperacion, sum(spooldormidos) from (
	SELECT  *
	, case when diferencia > 30 then 1 else 0 end as spooldormidos 
	FROM (
		select a.spoolid, datediff(day, fechaotentrega, FechaEmbarque) as diferencia, AnioMes  
		from #fechaembarque a with(nolock)
		left join #fechasOtEntrega b with(nolock) on a.spoolid = b.spoolid
		where fechaotentrega is not null   
	)XY 
)xyz group by AnioMes  order by aniomes

select * from #CicloOperaciones order by AnioMes asc

drop table #fechasOtEntrega
drop table #fechaembarque
drop table #CicloOperaciones
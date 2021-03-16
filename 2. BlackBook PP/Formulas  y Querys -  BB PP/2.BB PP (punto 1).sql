declare @from date = '2020-09-01'
declare @to date = '2021-02-28'

create table #fechaembarque 
(
	spoolid int,
	FechaEmbarque date,
	AnioMes date
)

insert into #fechaembarque (spoolid, FechaEmbarque, AnioMes)
select spoolid,   FechaEmbarque  , aniomes
from(
select spoolid, FechaEmbarque, aniomes  from (
	select A.spoolid
	,CONVERT(date, e.fechaenvio) as FechaEmbarque
	,cast( cast(year(e.fechaenvio) as nvarchar) +'-'+ cast(month(e.fechaenvio) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
	from spool A
	inner join OrdenTrabajospool B on A.SpoolID= B.SpoolID and a.campo7 != 'GRANEL' and a.campo7 != 'IWS' and a.campo7 != 'SOPORTE' 
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_DetalleCarga_Plana] C with(nolock) on a.spoolid = c.spoolid and (c.activo=1 or c.revisado=1)
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_Detalle] D  with(nolock) on d.CargaPlanaID = c.CargaPlanaID and d.activo=1
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_CapturaEnvio] E with(nolock) on e.EmbarqueID=d.EmbarqueID 
)x  where FechaEmbarque >= @FROM AND FechaEmbarque <= @TO 
) y


select aniomes,  cast( cast((sum(entregados) * 100.0 )as decimal) / count(spoolid) as numeric) as cumplimientoPortafo
from (
		select *
		 ,case when fechaembarque <= fechaplanembarque then 1 else 0 end as entregados
		from (
			select  a.AnioMes, a.spoolid, b.FechaPlanEmbarque, a.FechaEmbarque from #fechaembarque a
			left join PlanPorSpool b on a.spoolid = b.SpoolID
		) x
) y group by AnioMes order by aniomes


drop table #fechaembarque



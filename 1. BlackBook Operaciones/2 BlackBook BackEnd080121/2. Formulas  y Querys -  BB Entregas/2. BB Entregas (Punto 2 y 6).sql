declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';



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
	, CONVERT(date, e.fechaenvio) as FechaEmbarque, cast( cast(year(e.fechaenvio) as nvarchar) +'-'+ cast(month(e.fechaenvio) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
	from spool A
	inner join OrdenTrabajospool B on A.SpoolID= B.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_DetalleCarga_Plana] C with(nolock) on a.spoolid = c.spoolid and (c.activo=1 or c.revisado=1)
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_Detalle] D  with(nolock) on d.CargaPlanaID = c.CargaPlanaID and d.activo=1
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_CapturaEnvio] E with(nolock) on e.EmbarqueID=d.EmbarqueID 
)x  where FechaEmbarque >= @FROM AND FechaEmbarque <= @TO 
) y


select aniomes,
  sum(diferencias)/count(spoolid) as CicloEntrega2, sum(SpoolDormidos) as spooldormidos6
from (
	select  *,
	case when diferencias > 9 then 1 else 0 end as SpoolDormidos
	from(
		select a.aniomes, a.spoolid, datediff(day,b.fechaAutorizacion, a.fechaembarque ) as diferencias
		from #fechaembarque a with(nolock)
		inner join Shop_AutorizacionSI b with(nolock) on a.spoolid=b.spoolid 
	)x
)y group by AnioMes order by AnioMes


drop table #fechaembarque
declare   @from date = '2020-09-01';
declare   @to date = '2021-01-31';


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
	inner join OrdenTrabajospool B on A.SpoolID= B.SpoolID and a.campo7 != 'GRANEL' and a.campo7 != 'IWS' and a.campo7 != 'SOPORTE' 
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_DetalleCarga_Plana] C with(nolock) on a.spoolid = c.spoolid and (c.activo=1 or c.revisado=1)
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_Detalle] D  with(nolock) on d.CargaPlanaID = c.CargaPlanaID and d.activo=1
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_CapturaEnvio] E with(nolock) on e.EmbarqueID=d.EmbarqueID 
)x  where FechaEmbarque >= @FROM AND FechaEmbarque <= @TO 
) y

select aniomes, sum(diferencia)/count(spoolid) as CiclodeBackEnd ,  sum(diferencias) spooldormidos
 from(
	select spoolid, aniomes, diferencia
	 ,case when diferencia > 18 then 1 else 0 end as diferencias 
	from (
		select a.spoolid, datediff(day,  b.FechaTransferenciaPintura, a.FechaEmbarque) as diferencia 
		, cast( cast(year(FechaEmbarque) as nvarchar) +'-'+ cast(month(FechaEmbarque) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
		from #fechaembarque a with(nolock)
		inner join spool b with(nolock) on a.spoolid = b.SpoolID and b.campo7 != 'GRANEL' and b.campo7 != 'IWS' and b.campo7 != 'SOPORTE' 
		where FechaTransferenciaPintura is not null
	)x 
)y group by Aniomes order by Aniomes

drop table #fechaembarque
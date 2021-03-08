declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';


create table #fechaembarque 
(
	spoolid int,
	FechaEmbarque date,
	AnioMes date
)

create table #CicloBackEnd
(	
	Aniomes date,
	CicloBackEnd int,
	SpooldormidosBE int
)

create table #CalidadPintura
(
   aniomes date,
   PaintQualityLevel int
)

create table #TonsXembarque
(
	aniomes date,
	tonsXembarque decimal(5,1)
)

create table #portafolio
(
	aniomes date,
	cumplimiento int
)

create table #CicloEntrega1
(
	aniomes date,
	CicloEntrega1 int
)

create table #cicloentrega2
(
	aniomes date,
	cicloentrega2 int,
	spooldormidosEntregas int
)

create table #CicloPintura
(	
	aniomes date,
	ciclopintura int,
	spooldormidosPintura int
)


insert into #fechaembarque (spoolid, FechaEmbarque, AnioMes)
select spoolid,   FechaEmbarque  , aniomes
from(
select spoolid, FechaEmbarque, aniomes  from (
	select A.spoolid
	, CONVERT(date, e.fechaenvio) as FechaEmbarque, cast( cast(year(e.fechaenvio) as nvarchar) +'-'+ cast(month(e.fechaenvio) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
	from spool A with(nolock)
	inner join OrdenTrabajospool B on A.SpoolID= B.SpoolID and a.campo7 != 'GRANEL' and a.campo7 != 'IWS' and a.campo7 != 'SOPORTE' 
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_DetalleCarga_Plana] C with(nolock) on a.spoolid = c.spoolid and (c.activo=1 or c.revisado=1)
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_Detalle] D  with(nolock) on d.CargaPlanaID = c.CargaPlanaID and d.activo=1
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_CapturaEnvio] E with(nolock) on e.EmbarqueID=d.EmbarqueID 
)x  where FechaEmbarque >= @FROM AND FechaEmbarque <= @TO 
) y

insert into #CicloBackEnd(Aniomes, CicloBackEnd, SpooldormidosBE)
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
)y group by Aniomes 

insert into #CalidadPintura (aniomes, PaintQualityLevel)
select Aniomes, CAST( cast((COUNT(SpoolRechazados) * 100.0 ) as decimal) / COUNT(SPOOLID) AS numeric ) AS PaintQualityLevel
	from (
		SELECT C.SpoolID, FechaLiberadoPintura, 
		cast( cast(year(FechaLiberadoPintura) as nvarchar) +'-'+ cast(month(FechaLiberadoPintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes,
		D.SPOOLID as SpoolRechazados
		FROM WorkstatusSpool A with(nolock)
		INNER JOIN ORDENTRABAJOSPOOL B with(nolock) ON A.OrdenTrabajoSpoolID = B.OrdenTrabajoSpoolID and a.FechaLiberadoPintura is not null
		INNER JOIN SPOOL C with(nolock) ON B.SpoolID= C.SpoolID 
		LEFT JOIN SAM3.[STEELGO-SAM3].DBO.Sam3_Pintura_RechazoPintura D with(nolock) ON C.SpoolID = D.SPOOLID AND (D.ACTIVO=1 OR  D.HISTORICO=1) 
	)X WHERE FechaLiberadoPintura >= @from AND FechaLiberadoPintura <= @to group by Aniomes

insert into #TonsXembarque(aniomes, tonsXembarque)
select aniomes,  cast(sum (tons)/count(numeroembarque) as decimal(5,1)) as TonsXplana
from  (
	SELECT numeroembarque, tons
	,cast( cast(year(fechaenvio ) as nvarchar) +'-'+ cast(month(fechaenvio ) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from (
		select numeroembarque, fechaenvio, sum(ton)  as Tons from (
			select numeroembarque, d.fechaenvio, (a.peso / 1000) as Ton
			from  spool a with(nolock)
			inner join [sam3].[steelgo-sam3].dbo.sam3_Embarque_detallecarga_plana b with(nolock) on a.spoolid= b.spoolid and (b.activo =1 or b.revisado=1) 
			and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
			inner join [sam3].[steelgo-sam3].dbo.sam3_Embarque_detalle c with(nolock) on b.cargaplanaid = c.cargaplanaid and c.activo=1
			inner join [sam3].[steelgo-sam3].dbo.sam3_Embarque_CapturaEnvio d  with(nolock) on c.Embarqueid= d.embarqueid 
		) x  group by numeroembarque, fechaenvio
	)y where fechaenvio >=@from AND fechaenvio <=@to
)z group by aniomes

insert into #portafolio (aniomes, cumplimiento)
select aniomes,  cast( cast((sum(entregados) * 100.0 )as decimal) / count(spoolid) as numeric) as cumplimiento
from (
		select *
		 ,case when fechaembarque <= fechaplanembarque then 1 else 0 end as entregados
		from (
			select  a.AnioMes, a.spoolid, b.FechaPlanEmbarque, a.FechaEmbarque 
			from #fechaembarque a with(nolock)
			left join PlanPorSpool b with(nolock) on a.spoolid = b.SpoolID
		) x
) y group by AnioMes 

insert into #CicloEntrega1(aniomes,CicloEntrega1)
select aniomes,  sum(diferencias) / count(spoolid) from (
	select a.spoolid, b.FechaAutorizacion, a.okcalidadcliente, datediff(day,  b.FechaAutorizacion, a.okcalidadcliente)as  diferencias
	,cast( cast(year(a.okcalidadcliente ) as nvarchar) +'-'+ cast(month(a.okcalidadcliente ) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from spool a
	inner join Shop_AutorizacionSI b on a.spoolid= b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
	where a.okcalidadcliente  >= @FROM AND a.okcalidadcliente  <= @TO 
) x group by aniomes

insert into #cicloentrega2(aniomes, cicloentrega2, spooldormidosEntregas)
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
)y group by AnioMes 

insert into #CicloPintura(aniomes, ciclopintura, spooldormidosPintura)
select aniomes, sum(diferentes) / count(spoolid) as CicloPintura, sum(spooldormidos) as SpooldormidosPintura
from(
	select *
		,case when diferentes > 9 then 1 else 0 end as spooldormidos
		from (
			select a.spoolid, datediff(day,FechaTransferenciaPintura,FechaLiberadoPintura) as diferentes
			,cast( cast(year(FechaLiberadoPintura) as nvarchar) +'-'+ cast(month(FechaLiberadoPintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
			from spool a
			inner join OrdenTrabajoSpool b on a.SpoolID = b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
			inner join WorkstatusSpool c on b.OrdenTrabajoSpoolID = c.OrdenTrabajoSpoolID 
			where FechaLiberadoPintura >=@from and FechaLiberadoPintura <=@to
	)x
)y group by Aniomes

-------------------------------------------------------
select A.Aniomes, a.CicloBackEnd, A.SpooldormidosBE, b.PaintQualityLevel, c.tonsXembarque, d.cumplimiento, e.CicloEntrega1
,f.cicloentrega2, f.spooldormidosEntregas, g.ciclopintura, g.spooldormidosPintura
from #CicloBackEnd a with(nolock)
inner join #CalidadPintura b with(nolock) on a.Aniomes=b.aniomes
inner join #TonsXembarque c with(nolock) on a.Aniomes= c.aniomes
inner join #portafolio d on a.Aniomes=d.aniomes
inner join #CicloEntrega1 e on a.Aniomes=e.aniomes
inner join #cicloentrega2 f on a.Aniomes=f.aniomes
inner join #CicloPintura g on a.Aniomes=g.aniomes
order by a.AnioMes desc



drop table #fechaembarque
drop table #CicloBackEnd
drop table #CalidadPintura
drop table #TonsXembarque
drop table #portafolio
drop table #CicloEntrega1
drop table #cicloentrega2
drop table #CicloPintura
declare @from date = '2020-09-01'
declare @to date = '2021-02-28'

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

create table #cumplimientoPrograma
(
	aniomes date,
	Cumplimientoprograma int
)

create table #cumplimientoCicloProdrution
(
	aniomes date,
	CumplimientoCiclo int
)

create table #cumplimientoReservado
(
	aniomes date,
	cumplimientoReservado int
)

create table #fechasOtReal
(
	spoolid int,
	fechaotentrega date
)


create table #CumplimientoProgramacion
(
	aniomes date,
	CumplimientoProgramacion int
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

insert into #cumplimientoPrograma(aniomes, Cumplimientoprograma)
select aniomes,  cast( cast((sum(entregados) * 100.0 )as decimal) / count(spoolid) as numeric) as cumplimientoPortafo
from (
		select *
		 ,case when fechaembarque <= fechaplanembarque then 1 else 0 end as entregados
		from (
			select  a.AnioMes, a.spoolid, b.FechaPlanEmbarque, a.FechaEmbarque 
			from #fechaembarque a with(nolock)
			left join PlanPorSpool b with(nolock) on a.spoolid = b.SpoolID
		) x
) y group by AnioMes 

insert into #fechasOtEntrega (spoolid, fechaotentrega)
	select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
	from SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a with(nolock)
	inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
	INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
	INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
	inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	where B.ZonaID=3031 group by e.SpoolID

insert into #cumplimientoCicloProdrution(aniomes, CumplimientoCiclo)
select  AnioMes,  sum(diferentes)/count(spoolid)as CumplimientoCicloProduccion from (
		select  a.spoolid, AnioMes , datediff(day, fechaotentrega, FechaEmbarque) as diferentes
		from #fechaembarque a with(nolock)
		inner join #fechasOtEntrega b with(nolock) on a.spoolid=  b.spoolid
) x group by aniomes order by AnioMes

insert into #cumplimientoReservado(aniomes, cumplimientoReservado)
select aniomes, ( sum(ReservadoMaterial) * 100.0) / sum(FabConfirmado) as CumplimientoReservado from (
	select aniomes
	,case when FechaFabricableConfirmado is not null then 1 else 0 end as FabConfirmado
	,case when FechaReservaMaterial is not null then 1 else 0 end as ReservadoMaterial
	from (
		select  a.FechaFabricableConfirmado, b.FechaReservaMaterial 	
		,cast( cast(year(a.FechaFabricableConfirmado) as nvarchar) +'-'+ cast(month(a.FechaFabricableConfirmado) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
		from spool a with(nolock)
		left join OrdenTrabajospool b with(nolock) on a.SpoolID=b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
		where a.FechaFabricableConfirmado >=@from and a.FechaFabricableConfirmado<=@to 
	) x
)y group by  aniomes order by aniomes


insert into #fechasOtReal (spoolid, fechaotentrega)
		select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
		from SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a with(nolock)
		inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
		INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
		INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
		inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	    where B.ZonaID=3031 group by e.SpoolID

insert into #CumplimientoProgramacion(aniomes, CumplimientoProgramacion)
select aniomes, (sum(diferencia) * 100.0)/ COUNT(aniomes) from (
	select  aniomes
	, case when fechaotentrega <= FechaPlanEmision  then 1 else 0 end as diferencia
	from (
		select a.spoolid, FechaPlanEmision, fechaotentrega 
		,cast( cast(year(fechaotentrega) as nvarchar) +'-'+ cast(month(fechaotentrega) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
		from spool a with(nolock) 
		inner join #fechasOtReal b  with(nolock)  on a.spoolid =b.SpoolID
		left join PlanPorSpool c with(nolock)  on b.spoolid =c.SpoolID
		where  fechaotentrega >=@from and fechaotentrega<=@to
		and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
	)x
)y group by aniomes
----------------------------------------------------
select a.aniomes, a.Cumplimientoprograma, b.CumplimientoCiclo, c.cumplimientoReservado, d.CumplimientoProgramacion
from #cumplimientoPrograma a with(nolock)
inner join #cumplimientoCicloProdrution b with(nolock)on a.aniomes =b.aniomes
left join #cumplimientoReservado c with(nolock) on a.aniomes = c.aniomes
inner join #CumplimientoProgramacion d with(nolock) on a.aniomes= d.aniomes
order by aniomes



drop table #fechaembarque
drop table #cumplimientoPrograma
drop table #fechasOtEntrega
drop table #cumplimientoCicloProdrution
drop table #cumplimientoreservado
drop table #fechasOtReal
drop table #CumplimientoProgramacion
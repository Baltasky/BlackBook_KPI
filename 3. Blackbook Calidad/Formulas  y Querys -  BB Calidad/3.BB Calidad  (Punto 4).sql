declare @from date = '2020-09-01'
declare @to date = '2021-02-28'


create table #spoolrechazadosdimencional
(
	spoolid int,
	spoolrechazadodimencional bit,
	aniomes date
)

create table #spoolrechazadosvisual
(
	spoolid int,
	spoolrechazadovisual bit,
	aniomes date
)

create table #rechazosVisualDimencional
(
	spoolid int ,
	rechazadoDimencional int,
	rechazadoVisual int,
	spoolsRechazados int,
	aniomes date
)

create table #CalidadSpoolInspeccionados
(
	aniomes date,
	CalidadSpoolInspeccionados int
)

--------------------------------------------------------------------------dimencional
insert into #spoolrechazadosdimencional(spoolid, spoolrechazadodimencional, aniomes)
select spoolid,  SpoolrechaazadoDimencional
	,cast( cast(year(fechainspecciondimencional) as nvarchar) +'-'+ cast(month(fechainspecciondimencional) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes

from (
	select spoolid, sum(inspeccinrechazada) SpoolrechaazadoDimencional, MAX( convert(date, fechainspeccion ) ) as fechainspecciondimencional
	from (
		select spoolid, fechainspeccion
		,case when resultadoid = 2 then 1 else 0 end as inspeccinrechazada 
		from (
			select a.spoolid,  convert(date,c.fechainspeccion) as fechainspeccion ,  c.inspecciondimensionalid, c.resultadoid  
			from spool a with(nolock)
			left join OrdenTrabajospool b with(nolock) on  a.SpoolID = b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
			left join sam3.[steelgo-sam3].dbo.Sam3_InspeccionDimensional c with(nolock) on b.OrdenTrabajoSpoolID = c.ordentrabajospoolid 
		) x where inspecciondimensionalid is not null and FechaInspeccion >= @from and FechaInspeccion<= @to
	)y group by SpoolID
)z 

------------------------------------------------------------------------------visual
insert into #spoolrechazadosvisual(spoolid, spoolrechazadovisual, aniomes)
select spoolid
,case when  rechazos > 0 then 1 else 0 end as SpoolRechazadoVisual
	,cast( cast(year(FechaInspeccionvisual) as nvarchar) +'-'+ cast(month(FechaInspeccionvisual) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	
	from (
		select spoolid, sum(TieneRechazos) as Rechazos, MAX( convert(date, fechainspeccion ) )  as FechaInspeccionvisual
		from (
			select spoolid
			,case when resultadoid= 2 then 1 else 0 end as TieneRechazos
			,fechainspeccion
			from (	
				select a.SpoolID, c.resultadoid, Defectoid, c.fechainspeccion 
				from spool a with(nolock)
				inner join OrdenTrabajospool b  with(nolock) on a.spoolid=b.spoolid and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
				inner join JuntaWorkstatus d with(nolock) on  d.OrdenTrabajoSpoolID = b.OrdenTrabajoSpoolID
				inner join sam3.[steelgo-sam3].dbo.sam3_inspeccionVisual c with(nolock) on d.JuntaWorkstatusID = c.JuntaWorkstatusID and (c.activo=1 or c.historico=1)
			)x where FechaInspeccion >= @from and FechaInspeccion<= @to
		)y group by spoolid 
	)z  


insert into #rechazosVisualDimencional(spoolid, rechazadoDimencional, rechazadoVisual, spoolsRechazados, aniomes) 
select 
case when a.spoolid is null then b.spoolid else a.spoolid end spoolid
, spoolrechazadodimencional, B.spoolrechazadovisual
,case when  (spoolrechazadodimencional = 1 or  spoolrechazadovisual=1) then 1 else 0 end as SpoolRechazado
,case when a.aniomes is null  then b.aniomes else a.aniomes end aniomes
from #spoolrechazadosdimencional a with(nolock)
left join #spoolrechazadosvisual b  with(nolock) on a.spoolid=b.spoolid and a.aniomes= b.aniomes

insert into #CalidadSpoolInspeccionados(aniomes, CalidadSpoolInspeccionados)
select  aniomes, cast((sum(spoolsRechazados)*100.0)  /  count(spoolid) as numeric)  as CalidadSpoolInspeccionados
from #rechazosVisualDimencional with(nolock)
group by aniomes order by aniomes


select * from #CalidadSpoolInspeccionados

drop table #spoolrechazadosdimencional
drop table #spoolrechazadosvisual
drop table #rechazosVisualDimencional
drop table #CalidadSpoolInspeccionados
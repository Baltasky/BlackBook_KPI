declare @from date = '2020-09-01'
declare @to date = '2021-01-31'

create table #CalidadSoldadura
(
	aniomes date,
	CalidadSoldadura int
)

create table #CalidadPintura
(
	aniomes date,
	CalidadPintura int
)

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


create table #FechaInspeccionDimencional
(
	spoolid int,
	FechaInspeccionDimencional date
)

create table #UltimaFechaSoldadura
(
	spoolid int,
	UltimaFechaSoldadura date
)


Create table #Visual
		(
			SpoolId int,
			Visual int
		)

create table #NivelInspeccionFab
(	
	aniomes date,
	NivelInspeccionFab float
)

create table #InspeccionFinal
(
	aniomes date,
	InspeccionFinal int
)

insert into #CalidadSoldadura (aniomes,CalidadSoldadura)
		select    aniomes
		, cast ( cast( (sum(reachazadas) * 100.0 ) as decimal) / COUNT(JuntaWorkstatusID) as numeric) as WelddingQualetyLevel  
			from (
				select b.JuntaWorkstatusID, convert (date,c.fechaprueba  ) as FechaPrueba
				,cast( cast(year(FechaPrueba) as nvarchar) +'-'+ cast(month(FechaPrueba) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
				,case when Aprobado = 0 then 1 else 0 end reachazadas
					from OrdenTrabajospool a
					inner join JuntaWorkstatus b with(nolock) on a.OrdenTrabajoSpoolID = b.OrdenTrabajoSpoolID
					inner join JuntaReportePnd c with(nolock) on b.JuntaWorkstatusID = c.JuntaWorkstatusID
					inner join ReportePnd d with(nolock) on c.ReportePndID = d.ReportePndID
					inner join JuntaRequisicion e with(nolock) on c.JuntaRequisicionID = e.JuntaRequisicionID
					inner join TipoPrueba g with(nolock) on d.TipoPruebaID = g.TipoPruebaID
					WHERE  g.TipoPruebaID IN (1,5) 
		) x where fechaprueba >= @FROM AND fechaprueba <= @TO  group by aniomes 

insert into #CalidadPintura(aniomes,  CalidadPintura)
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


insert into #UltimaFechaSoldadura(spoolid, UltimaFechaSoldadura)
select * from (
	select spoolid, max( convert(date,FechaSoldadura))as UltimaFechaSoldadura from(
		select a.spoolid, FechaSoldadura 
		from spool a  with(nolock)
		inner join OrdenTrabajospool b  with(nolock) on a.SpoolID=b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null) 
		inner join juntaworkstatus c  with(nolock) on b.OrdenTrabajoSpoolID = c.OrdenTrabajoSpoolID and c.JuntaFinal=1 
		left  join JuntaSoldadura d  with(nolock) on c.JuntaWorkstatusID = d.JuntaWorkstatusID
	)x group by spoolid
)y where UltimaFechaSoldadura>=  @from and  UltimaFechaSoldadura <= @to

-----------------------------------------------------------visual
		insert into #Visual
		select s.SpoolID 
			,case when count(js.juntaspoolid)=0 then 1 
					when count(jw.juntaspoolid)=count(iv.juntaspoolid) then 1 else 0 end as Resultado
		from spool s with(nolock)
		left join JuntaSpool js with(nolock) on js.SpoolID=s.SpoolID and js.FabAreaID=1  and (s.campo7 not in ('GRANEL','SOPORTE','IWS') or s.campo7 is null)
		left join JuntaWorkstatus jw with(nolock) on jw.JuntaSpoolID=js.JuntaSpoolID and js.Etiqueta=jw.EtiquetaJunta 
		left join sam3.[steelgo-sam3].dbo.sam3_inspeccionvisual iv with(nolock) on iv.JuntaWorkstatusID=jw.JuntaWorkstatusID and iv.resultadoid=1 and iv.activo=1
		group by s.SpoolID

---------------------------------------------------------fechadimencional

insert into #FechaInspeccionDimencional (spoolid, FechaInspeccionDimencional)
select spoolid,fechainspecciondimencional
from (
	select spoolid, MAX( convert(date, fechainspeccion ) ) as fechainspecciondimencional
	from (
		select spoolid, fechainspeccion
		from (
			select a.spoolid,  convert(date,c.fechainspeccion) as fechainspeccion ,  c.inspecciondimensionalid, c.resultadoid  
			from spool a with(nolock)
			inner  join OrdenTrabajospool b with(nolock) on  a.SpoolID = b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
			left join sam3.[steelgo-sam3].dbo.Sam3_InspeccionDimensional c with(nolock) on b.OrdenTrabajoSpoolID = c.ordentrabajospoolid 
			where (c.activo=1 or c.defectoid is not null)
		) x where inspecciondimensionalid is not null  
	)y group by SpoolID
)z  


insert into #NivelInspeccionFab(aniomes, NivelInspeccionFab)
select aniomes, cast((sum(cumple) * 100.0)/ count(spoolid) as decimal(5,2)) as NivelInspeccionFab from (
	select spoolid, 
	 case when (ultimoDiaMes >= FechaInspeccionDimencional) and (visual=1 and FechaInspeccionDimencional  is not null)  then 1 else 0 end as Cumple
	,aniomes
	from(
			select a.spoolid, UltimaFechaSoldadura, Visual, FechaInspeccionDimencional
			 , convert(date, DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0, UltimaFechaSoldadura)+1,0))) as ultimoDiaMes
			,cast( cast(year(UltimaFechaSoldadura) as nvarchar) +'-'+ cast(month(UltimaFechaSoldadura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
			from #UltimaFechaSoldadura a with(nolock)
			left join #Visual b with(nolock) on a.spoolid = b.SpoolId
			left join #FechaInspeccionDimencional c with(nolock)  on a.spoolid = c.spoolid	
	)x 	
)y group by aniomes  


insert into #InspeccionFinal(aniomes, InspeccionFinal)
select aniomes, cast( sum(cumple) *100.0/ COUNT(SpoolID)  as numeric) as InspeccionFinal from (
	select spoolid , aniomes,
	case when FechaTigger is not null and  FechaTigger <=ultimoDiaMes then 1 else 0 end as Cumple
	from (
		select x.spoolid, FechaLiberadoPintura,  convert(date,FechaAutorizacion) as FechaTigger ,
		convert(date, DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0, FechaLiberadoPintura)+1,0))) as ultimoDiaMes
		,cast( cast(year(FechaLiberadoPintura) as nvarchar) +'-'+ cast(month(FechaLiberadoPintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
		from (
			select a.spoolid, FechaLiberadoPintura
			from spool a with(nolock)
			inner join OrdenTrabajoSpool b with(nolock) on a.SpoolID = b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
			inner join WorkstatusSpool c with(nolock) on b.OrdenTrabajoSpoolID = c.OrdenTrabajoSpoolID
			where FechaLiberadoPintura >= @from and FechaLiberadoPintura<=@to
			)x  left join  Shop_AutorizacionSI y with(nolock) on x.SpoolID = y.SpoolID and y.Activo=1 
	)y 
)z group by aniomes order by Aniomes




select a.aniomes, a.CalidadSoldadura, b.CalidadPintura, c.CalidadSpoolInspeccionados, d.NivelInspeccionFab, e.InspeccionFinal
from #CalidadSoldadura a with(nolock)
inner join  #CalidadPintura b with(nolock) on a.aniomes = b.aniomes
inner join #CalidadSpoolInspeccionados c with(nolock) on a.aniomes = c.aniomes
inner join #NivelInspeccionFab d with(nolock) on  a.aniomes= d.aniomes
inner join #InspeccionFinal e with(nolock) on a.aniomes = e.aniomes
order by aniomes




drop table #CalidadSoldadura
drop table #CalidadPintura
drop table #spoolrechazadosdimencional
drop table #spoolrechazadosvisual
drop table #rechazosVisualDimencional
drop table #CalidadSpoolInspeccionados
drop table #Visual
drop table #UltimaFechaSoldadura
drop table #FechaInspeccionDimencional
drop table #NivelInspeccionFab
drop table #InspeccionFinal
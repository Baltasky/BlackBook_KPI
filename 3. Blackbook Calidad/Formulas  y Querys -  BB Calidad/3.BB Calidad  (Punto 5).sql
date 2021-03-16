declare @from date = '2020-09-01'
declare @to date = '2021-02-28'


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
)y group by aniomes order by aniomes




		drop table #Visual
		drop table #UltimaFechaSoldadura
		drop table #FechaInspeccionDimencional
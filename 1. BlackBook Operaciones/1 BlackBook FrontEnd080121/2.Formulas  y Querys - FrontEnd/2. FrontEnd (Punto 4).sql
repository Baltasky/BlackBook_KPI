declare @from date = '2020-09-01'
declare @to date = '2021-01-31'

select aniomes, cast( cast( (sum(rechazados) * 100.0)as decimal) / count(spoolid) as numeric)  as RechazoVisualLevel  from (
	select *,
	case when resultadoid = 2 then 1 else 0 end as rechazados
	,cast( cast(year(fechainspeccion) as nvarchar) +'-'+ cast(month(fechainspeccion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from (
		select  a.SpoolID, d.fechainspeccion, d.resultadoid 
		from spool a with(nolock)
		inner join OrdenTrabajospool b with(nolock) on a.spoolid = b.SpoolID and a.campo7 != 'GRANEL' and a.campo7 != 'IWS' and a.campo7 != 'SOPORTE' 
		inner join JuntaWorkstatus c with(nolock) on b.OrdenTrabajoSpoolID= c.OrdenTrabajoSpoolID
		inner join sam3.[steelgo-sam3].dbo.sam3_inspeccionvisual d on c.JuntaWorkstatusID = d.JuntaWorkstatusID and (d.activo=1 or d.historico=1)
		inner join Proyecto e with(nolock) on a.ProyectoID= e.ProyectoID and e.ActivoCalculos=1
		where d.fechainspeccion >= @from and d.fechainspeccion <= @to
	 ) x
)y group by aniomes order by aniomes
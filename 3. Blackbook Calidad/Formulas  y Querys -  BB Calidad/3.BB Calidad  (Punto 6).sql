declare @from date = '2020-09-01'
declare @to date = '2021-02-28'


Create table #Reportes
(
	Proyecto int,
	Carpeta nvarchar(250),
	Reporte nvarchar(250),
	Fecha date 
)



insert into #Reportes
select distinct p.proyectoid,tp.Nombre,rp.NumeroReporte,rp.FechaReporte 
from ReportePnd rp
inner join JuntaReportePnd jrp on jrp.ReportePndID=rp.ReportePndID
inner join TipoPrueba tp on tp.TipoPruebaID=rp.TipoPruebaID
inner join Proyecto p on p.ProyectoID=rp.ProyectoID
where p.ActivoCalculos=1
union
select distinct  p.proyectoid,tp.Nombre,rp.NumeroReporte,rp.FechaReporte 
from ReporteTt rp
inner join JuntaReporteTt jrp on jrp.ReporteTtID=rp.ReporteTtID
inner join TipoPrueba tp on tp.TipoPruebaID=rp.TipoPruebaID
inner join Proyecto p on p.ProyectoID=rp.ProyectoID
where p.ActivoCalculos=1
union
select p.proyectoid,'SandBlast',ps.ReporteSandblast,FechaSandblast 
from PinturaSpool ps
inner join Proyecto p on p.ProyectoID=ps.ProyectoID
where p.ActivoCalculos=1
and FechaSandblast is not null
group by p.proyectoid,ps.ReporteSandblast,FechaSandblast 

union
select p.proyectoid,'Primarios',ps.ReportePrimarios,FechaPrimarios
from PinturaSpool ps
inner join Proyecto p on p.ProyectoID=ps.ProyectoID
where p.ActivoCalculos=1
and FechaPrimarios is not null
group by p.proyectoid,ps.ReportePrimarios,FechaPrimarios
union
select p.proyectoid,'Intermedios',ps.ReporteIntermedios,FechaIntermedios
from PinturaSpool ps
inner join Proyecto p on p.ProyectoID=ps.ProyectoID
where p.ActivoCalculos=1
and FechaIntermedios is not null
group by p.proyectoid,ps.ReporteIntermedios,FechaIntermedios
union
select p.proyectoid,'AcabadoVisual',ps.ReporteAcabadoVisual,FechaAcabadoVisual
from PinturaSpool ps
inner join Proyecto p on p.ProyectoID=ps.ProyectoID
where p.ActivoCalculos=1
and FechaAcabadoVisual is not null
group by p.proyectoid,ps.ReporteAcabadoVisual,FechaAcabadoVisual
union
select p.proyectoid,'Adherencia',ps.ReporteAdherencia,FechaAdherencia
from PinturaSpool ps
inner join Proyecto p on p.ProyectoID=ps.ProyectoID
where p.ActivoCalculos=1
and FechaAdherencia is not null
group by p.proyectoid,ps.ReporteAdherencia,FechaAdherencia

union
select p.proyectoid,'PullOff',ps.ReportePullOff,FechaPullOff
from PinturaSpool ps
inner join Proyecto p on p.ProyectoID=ps.ProyectoID
where p.ActivoCalculos=1
and FechaPullOff is not null
group by p.proyectoid,ps.ReportePullOff,FechaPullOff

union 
select p.proyectoid, 'Holiday', campo73, convert(date,campo72) 
from spool s
inner join Proyecto p on p.ProyectoID=s.ProyectoID
where p.ActivoCalculos=1
and campo72 is not null	
group by p.proyectoid, campo73, convert(date,campo72) 




select aniomes, cast((count(Archivo) *100.0) /count(Reporte)  as decimal (5,2)) as PorcDig from (
	select  a.Reporte, b.Archivo
	,cast( cast(year(a.Fecha) as nvarchar) +'-'+ cast(month(a.Fecha) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from #Reportes a
	inner join Proyecto p on p.ProyectoID=a.Proyecto
	left join ArchivosPorProyecto b on a.Proyecto=b.ProyectoID and a.Reporte=b.Archivo collate Latin1_General_CI_AS 
	where a.Fecha>= @from
	and a.Fecha< @to 
) x group by aniomes order by aniomes

drop table #Reportes

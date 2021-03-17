
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


select  count(b.Archivo) *100.0/count(a.Reporte) as PorcDig,count(a.Reporte) TotalReportes,count(b.Archivo) TotalDigitalizado
from #Reportes a
inner join Proyecto p on p.ProyectoID=a.Proyecto
left join ArchivosPorProyecto b on a.Proyecto=b.ProyectoID and a.Reporte=b.Archivo collate Latin1_General_CI_AS and FechaDigitalizacion<'20210301'
where a.Fecha>='20210201'
and a.Fecha<'20210301'



drop table #Reportes
declare @from date = '2020-09-01'
declare @to date = '2021-01-31'


create table #fechasOtEntrega
(
	spoolid int,
	fechaotentrega date
)

create table #CicloFabricacion
(
	spoolid int,
	FechaInspeccion date
)


insert into #fechasOtEntrega (spoolid, fechaotentrega)
	select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
	from SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a with(nolock)
	inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
	INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
	INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
	inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	inner join Spool f with(nolock) on f.SpoolID = e.SpoolID
	where B.ZonaID=3031 group by e.SpoolID

insert into #CicloFabricacion (spoolid, FechaInspeccion)
	select  a.SpoolID,  convert(date,max(d.fechainspeccion)) as FechaInspeccion
	from spool a with(nolock)
	inner join OrdenTrabajospool b with(nolock) on a.spoolid = b.SpoolID and a.campo7 != 'GRANEL' and a.campo7 != 'IWS' and a.campo7 != 'SOPORTE' 
	inner join sam3.[steelgo-sam3].dbo.Sam3_InspeccionDimensional d with(nolock) on d.ordentrabajospoolid = b.OrdenTrabajoSpoolID and d.activo=1 and d.resultadoid=1
	where d.fechainspeccion >= @from and d.fechainspeccion <= @to
	group by a.SpoolID, a.Nombre


	select aniomes, cast( cast( sum(diferencia) as decimal) /  count(spoolid) as decimal) as CicloFabricacion  from (
		select a.spoolid, DATEDIFF(day, b.fechaotentrega, a.FechaInspeccion) as diferencia
		, cast( cast(year(a.FechaInspeccion) as nvarchar) +'-'+ cast(month(a.FechaInspeccion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
		from  #CicloFabricacion a with(nolock)
		inner join #fechasOtEntrega b with(nolock) on a.spoolid = b.spoolid
 ) x group by aniomes order by aniomes


drop table #fechasOtEntrega
drop table #CicloFabricacion


 
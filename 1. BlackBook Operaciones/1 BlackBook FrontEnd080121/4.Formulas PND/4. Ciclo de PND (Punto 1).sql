declare @from date = '2020-09-01'
declare @to date = '2021-01-31'


create table #OkFab
( 
	spoolid int,
	FechaOkFabricacion date
)


insert into #OkFab( spoolid, FechaOkFabricacion)
	SELECT spoolid, FechaOkFabricacion from spool with(nolock)
	where campo7 != 'GRANEL' and campo7 != 'IWS' and campo7 != 'SOPORTE' 
	and FechaOkFabricacion >=  @from  and FechaOkFabricacion <= @to

select 
	aniomes, cast( sum(diferencia) / count(spoolid) as numeric) as  CicloPND
from (
	select  
	spoolid, aniomes, datediff(day, FechaDimencional, FechaOkFabricacion)as diferencia
	from (
		select a.spoolid, a.FechaOkFabricacion, max(convert(date,c.fechainspeccion)) as FechaDimencional
		,cast( cast(year(a.FechaOkFabricacion) as nvarchar) +'-'+ cast(month(a.FechaOkFabricacion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
		from #OkFab a with(nolock)
		inner join ordentrabajospool b with(nolock) on a.spoolid=b.SpoolID
		inner join sam3.[steelgo-sam3].dbo.sam3_InspeccionDimensional c with(nolock) on b.OrdenTrabajoSpoolID = c.ordentrabajospoolid 
		where (c.activo=1 or c.defectoid is not null)  group by a.spoolid, a.fechaokfabricacion
	) x 
)y group by Aniomes order by Aniomes

drop table #OkFab
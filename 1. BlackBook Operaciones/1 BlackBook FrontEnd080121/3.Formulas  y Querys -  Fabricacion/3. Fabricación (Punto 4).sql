declare @from date = '2020-09-01'
declare @to date = '2021-01-31'


create table #fechasOtEntrega
(
	spoolid int,
	fechaotentrega date
)

create table #OkFab
( 
	spoolid int,
	FechaOkFabricacion date
)

create table #SpoolDormidosOkFab
( 
	aniomes date,
	SpooldormidoFab int 
)

insert into #fechasOtEntrega (spoolid, fechaotentrega)
	select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
	from SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a with(nolock)
	inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
	INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
	INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
	inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	where B.ZonaID=3031 group by e.SpoolID

insert into #OkFab( spoolid, FechaOkFabricacion)
	SELECT spoolid, FechaOkFabricacion from spool with(nolock)
	where campo7 != 'GRANEL' and campo7 != 'IWS' and campo7 != 'SOPORTE' 
	and FechaOkFabricacion >=  @from  and FechaOkFabricacion <= @to

insert into #SpoolDormidosOkFab (aniomes, SpooldormidoFab)
select aniomes, sum(dormidos) as Spooldormidos  from(
	select aniomes
	,case when diferencia > 6 then 1 else 0 end as dormidos
	from (
		select a.spoolid, DATEDIFF(day, fechaotentrega, FechaOkFabricacion ) as diferencia
		, cast( cast(year(FechaOkFabricacion) as nvarchar) +'-'+ cast(month(FechaOkFabricacion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
		from #OkFab a  with(nolock)
        inner join #fechasOtEntrega b  with(nolock) on a.spoolid = b.spoolid
	) x 
)y group by aniomes order by aniomes


drop table #fechasOtEntrega
drop table #okfab
drop table #SpoolDormidosOkFab
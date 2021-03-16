declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';

create table #fechasOtEntrega
(
	spoolid int,
	fechaotentrega date
)


insert into #fechasOtEntrega (spoolid, fechaotentrega)
select * from (
	select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
	from 
    SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a 
	inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
	INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
	INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
	inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	where B.ZonaID=3031 group by e.spoolid
) x where fechaotentrega >= @from and FechaOtEntrega<=@to 

select aniomes, cast(cast(sum(diferencia)as numeric)/ COUNT(spoolid)as decimal(5,2)) as TiempoDespacho
from (
	select a.spoolid, datediff(day,FechaProgramadaSoldadura, fechaotentrega) as diferencia
	,cast( cast(year(fechaotentrega) as nvarchar) +'-'+ cast(month(fechaotentrega) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from #fechasOtEntrega a
	left join OrdenTrabajospool b  with(nolock) on a.spoolid=b.SpoolID
) x group by aniomes order by aniomes

drop table #fechasOtEntrega 


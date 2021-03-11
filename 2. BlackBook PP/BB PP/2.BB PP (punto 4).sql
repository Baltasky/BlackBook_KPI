declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';

create table #fechasOtReal
(
	spoolid int,
	fechaotentrega date
)

insert into #fechasOtReal (spoolid, fechaotentrega)
		select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
		from SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a with(nolock)
		inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
		INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
		INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
		inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	    where B.ZonaID=3031 group by e.SpoolID

select aniomes, (sum(diferencia) * 100)/ COUNT(aniomes) from (
	select  aniomes
	, case when fechaotentrega <= FechaPlanEmision  then 1 else 0 end as diferencia
	from (
		select a.spoolid, FechaPlanEmision, fechaotentrega 
		,cast( cast(year(fechaotentrega) as nvarchar) +'-'+ cast(month(fechaotentrega) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
		from spool a with(nolock) 
		inner join #fechasOtReal b  with(nolock)  on a.spoolid =b.SpoolID
		left join PlanPorSpool c with(nolock)  on b.spoolid =c.SpoolID
		where  fechaotentrega >=@from and fechaotentrega<=@to
		and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
	)x
)y group by aniomes order by aniomes

drop table #fechasOtReal


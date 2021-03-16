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
			where FechaLiberadoPintura >= '2020-9-1' and FechaLiberadoPintura<='2021-02-28'  
		)x  left join  Shop_AutorizacionSI y with(nolock) on x.SpoolID = y.SpoolID and y.Activo=1 
	)y 
)z group by aniomes order by Aniomes


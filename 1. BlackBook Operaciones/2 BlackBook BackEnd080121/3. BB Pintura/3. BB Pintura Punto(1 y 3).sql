declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';


select aniomes, sum(diferentes) / count(spoolid) as CicloPintura, sum(spooldormidos) as SpooldormidosPintura
from(
	select *
		,case when diferentes > 9 then 1 else 0 end as spooldormidos
		from (
			select a.spoolid, datediff(day,FechaTransferenciaPintura,FechaLiberadoPintura) as diferentes
			,cast( cast(year(FechaLiberadoPintura) as nvarchar) +'-'+ cast(month(FechaLiberadoPintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
			from spool a
			inner join OrdenTrabajoSpool b on a.SpoolID = b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
			inner join WorkstatusSpool c on b.OrdenTrabajoSpoolID = c.OrdenTrabajoSpoolID 
			where FechaLiberadoPintura >=@from and FechaLiberadoPintura <=@to
	)x
)y group by Aniomes order by aniomes
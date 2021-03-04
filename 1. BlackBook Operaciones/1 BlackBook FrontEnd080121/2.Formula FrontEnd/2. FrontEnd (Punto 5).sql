declare @from date = '2020-09-01'
declare @to date = '2021-01-31'


select aniomes,
   cast( cast( (sum(Rechazado)* 100.0)as decimal) / count(spoolid) as numeric) as RechazoDimensinalLevel
from 
(
		select  a.SpoolID,
			case when d.resultadoid=2 then 1 else 0 end Rechazado
			, cast( cast(year( d.fechainspeccion) as nvarchar) +'-'+ cast(month( d.fechainspeccion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
		from spool a with(nolock) 
		inner join OrdenTrabajospool b with(nolock) on a.spoolid = b.SpoolID and a.campo7 != 'GRANEL' and a.campo7 != 'IWS' and a.campo7 != 'SOPORTE' 
		inner join sam3.[steelgo-sam3].dbo.Sam3_InspeccionDimensional d with(nolock) on d.ordentrabajospoolid = b.OrdenTrabajoSpoolID
		where d.fechainspeccion >= @from and d.fechainspeccion <= @to 
		and (d.activo=1 or d.defectoid is not null)
)a group by aniomes order by aniomes

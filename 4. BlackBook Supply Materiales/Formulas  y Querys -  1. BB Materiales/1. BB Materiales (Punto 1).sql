declare @from date = '2020-09-01'
declare @to date = '2021-02-28'

select Aniomes, cast( (sum(cumple) * 100.0 ) as numeric)/ count( FolioAvisoEntradaID ) as CicloRecepcion
from(
	select folioavisoentradaid
	,cast( cast(year(FechaCreacion) as nvarchar) +'-'+ cast(month(FechaCreacion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
	,case when datediff(day,FechaFolioDescarga, FechaCreacion )  = 0 then 1 else 0 end as cumple
	from sam3.[steelgo-sam3].dbo.Sam3_FolioAvisoEntrada  with(nolock)
	where FechaCreacion >= @from and FechaCreacion <=@to

) x group by aniomes
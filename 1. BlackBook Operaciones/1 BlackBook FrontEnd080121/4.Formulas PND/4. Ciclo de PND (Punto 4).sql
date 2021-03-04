declare @from date = '2020-09-01'
declare @to date = '2021-01-31'

create table #fechTransfePintura
(
	spoolid int,
	fechaTransfePintura date
)


insert into #fechTransfePintura(spoolid, fechaTransfePintura)
	select spoolid, FechaTransferenciaPintura
	from spool   with(nolock)
	where  campo7 != 'GRANEL' and campo7 != 'IWS' and campo7 != 'SOPORTE'  
	and FechaTransferenciaPintura >= @from and FechaTransferenciaPintura <= @to 

select aniomes, sum(spooldormidos) as Spooldormidos from (
	select aniomes
	,case when diferencia > 6 then 1 else 0 end as spooldormidos
	from (
		select datediff(day, FechaOkFabricacion, fechaTransfePintura)  as diferencia
		,cast( cast(year(fechaTransfePintura) as nvarchar) +'-'+ cast(month(fechaTransfePintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
		 from (
			select a.spoolid, fechaTransfePintura, FechaOkFabricacion 
			from #fechTransfePintura a  with(nolock)
			inner join spool b  with(nolock) on a.spoolid = b.spoolid
		) x
	)y
)xy group by aniomes order by aniomes

drop table #fechTransfePintura


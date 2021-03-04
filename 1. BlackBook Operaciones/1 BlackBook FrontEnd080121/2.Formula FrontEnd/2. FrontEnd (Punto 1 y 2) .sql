declare @from date = '2020-09-01'
declare @to date = '2021-01-31'



create table #fechasOtEntrega
(
	spoolid int,
	fechaotentrega date
)

create table #fechTransfePintura
(
	spoolid int,
	fechaTransfePintura date
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

insert into #fechTransfePintura(spoolid, fechaTransfePintura)
	select spoolid, FechaTransferenciaPintura
	from spool 
	where  campo7 != 'GRANEL' and campo7 != 'IWS' and campo7 != 'SOPORTE'  
	and FechaTransferenciaPintura >= @from and FechaTransferenciaPintura <= @to 
	

		select Aniomes, sum(diferencia) / count(spoolid) as CicloFrontEnd, sum(spooldormidos) as spooldormidos from (
			select *, 
			case when diferencia > 12 then 1 else 0 end as Spooldormidos
			from (
				SELECT a.SpoolID, datediff(day,  fechaotentrega, a.fechaTransfePintura) as Diferencia
				, cast( cast(year(fechaTransfePintura) as nvarchar) +'-'+ cast(month(fechaTransfePintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
				from #fechTransfePintura a with(nolock)
				inner join #fechasOtEntrega b with(nolock) on a.SpoolID=b.spoolid    
				where  b.spoolid is not null  and fechaotentrega is not null
			)x 
		)y group by Aniomes order by Aniomes


drop table #fechasOtEntrega
drop table #fechTransfePintura
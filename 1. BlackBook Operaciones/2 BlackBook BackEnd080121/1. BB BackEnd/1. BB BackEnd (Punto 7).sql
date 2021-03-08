declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';

select aniomes,  cast(sum (tons)/count(numeroembarque) as decimal(5,1)) as TonsXplana
from  (
	SELECT numeroembarque, tons
	,cast( cast(year(fechaenvio ) as nvarchar) +'-'+ cast(month(fechaenvio ) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from (
		select numeroembarque, fechaenvio, sum(ton)  as Tons from (
			select numeroembarque, d.fechaenvio, (a.peso / 1000) as Ton
			from  spool a
			inner join [sam3].[steelgo-sam3].dbo.sam3_Embarque_detallecarga_plana b on a.spoolid= b.spoolid and (b.activo =1 or b.revisado=1) 
			and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
			inner join [sam3].[steelgo-sam3].dbo.sam3_Embarque_detalle c on b.cargaplanaid = c.cargaplanaid and c.activo=1
			inner join [sam3].[steelgo-sam3].dbo.sam3_Embarque_CapturaEnvio d on c.Embarqueid= d.embarqueid 
		) x  group by numeroembarque, fechaenvio
	)y where fechaenvio >=@from AND fechaenvio <=@to
)z group by aniomes order by aniomes
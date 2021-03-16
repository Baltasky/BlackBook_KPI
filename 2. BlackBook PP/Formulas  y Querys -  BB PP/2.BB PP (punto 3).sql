declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';

select aniomes, ( sum(ReservadoMaterial) * 100) / sum(FabConfirmado) as CumplimientoReservado from (
	select aniomes
	,case when FechaFabricableConfirmado is not null then 1 else 0 end as FabConfirmado
	,case when FechaReservaMaterial is not null then 1 else 0 end as ReservadoMaterial
	from (
		select  a.FechaFabricableConfirmado, b.FechaReservaMaterial 	
		,cast( cast(year(a.FechaFabricableConfirmado) as nvarchar) +'-'+ cast(month(a.FechaFabricableConfirmado) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
		from spool a with(nolock)
		left join OrdenTrabajospool b with(nolock) on a.SpoolID=b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
		where a.FechaFabricableConfirmado >=@from and a.FechaFabricableConfirmado<=@to 
	) x
)y group by  aniomes order by aniomes
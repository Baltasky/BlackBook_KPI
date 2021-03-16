declare   @from date = '2020-09-01';
declare   @to date = '2021-01-31';



select  sum(diferencias) / count(spoolid), aniomes from (
	select a.spoolid, b.FechaAutorizacion, a.okcalidadcliente, datediff(day,  b.FechaAutorizacion, a.okcalidadcliente)as  diferencias
	,cast( cast(year(a.okcalidadcliente ) as nvarchar) +'-'+ cast(month(a.okcalidadcliente ) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from spool a
	inner join Shop_AutorizacionSI b on a.spoolid= b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
	where a.okcalidadcliente  >= @FROM AND a.okcalidadcliente  <= @TO 
) x group by aniomes
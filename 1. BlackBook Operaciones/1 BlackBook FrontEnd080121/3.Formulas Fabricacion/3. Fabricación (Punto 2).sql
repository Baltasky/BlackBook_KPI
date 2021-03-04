declare @from date = '2020-09-01'
declare @to date = '2021-01-31'

		select    aniomes
		, cast ( cast( (sum(reachazadas) * 100) as decimal) / COUNT(JuntaWorkstatusID) as numeric) as WelddingQualetyLevel  
			from (
				select b.JuntaWorkstatusID, convert (date,c.fechaprueba  ) as FechaPrueba
				,cast( cast(year(FechaPrueba) as nvarchar) +'-'+ cast(month(FechaPrueba) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
				,case when Aprobado = 0 then 1 else 0 end reachazadas
					from OrdenTrabajospool a
					inner join JuntaWorkstatus b with(nolock) on a.OrdenTrabajoSpoolID = b.OrdenTrabajoSpoolID
					inner join JuntaReportePnd c with(nolock) on b.JuntaWorkstatusID = c.JuntaWorkstatusID
					inner join ReportePnd d with(nolock) on c.ReportePndID = d.ReportePndID
					inner join JuntaRequisicion e with(nolock) on c.JuntaRequisicionID = e.JuntaRequisicionID
					inner join TipoPrueba g with(nolock) on d.TipoPruebaID = g.TipoPruebaID
					WHERE  g.TipoPruebaID IN (1,5) 
		) x where fechaprueba >= @FROM AND fechaprueba <= @TO  group by aniomes  order by aniomes
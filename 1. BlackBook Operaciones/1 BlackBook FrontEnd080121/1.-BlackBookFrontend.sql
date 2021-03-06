declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';

create table #fechasOtEntrega
(
	spoolid int,
	fechaotentrega date
)

create table #fechaembarque 
(
	spoolid int,
	FechaEmbarque date,
	AnioMes date
)

create table #CicloOperaciones
(
	AnioMes date,
	CicloOperacion int,
	SpooldormidosCO int
)

create table #Calidadsoldadura
(
   AnioMes date,
   WelddingQualetyLevel int
)

create table #CalidadPintura
(
   aniomes date,
   PaintQualityLevel int
)

create table #portafolio
(
	aniomes date,
	cumplimiento int
)

create table #fechTransfePintura
(
	spoolid int,
	fechaTransfePintura date
)

create table #CicloFrontend
(	
	Aniomes date,
	CicloFrontEnd int,
	spooldormidosCF int
)

create table #NivelRechazoVisual
(
	aniomes date,
	rechazovisualLevel int
)

create table #NivelRechazoDimensional
(
	aniomes date,
	rechazoDimencionalLevel int
)

create table #FechaInspeccion
(
	spoolid int,
	FechaInspeccion date
)

create table #FechaFabricacion
(	
	aniome date,
	Ciclofabricacion int
)

create table #OkFab
( 
	spoolid int,
	FechaOkFabricacion date
)

create table #SpoolDormidosOkFab
( 
	aniomes date,
	SpooldormidoFab int 
)

create table #CicloPND 
(	
	aniomes date,
	CicloPND INT
)

create table #spoolDormidosPND
( 
	aniomes date,
	SpooldormidosPND INT
)

insert into #fechasOtEntrega (spoolid, fechaotentrega)
	select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
	from SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a with(nolock)
	inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
	INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
	INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
	inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	where B.ZonaID=3031 group by e.SpoolID


insert into #fechaembarque (spoolid, FechaEmbarque, AnioMes)
select spoolid,   FechaEmbarque  , aniomes
from(
select spoolid, FechaEmbarque, aniomes  from (
	select A.spoolid
	, CONVERT(date, e.fechaenvio) as FechaEmbarque
	, cast( cast(year(e.fechaenvio) as nvarchar) +'-'+ cast(month(e.fechaenvio) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
	from spool A
	inner join OrdenTrabajospool B on A.SpoolID= B.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_DetalleCarga_Plana] C with(nolock) on a.spoolid = c.spoolid and (c.activo=1 or c.revisado=1)
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_Detalle] D  with(nolock) on d.CargaPlanaID = c.CargaPlanaID and d.activo=1
	left join [sam3].[steelgo-sam3].[dbo].[Sam3_Embarque_CapturaEnvio] E with(nolock) on e.EmbarqueID=d.EmbarqueID 
)x  where FechaEmbarque >= @FROM AND FechaEmbarque <= @TO 
) y


insert into #CicloOperaciones (AnioMes, CicloOperacion, SpooldormidosCO)
select AnioMes, cast( cast(sum(diferencia) as decimal) / count(spoolid) as numeric) AS CicloOperacion, sum(spooldormidos) from (
	SELECT  *
	, case when diferencia > 30 then 1 else 0 end as spooldormidos 
	FROM (
		select a.spoolid, datediff(day, fechaotentrega, FechaEmbarque) as diferencia, AnioMes  
		from #fechaembarque a with(nolock)
		left join #fechasOtEntrega b with(nolock) on a.spoolid = b.spoolid
		where fechaotentrega is not null   
	)XY 
)xyz group by AnioMes  



insert into  #Calidadsoldadura ( AnioMes, WelddingQualetyLevel)
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
		) x where fechaprueba >= @FROM AND fechaprueba <= @TO  group by aniomes  


insert into #CalidadPintura (aniomes, PaintQualityLevel)
select Aniomes, CAST( cast((COUNT(SpoolRechazados) * 100.0 ) as decimal) / COUNT(SPOOLID) AS numeric ) AS PaintQualityLevel
	from (
		SELECT C.SpoolID, FechaLiberadoPintura, 
		cast( cast(year(FechaLiberadoPintura) as nvarchar) +'-'+ cast(month(FechaLiberadoPintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes,
		D.SPOOLID as SpoolRechazados
		FROM WorkstatusSpool A with(nolock)
		INNER JOIN ORDENTRABAJOSPOOL B with(nolock) ON A.OrdenTrabajoSpoolID = B.OrdenTrabajoSpoolID and a.FechaLiberadoPintura is not null
		INNER JOIN SPOOL C with(nolock) ON B.SpoolID= C.SpoolID 
		LEFT JOIN SAM3.[STEELGO-SAM3].DBO.Sam3_Pintura_RechazoPintura D with(nolock) ON C.SpoolID = D.SPOOLID AND (D.ACTIVO=1 OR  D.HISTORICO=1) 
	)X WHERE FechaLiberadoPintura >= @from AND FechaLiberadoPintura <= @to group by Aniomes


insert into #portafolio (aniomes, cumplimiento)
select aniomes,  cast( cast((sum(entregados) * 100.0 )as decimal) / count(spoolid) as numeric) as cumplimiento
from (
		select *
		 ,case when fechaembarque <= fechaplanembarque then 1 else 0 end as entregados
		from (
			select  a.AnioMes, a.spoolid, b.FechaPlanEmbarque, a.FechaEmbarque 
			from #fechaembarque a with(nolock)
			left join PlanPorSpool b with(nolock) on a.spoolid = b.SpoolID
		) x
) y group by AnioMes 


insert into #fechTransfePintura(spoolid, fechaTransfePintura)
	select spoolid, FechaTransferenciaPintura
	from spool with(nolock)
	where   FechaTransferenciaPintura >= @from and FechaTransferenciaPintura <= @to 
	and (campo7 not in ('GRANEL','SOPORTE','IWS') or campo7 is null)


insert into #CicloFrontend (Aniomes, CicloFrontEnd, SpooldormidosCF)
select Aniomes, sum(diferencia) / count(spoolid) as CicloFrontEnd, sum(spooldormidos) as spooldormidos from (
			select *, 
			case when diferencia > 12 then 1 else 0 end as Spooldormidos
			from (
				SELECT a.SpoolID, datediff(day,  fechaotentrega, a.fechaTransfePintura) as Diferencia
				, cast( cast(year(fechaTransfePintura) as nvarchar) +'-'+ cast(month(fechaTransfePintura) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
				from #fechTransfePintura a with(nolock)
				inner join #fechasOtEntrega b with(nolock) on a.SpoolID=b.spoolid    
				where  b.spoolid is not null  
			)x 
		)y group by Aniomes 


insert into #NivelRechazoVisual (aniomes, rechazovisualLevel)
select aniomes, cast( cast( (sum(rechazados) * 100.0)as decimal) / count(spoolid) as numeric)  as RechazoVisualLevel  from (
	select *,
	case when resultadoid = 2 then 1 else 0 end as rechazados
	,cast( cast(year(fechainspeccion) as nvarchar) +'-'+ cast(month(fechainspeccion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from (
		select  a.SpoolID, d.fechainspeccion, d.resultadoid 
		from spool a with(nolock)
		inner join OrdenTrabajospool b with(nolock) on a.spoolid = b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
		inner join JuntaWorkstatus c with(nolock) on b.OrdenTrabajoSpoolID= c.OrdenTrabajoSpoolID
		inner join sam3.[steelgo-sam3].dbo.sam3_inspeccionvisual d on c.JuntaWorkstatusID = d.JuntaWorkstatusID and (d.activo=1 or d.historico=1)
		inner join Proyecto e with(nolock) on a.ProyectoID= e.ProyectoID and e.ActivoCalculos=1
		where d.fechainspeccion >= @from and d.fechainspeccion <= @to
	 ) x
)y group by aniomes 


insert into #NivelRechazoDimensional (aniomes, rechazoDimencionalLevel)
select aniomes,
   cast( cast( (sum(Rechazado)* 100.0)as decimal) / count(spoolid) as numeric) as RechazoDimensinalLevel
from 
(
		select  a.SpoolID,
			case when d.resultadoid=2 then 1 else 0 end Rechazado
			, cast( cast(year( d.fechainspeccion) as nvarchar) +'-'+ cast(month( d.fechainspeccion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
		from spool a with(nolock) 
		inner join OrdenTrabajospool b with(nolock) on a.spoolid = b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
		inner join sam3.[steelgo-sam3].dbo.Sam3_InspeccionDimensional d with(nolock) on d.ordentrabajospoolid = b.OrdenTrabajoSpoolID
		where d.fechainspeccion >= @from and d.fechainspeccion <= @to 
		and (d.activo=1 or d.defectoid is not null)
)a group by aniomes 


insert into #FechaInspeccion (spoolid, FechaInspeccion)
	select  a.SpoolID,  convert(date,max(d.fechainspeccion)) as FechaInspeccion
	from spool a with(nolock)
	inner join OrdenTrabajospool b with(nolock) on a.spoolid = b.SpoolID and (a.campo7 not in ('GRANEL','SOPORTE','IWS') or a.campo7 is null)
	inner join sam3.[steelgo-sam3].dbo.Sam3_InspeccionDimensional d with(nolock) on d.ordentrabajospoolid = b.OrdenTrabajoSpoolID and d.activo=1 and d.resultadoid=1
	where d.fechainspeccion >= @from and d.fechainspeccion <= @to
	group by a.SpoolID, a.Nombre

insert into #FechaFabricacion(aniome, Ciclofabricacion)
	select aniomes, cast( cast( sum(diferencia) as decimal) /  count(spoolid) as decimal) as CicloFabricacion  from (
		select a.spoolid, DATEDIFF(day, b.fechaotentrega, a.FechaInspeccion) as diferencia
		, cast( cast(year(a.FechaInspeccion) as nvarchar) +'-'+ cast(month(a.FechaInspeccion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
		from  #FechaInspeccion a with(nolock)
		inner join #fechasOtEntrega b with(nolock) on a.spoolid = b.spoolid
 ) x group by aniomes 

 insert into #OkFab( spoolid, FechaOkFabricacion)
	SELECT spoolid, FechaOkFabricacion from spool with(nolock)
	where FechaOkFabricacion >=  @from  and FechaOkFabricacion <= @to
	and (campo7 not in ('GRANEL','SOPORTE','IWS') or campo7 is null)

insert into #SpoolDormidosOkFab (aniomes, SpooldormidoFab)
select aniomes, sum(dormidos) as Spooldormidos  from(
	select aniomes
	,case when diferencia > 6 then 1 else 0 end as dormidos
	from (
		select a.spoolid, DATEDIFF(day, fechaotentrega, FechaOkFabricacion ) as diferencia
		, cast( cast(year(FechaOkFabricacion) as nvarchar) +'-'+ cast(month(FechaOkFabricacion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes 
		from #OkFab a  with(nolock)
        inner join #fechasOtEntrega b  with(nolock) on a.spoolid = b.spoolid
	) x 
)y group by aniomes order by aniomes

insert into #CicloPND(aniomes, CicloPND)
select 
	aniomes, cast( sum(diferencia) / count(spoolid) as numeric) as  CicloPND
from (
	select  
	spoolid, aniomes, datediff(day, FechaDimencional, FechaOkFabricacion)as diferencia
	from (
		select a.spoolid, a.FechaOkFabricacion, max(convert(date,c.fechainspeccion)) as FechaDimencional
		,cast( cast(year(a.FechaOkFabricacion) as nvarchar) +'-'+ cast(month(a.FechaOkFabricacion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
		from #OkFab a with(nolock)
		inner join ordentrabajospool b with(nolock) on a.spoolid=b.SpoolID
		inner join sam3.[steelgo-sam3].dbo.sam3_InspeccionDimensional c with(nolock) on b.OrdenTrabajoSpoolID = c.ordentrabajospoolid 
		where (c.activo=1 or c.defectoid is not null)  group by a.spoolid, a.fechaokfabricacion
	) x 
)y group by Aniomes

insert into #spoolDormidosPND (aniomes, SpooldormidosPND)
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
)xy group by aniomes 
---------------------------------------------------1-Operaciones-------------------------------------------------------------------------
select a.AnioMes, a.CicloOperacion, a.SpooldormidosCO, b.WelddingQualetyLevel, c.PaintQualityLevel, d.cumplimiento,
e.CicloFrontEnd, e.spooldormidosCF, f.RechazoVisualLevel, g.rechazoDimencionalLevel, h.Ciclofabricacion, i.SpooldormidoFab
,j.CicloPND, k.SpooldormidosPND
from #CicloOperaciones a with(nolock)
inner join #Calidadsoldadura b with(nolock) on a.AnioMes = b.AnioMes 
inner join #CalidadPintura c with(nolock) on a.AnioMes = c.aniomes
inner join #portafolio d with(nolock) on a.AnioMes = d.AnioMes 
Inner join #CicloFrontend e with(nolock)  on a.AnioMes = e.AnioMes 
inner join #NivelRechazoVisual f with(nolock) on a.Aniomes = f.aniomes
inner join #NivelRechazoDimensional g with(nolock) on a.Aniomes = g.aniomes
inner join #FechaFabricacion h on a.AnioMes = h.aniome
inner join #SpoolDormidosOkFab i on a.AnioMes = i.aniomes
inner join #CicloPND j on a.AnioMes = j.aniomes
inner join #spoolDormidosPND  k on a.AnioMes = k.aniomes
order by a.AnioMes desc
-----------------------------------------------------------------------------------------------------------------------------


drop table #fechasOtEntrega
drop table #fechaembarque
drop table #CicloOperaciones
drop table #Calidadsoldadura
drop table #CalidadPintura
drop table #portafolio
drop table #fechTransfePintura
drop table #CicloFrontend
drop table #NivelRechazoVisual
drop table #NivelRechazoDimensional
drop table #FechaInspeccion
drop table #FechaFabricacion
drop table #OkFab
drop table #SpoolDormidosOkFab
drop table #CicloPND
drop table #spoolDormidosPND
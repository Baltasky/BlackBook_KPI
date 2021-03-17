declare   @from date = '2020-09-01';
declare   @to date = '2021-02-28';

create table #CicloRecepcion
(
	aniomes date,
	CicloRecepcion float
)


create table #fechasOtEntrega
(
	spoolid int,
	fechaotentrega date
)

create table #TiempoDespacho
(	
	aniomes date,
	TiempoDespacho float
)

create table #FechaRecepcion
(	
	fecharecepcion date,
	proyectoid int,
	indentificacodrCliente nvarchar(200),
	aniomes date
)

create table #NumeroUnicos
(
	NumeroUnico nvarchar(20),
	proyectoid int,
	identificadorcliente nvarchar(200),
	estatusMaterial nvarchar(50),
	numeromtr nvarchar(200)
)

create table #CierreInterno
(
	aniomes date,
	Cierreinterno int,
	NuSinMtr float
)

insert into #CicloRecepcion(aniomes, CicloRecepcion)
select Aniomes, cast( cast( (sum(cumple) * 100.0 ) as numeric)/ count( FolioAvisoEntradaID ) as numeric) as CicloRecepcion
from(
	select folioavisoentradaid
	,cast( cast(year(FechaCreacion) as nvarchar) +'-'+ cast(month(FechaCreacion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
	,case when datediff(day,FechaFolioDescarga, FechaCreacion )  = 0 then 1 else 0 end as cumple
	from sam3.[steelgo-sam3].dbo.Sam3_FolioAvisoEntrada  with(nolock)
	where FechaCreacion >= @from and FechaCreacion <=@to
) x group by aniomes


insert into #fechasOtEntrega (spoolid, fechaotentrega)
select * from (
	select e.SpoolID , Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
	from 
    SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante  a  with(nolock) 
	inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b with(nolock) on a.ZonaID= b.ZonaID AND A.Activo=1
	INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C with(nolock) ON A.PatioID = C.SAM3_PATIOID
	INNER JOIN Cuadrante D with(nolock) ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
	inner join CuadranteHistorico e with(nolock) on d.CuadranteID = e.CuadranteID
	where B.ZonaID=3031 group by e.spoolid
) x where fechaotentrega >= @from and FechaOtEntrega<=@to 

insert into #TiempoDespacho(aniomes, TiempoDespacho)
select aniomes, cast(cast(sum(diferencia)as numeric)/ COUNT(spoolid)as decimal(5,2)) as TiempoDespacho
from (
	select a.spoolid, datediff(day,FechaProgramadaSoldadura, fechaotentrega) as diferencia
	,cast( cast(year(fechaotentrega) as nvarchar) +'-'+ cast(month(fechaotentrega) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as aniomes
	from #fechasOtEntrega a with(nolock) 
	left join OrdenTrabajospool b  with(nolock) on a.spoolid=b.SpoolID
) x group by aniomes order by aniomes


insert into #FechaRecepcion(fecharecepcion, proyectoid, indentificacodrCliente, aniomes)
select convert(date, a.FechaCreacion) as FechaRecepcion, ProyectoID, IdentificadorCliente
,cast( cast(year(a.FechaCreacion) as nvarchar) +'-'+ cast(month(a.FechaCreacion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
from sam3.[steelgo-sam3].dbo.Sam3_FolioAvisoEntrada a with(nolock)
left join sam3.[steelgo-sam3].dbo.Sam3_FolioAvisoLlegada b with(nolock) on a.FolioAvisoLlegadaID=b.FolioAvisoLlegadaID and a.Activo=1
left join sam3.[steelgo-sam3].dbo.Sam3_Rel_FolioAvisoLlegada_Proyecto c with(nolock) on b.FolioAvisoLlegadaID=c.FolioAvisoLlegadaID
where  a.FechaCreacion >=@from and a.FechaCreacion <=@to

insert into #NumeroUnicos(NumeroUnico, proyectoid, identificadorcliente, numeromtr, estatusMaterial)
select Nu, rn.proyectoid, identificadorcliente, numeromtr
, case when (RecibidoCondicionado + RecibidoDanado + RecibidoAprobado = 0) or (DocumentalRechazado + DucumentalAprobado = 0) then 'En proceso de recepción'
	when (RecibidoCondicionado + RecibidoDanado) != 0 and DocumentalRechazado != 0 then 'Físico + documental rechazado'
	when (RecibidoCondicionado + RecibidoDanado) != 0 then 'Físico Rechazado'
	when DocumentalRechazado != 0 then 'Documental Rechazado'
	when (FisicoCondicionado + FisicoDanado+ FisicoAprobado) = 0 and CantidadDespachada != 0 then 'Ok'
	when RecibidoCondicionado = 0 and RecibidoDanado = 0 and DocumentalRechazado = 0 then 'Ok'
	when pendienteic=1 then 'PENDIENTE' end as EstatusMaterial
 from sam3.[steelgo-sam3].dbo.[VW_ResumenNUSegmento] rn with(nolock)

insert into #CierreInterno(aniomes, Cierreinterno, NuSinMtr)
select aniomes,cast( (sum(cumpleOK)* 100.0)/  COUNT(numerounico) as numeric) as CierreInterno 
, CAST((1- (CAST(sum(cumpleMTR) AS NUMERIC)/ COUNT(numerounico)) )* 100.0 AS decimal(5,2)) AS NuSinMTR
FROM (
	select NumeroUnico, aniomes
	, case when a.estatusMaterial = 'OK' then 1 else 0 end as CumpleOK
	,case when a.numeromtr is null then 1 else 0 end as CumpleMTR
	from #NumeroUnicos a with(nolock)
	inner join #FechaRecepcion b with(nolock) on a.proyectoid = b.proyectoid and a.identificadorcliente=b.indentificacodrCliente
)X group by aniomes order by aniomes 



select a.aniomes, a.CicloRecepcion, b.TiempoDespacho, c.Cierreinterno, c.NuSinMtr, '100%' as AmparoLegal
from #CicloRecepcion a
inner join #TiempoDespacho b on a.aniomes= b.aniomes
inner join #CierreInterno c on a.aniomes = c.aniomes
order by aniomes 

drop table #CicloRecepcion
drop table #fechasOtEntrega 
drop table #TiempoDespacho
drop table #FechaRecepcion
drop table #NumeroUnicos
drop table #CierreInterno
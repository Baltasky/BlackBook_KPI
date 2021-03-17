declare @from date = '2020-09-01'
declare @to date = '2021-02-28'


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


insert into #FechaRecepcion(fecharecepcion, proyectoid, indentificacodrCliente, aniomes)
select convert(date, a.FechaCreacion) as FechaRecepcion, ProyectoID, IdentificadorCliente
,cast( cast(year(a.FechaCreacion) as nvarchar) +'-'+ cast(month(a.FechaCreacion) as nvarchar) +'-'+ cast( 01 as nvarchar) as date) as Aniomes
from Sam3_FolioAvisoEntrada a with(nolock)
left join Sam3_FolioAvisoLlegada b with(nolock) on a.FolioAvisoLlegadaID=b.FolioAvisoLlegadaID and a.Activo=1
left join Sam3_Rel_FolioAvisoLlegada_Proyecto c with(nolock) on b.FolioAvisoLlegadaID=c.FolioAvisoLlegadaID
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
 from [VW_ResumenNUSegmento] rn with(nolock)

select aniomes,cast( (sum(cumpleOK)* 100.0)/  COUNT(numerounico) as numeric) as CierreInterno 
, CAST((1- (CAST(sum(cumpleMTR) AS NUMERIC)/ COUNT(numerounico)) )* 100.0 AS decimal(5,2)) AS NuSinMTR
FROM (
	select NumeroUnico, aniomes
	, case when a.estatusMaterial = 'OK' then 1 else 0 end as CumpleOK
	,case when a.numeromtr is null then 1 else 0 end as CumpleMTR
	from #NumeroUnicos a with(nolock)
	inner join #FechaRecepcion b with(nolock) on a.proyectoid = b.proyectoid and a.identificadorcliente=b.indentificacodrCliente
)X group by aniomes order by aniomes 


drop table #FechaRecepcion
drop table #NumeroUnicos

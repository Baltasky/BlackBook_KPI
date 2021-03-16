
declare @proyectoid nvarchar(250) ='89,95,91,92,93,94'
,@fechasoldadurainicio date='2021-02-01'
,@fechasoldadurafin date='2021-03-01'

 SELECT * INTO #ProyectosSplit FROM dbo.fnSplitString(@proyectoid,',')


--Create table #DatosSoldador
--(
--	Juntaspoolid int,
--	Juntaworkstatusid int,
--	NombreSoldador nvarchar(250),
--	Codigo nvarchar(250),
--	JuntasBW int,
--	JuntasFW int,
--	JuntasRT int,
--	PlacasRt int,
--	JuntasRechazadasRt int,
--	PlacasRechazadasRT int
--)

Create table #PlacasPorJunta
(
	JuntaSpoolID int,
	JuntaWorkstatusid int,
	NumPlacas int,
	FechaToma date
)

Create table #Placas
(
	Diametro decimal(18,2),
	Espesor nvarchar(250),
	RangoEspesor1 decimal(18,3),
	RangoEspesor2 decimal(18,3),
	NumPlacas int
)

insert into #Placas
values
(3,'XXS',null,null,3),
(4,'XS',null,null,3),
(6,'XS',null,null,3),
(8,'XS',null,null,3),
(4,'80',null,null,3),
(6,'80',null,null,3),
(8,'80',null,null,3),
(10,'80',null,null,3),
(12,'80',null,null,3),
(14,'80',null,null,3),
(16,'80',null,null,3),
(18,'100',null,null,3),
(20,'80',null,null,5),
(22,'80',null,null,5),
(24,'60',null,null,6),
(30,'XS',null,null,7),
(32,'XS',null,null,7),
(36,'XS',null,null,8),
(40,'XS',null,null,9),
(4,'XXS',null,null,4),
(6,'XXS',null,null,4),
(8,'160',null,null,4),
(10,'160',null,null,4),
(12,'140',null,null,4),
(14,'140',null,null,4),
(16,'120',null,null,4),
(18,'160',null,null,5),
(20,'160',null,null,6),
(22,'160',null,null,6),
(24,'160',null,null,7),
(3,null,2.11,15.24,3),
(4,null,3.05,8.56,3),
(6,null,2.77,10.97,3),
(8,null,2.77,12.7,3),
(10,null,3.4,15.09,3),
(12,null,4.57,17.48,3),
(14,null,3.96,19.05,3),
(16,null,4.19,21.44,3),
(18,null,4.19,29.36,3),
(20,null,4.78,26.19,5),
(22,null,4.78,28.58,5),
(24,null,5.54,24.61,6),
(30,null,6.35,12.7,7),
(32,null,6.35,12.7,7),
(36,null,6.35,12.7,8),
(40,null,9.53,12.7,9),
(4,null,11.13,17.12,4),
(6,null,14.27,21.95,4),
(8,null,18.26,23.01,4),
(10,null,21.44,28.58,4),
(12,null,21.44,28.58,4),
(14,null,23.83,31.75,4),
(16,null,26.19,30.96,4),
(18,null,34.93,45.24,5),
(20,null,32.54,50.01,6),
(22,null,34.93,53.98,6),
(24,null,30.96,59.54,7)

insert into #PlacasPorJunta
select js.JuntaSpoolID,jw.juntaworkstatusid,2,jrp.FechaPrueba
from Spool s with(nolock)
inner join JuntaSpool js with(nolock) on js.SpoolID=s.SpoolID and js.FabAreaID=1
inner join juntaworkstatus jw with(nolock) on jw.juntaspoolid=js.juntaspoolid --and jw.EtiquetaJunta=js.Etiqueta
inner join JuntaSoldadura jsd with(nolock) on jsd.JuntaWorkstatusID=jw.JuntaWorkstatusID
inner join JuntaReportePnd jrp with(nolock) on jrp.JuntaWorkstatusID=jw.JuntaWorkstatusID
inner join ReportePnd r with(nolock) on r.ReportePndID=jrp.ReportePndID and r.TipoPruebaID in (1,5)
inner join #ProyectosSplit p on s.ProyectoID=p.splitdata
where 
--s.ProyectoID=@proyectoid and 
--js.Cedula='STD' and 
js.Diametro<=2
and jsd.FechaSoldadura>=@fechasoldadurainicio
and jsd.FechaSoldadura<@fechasoldadurafin


insert into #PlacasPorJunta
select js.JuntaSpoolID,jw.juntaworkstatusid,p.NumPlacas,jrp.FechaPrueba
from Spool s with(nolock)
inner join JuntaSpool js with(nolock) on js.SpoolID=s.SpoolID and js.FabAreaID=1
inner join #Placas p with(nolock) on p.Diametro=js.Diametro and p.espesor=js.cedula collate Latin1_General_CI_AS
inner join juntaworkstatus jw with(nolock) on jw.juntaspoolid=js.juntaspoolid --and jw.EtiquetaJunta=js.Etiqueta
inner join JuntaSoldadura jsd with(nolock) on jsd.JuntaWorkstatusID=jw.JuntaWorkstatusID
inner join JuntaReportePnd jrp with(nolock) on jrp.JuntaWorkstatusID=jw.JuntaWorkstatusID
inner join ReportePnd r with(nolock) on r.ReportePndID=jrp.ReportePndID and r.TipoPruebaID in (1,5)
left join #PlacasPorJunta pj with(nolock) on pj.juntaworkstatusid=jw.juntaworkstatusid
inner join #ProyectosSplit pr on s.ProyectoID=pr.splitdata
where 
--s.ProyectoID=@proyectoid and 
pj.juntaworkstatusid is null
and jsd.FechaSoldadura>=@fechasoldadurainicio
and jsd.FechaSoldadura<@fechasoldadurafin


insert into #PlacasPorJunta
select js.JuntaSpoolID,jw.juntaworkstatusid,p.NumPlacas,jrp.FechaPrueba
from Spool s with(nolock)
inner join JuntaSpool js with(nolock) on js.SpoolID=s.SpoolID and js.FabAreaID=1
inner join #Placas p with(nolock) on p.Diametro=js.Diametro 
inner join juntaworkstatus jw with(nolock) on jw.juntaspoolid=js.juntaspoolid --and jw.EtiquetaJunta=js.Etiqueta
inner join JuntaSoldadura jsd with(nolock) on jsd.JuntaWorkstatusID=jw.JuntaWorkstatusID
inner join JuntaReportePnd jrp with(nolock) on jrp.JuntaWorkstatusID=jw.JuntaWorkstatusID
inner join ReportePnd r with(nolock) on r.ReportePndID=jrp.ReportePndID and r.TipoPruebaID in (1,5)
left join #PlacasPorJunta pj with(nolock) on pj.juntaworkstatusid=jw.juntaworkstatusid
inner join #ProyectosSplit pr on s.ProyectoID=pr.splitdata
where 
--s.ProyectoID=@proyectoid and 
js.Espesor>=p.RangoEspesor1 
and js.Espesor<=p.RangoEspesor2
and pj.juntaworkstatusid is null
and jsd.FechaSoldadura>=@fechasoldadurainicio
and jsd.FechaSoldadura<@fechasoldadurafin


	select js.JuntaSpoolID,rp.JuntaWorkstatusID,replace(replace(replace(replace(Placa,')',''),'(',''),'pl.-',''),'p-','') Placa,1 as Juntas,month(rp.FechaPrueba)Mes
	into #SegundaToma
	from JuntaSpool js with(nolock)
	inner join JuntaWorkstatus jw with(nolock) on jw.JuntaSpoolID=js.JuntaSpoolID --and js.Etiqueta!=jw.EtiquetaJunta
	inner join JuntaReportePnd rp with(nolock) on rp.JuntaWorkstatusID=jw.JuntaWorkstatusID
	inner join ReportePnd r with(nolock) on r.ReportePndID=rp.ReportePndID and r.TipoPruebaID in (1,5)
	inner join JuntaReportePndCuadrante jrp with(nolock) on rp.JuntaReportePndID=jrp.JuntaReportePndID
	inner join Proyecto p with(nolock) on p.ProyectoID=r.ProyectoID and p.ActivoCalculos=1
	inner join #PlacasPorJunta pj on pj.JuntaWorkstatusid=rp.JuntaWorkstatusID
	group by js.JuntaSpoolID,rp.JuntaWorkstatusID,replace(replace(replace(replace(Placa,')',''),'(',''),'pl.-',''),'p-',''),month(rp.FechaPrueba)

	insert into #SegundaToma
	select js.JuntaSpoolID,rp.JuntaWorkstatusID,replace(replace(Sector,')',''),'(','') Placa,1 as Juntas,month(rp.FechaPrueba)Mes
	from JuntaSpool js with(nolock)
	inner join JuntaWorkstatus jw with(nolock) on jw.JuntaSpoolID=js.JuntaSpoolID --and js.Etiqueta!=jw.EtiquetaJunta
	inner join JuntaReportePnd rp with(nolock) on rp.JuntaWorkstatusID=jw.JuntaWorkstatusID
	inner join ReportePnd r with(nolock) on r.ReportePndID=rp.ReportePndID and r.TipoPruebaID in (1,5)
	inner join JuntaReportePndSector jrp with(nolock) on rp.JuntaReportePndID=jrp.JuntaReportePndID
	inner join Proyecto p with(nolock) on p.ProyectoID=r.ProyectoID and p.ActivoCalculos=1
	inner join #PlacasPorJunta pj on pj.JuntaWorkstatusid=rp.JuntaWorkstatusID
	group by js.JuntaSpoolID,rp.JuntaWorkstatusID,replace(replace(Sector,')',''),'(',''),month(rp.FechaPrueba)


--select MONTH(FechaToma) as Mes,sum(NumPlacas)PlacasTomadas,sum(SegundaToma)SegundaToma
--from #PlacasPorJunta pj
--left join 
--(
--	select Mes,count(Placa) as SegundaToma 
--	from #SegundaToma 
--	group by Mes
--)s on pj.JuntaSpoolID=s.JuntaSpoolID
--where pj.FechaToma>='2020-01-01'
--group by  MONTH(FechaToma)


	select count(s.Placa)*100.0/sum(a.NumPlacas)
	from #PlacasPorJunta a
	left join #SegundaToma s on a.JuntaWorkstatusid=s.JuntaWorkstatusID
	


drop table #Placas
drop table #PlacasPorJunta
drop table #ProyectosSplit
drop table #SegundaToma




select e.SpoolID , g.Nombre as Proyecto, f.nombre as NombreSpool, Convert(DATE, min(e.FechaModificacion)) as FechaOtEntrega
from SAM3.[STEELGO-SAM3].DBO.Sam3_Cuadrante a
inner join  SAM3.[STEELGO-SAM3].DBO.Sam3_Zona b on a.ZonaID= b.ZonaID AND A.Activo=1
INNER JOIN  SAM3.[STEELGO-SAM3].DBO.Sam3_EquivalenciaPatio C ON A.PatioID = C.SAM3_PATIOID
INNER JOIN Cuadrante D ON D.PatioID =  C.SAM2_PATIOID AND a.Nombre= d.Nombre collate Latin1_General_CI_AS
inner join CuadranteHistorico e on d.CuadranteID = e.CuadranteID
inner join Spool f on f.SpoolID = e.SpoolID
inner join Proyecto g on g.ProyectoID= f.ProyectoID
where B.ZonaID=3031 group by e.SpoolID, f.nombre, g.Nombre


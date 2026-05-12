/*
================================================================================
Archivo:    99_validacion_post_etl.sql
Propósito:  Queries de validación para correr después del ETL.
            Confirman que los datos cargaron bien y los KPIs están en rango.

USO:       Abrir en SSMS y ejecutar bloque por bloque (F5 sobre cada SELECT).
================================================================================
*/
USE PiquilloBI_DW;
GO

PRINT '========================================================================';
PRINT 'VALIDACIÓN POST-ETL';
PRINT '========================================================================';

-- ============================================================
-- 1. Conteo de filas por tabla
-- ============================================================
PRINT '';
PRINT '1. CONTEO DE FILAS';
SELECT 'dw.DimFecha'        AS Tabla, COUNT(*) AS Filas FROM dw.DimFecha
UNION ALL SELECT 'dw.DimProductor',    COUNT(*) FROM dw.DimProductor
UNION ALL SELECT 'dw.DimFundo',        COUNT(*) FROM dw.DimFundo
UNION ALL SELECT 'dw.DimParcela',      COUNT(*) FROM dw.DimParcela
UNION ALL SELECT 'dw.DimCuadrilla',    COUNT(*) FROM dw.DimCuadrilla
UNION ALL SELECT 'dw.DimPlanta',       COUNT(*) FROM dw.DimPlanta
UNION ALL SELECT 'dw.DimLineaProceso', COUNT(*) FROM dw.DimLineaProceso
UNION ALL SELECT 'dw.DimFormato',      COUNT(*) FROM dw.DimFormato
UNION ALL SELECT 'dw.DimCliente',      COUNT(*) FROM dw.DimCliente
UNION ALL SELECT 'dw.DimDestino',      COUNT(*) FROM dw.DimDestino
UNION ALL SELECT 'dw.DimNaviera',      COUNT(*) FROM dw.DimNaviera
UNION ALL SELECT 'dw.DimIncoterm',     COUNT(*) FROM dw.DimIncoterm
UNION ALL SELECT 'dw.DimPrecioRefSUNAT', COUNT(*) FROM dw.DimPrecioRefSUNAT
UNION ALL SELECT '=== HECHOS ===',     NULL
UNION ALL SELECT 'dw.FactCosecha',     COUNT(*) FROM dw.FactCosecha
UNION ALL SELECT 'dw.FactProceso',     COUNT(*) FROM dw.FactProceso
UNION ALL SELECT 'dw.FactDespacho',    COUNT(*) FROM dw.FactDespacho;
GO

-- ============================================================
-- 2. Integridad SCD2 Productor (cada ProductorID debe tener EXACTAMENTE 1 EsActual=1)
-- ============================================================
PRINT '';
PRINT '2. INTEGRIDAD SCD2 PRODUCTOR';
WITH actuales AS (
    SELECT ProductorID, COUNT(*) AS NumActuales
    FROM dw.DimProductor
    WHERE EsActual = 1
    GROUP BY ProductorID
)
SELECT
    SUM(CASE WHEN NumActuales = 1 THEN 1 ELSE 0 END) AS ProductoresOK,
    SUM(CASE WHEN NumActuales <> 1 THEN 1 ELSE 0 END) AS ProductoresConProblema,
    (SELECT COUNT(DISTINCT ProductorID) FROM dw.DimProductor) AS TotalProductoresUnicos
FROM actuales;

-- Distribución de versiones por productor
SELECT NumVersiones, COUNT(*) AS NumProductores
FROM (
    SELECT ProductorID, COUNT(*) AS NumVersiones FROM dw.DimProductor GROUP BY ProductorID
) v
GROUP BY NumVersiones
ORDER BY NumVersiones;
GO

-- ============================================================
-- 3. KPIs Agrícolas por campaña
-- ============================================================
PRINT '';
PRINT '3. KPIs AGRÍCOLAS POR CAMPAÑA';
SELECT
    Campania,
    SUM(KgCosechados) / 1000.0 AS TonsCosechadas,
    AVG(TasaRechazoCampo) AS TasaRechazoPromedio,
    AVG(ProductividadKgXHH) AS ProductividadKgXHH_Prom,
    AVG(CostoUnitarioSolesXKg) AS CostoUnitarioSolesXKg_Prom
FROM dw.FactCosecha
GROUP BY Campania
ORDER BY Campania;
GO

-- Rendimiento por hectárea por campaña (con join correcto)
SELECT
    fc.Campania,
    SUM(fc.KgCosechados) AS KgCosechados,
    SUM(DISTINCT_AREA.AreaHa_Sum) AS HectareasProductivas,
    SUM(fc.KgCosechados) / NULLIF(SUM(DISTINCT_AREA.AreaHa_Sum), 0) AS RendimientoKgPorHa
FROM dw.FactCosecha fc
INNER JOIN (
    SELECT DISTINCT fc2.Campania, fc2.ParcelaID, p.AreaHa AS AreaHa_Sum
    FROM dw.FactCosecha fc2
    INNER JOIN dw.DimParcela p ON p.ParcelaID = fc2.ParcelaID
) DISTINCT_AREA
    ON DISTINCT_AREA.Campania = fc.Campania AND DISTINCT_AREA.ParcelaID = fc.ParcelaID
GROUP BY fc.Campania
ORDER BY fc.Campania;
GO

-- ============================================================
-- 4. KPIs Industriales
-- ============================================================
PRINT '';
PRINT '4. KPIs INDUSTRIALES';
SELECT
    Campania,
    SUM(KgIngresoMP) / 1000.0 AS TonsMP,
    SUM(KgProductoTerminado) / 1000.0 AS TonsPT,
    AVG(RendimientoProceso) AS RendimientoPromedio,
    AVG(TasaMermaProceso) AS MermaPromedio,
    AVG(TasaRechazoCalidad) AS RechazoCalidadProm
FROM dw.FactProceso
GROUP BY Campania
ORDER BY Campania;

-- Rendimiento por tipo de formato
SELECT
    f.Tipo,
    COUNT(*) AS Lotes,
    SUM(fp.KgIngresoMP) AS KgMP,
    SUM(fp.KgProductoTerminado) AS KgPT,
    SUM(fp.KgProductoTerminado) * 1.0 / NULLIF(SUM(fp.KgIngresoMP), 0) AS Rendimiento
FROM dw.FactProceso fp
INNER JOIN dw.DimFormato f ON f.FormatoID = fp.FormatoID
GROUP BY f.Tipo
ORDER BY f.Tipo;
GO

-- ============================================================
-- 5. KPIs Comerciales
-- ============================================================
PRINT '';
PRINT '5. KPIs COMERCIALES';
SELECT
    Campania,
    COUNT(*) AS Despachos,
    SUM(KgNetosExportados) AS KgExportados,
    SUM(ValorFOB_USD) AS ValorFOB,
    SUM(ValorFOB_USD) * 1.0 / NULLIF(SUM(KgNetosExportados), 0) AS FOB_USD_Kg,
    SUM(CAST(EsOnTime AS INT)) * 1.0 / COUNT(*) AS DIFOT_Porc
FROM dw.FactDespacho
GROUP BY Campania
ORDER BY Campania;

-- Top destinos
SELECT TOP 10
    d.Pais,
    COUNT(*) AS Despachos,
    SUM(fd.KgNetosExportados) AS KgExportados,
    SUM(fd.ValorFOB_USD) AS ValorFOB,
    SUM(fd.ValorFOB_USD) / NULLIF(SUM(fd.KgNetosExportados), 0) AS FOB_USD_Kg
FROM dw.FactDespacho fd
INNER JOIN dw.DimDestino d ON d.DestinoID = fd.DestinoID
GROUP BY d.Pais
ORDER BY ValorFOB DESC;
GO

-- ============================================================
-- 6. Comparación FOB nuestro vs SUNAT
-- ============================================================
PRINT '';
PRINT '6. COMPARACIÓN FOB NUESTRO vs SECTOR SUNAT';
SELECT
    df.Anio,
    df.Mes,
    SUM(fd.ValorFOB_USD) / NULLIF(SUM(fd.KgNetosExportados), 0) AS NuestroFOB,
    AVG(p.FOBPromedioSector_USDxKg) AS SectorFOB,
    SUM(fd.ValorFOB_USD) / NULLIF(SUM(fd.KgNetosExportados), 0) -
        AVG(p.FOBPromedioSector_USDxKg) AS Brecha
FROM dw.FactDespacho fd
INNER JOIN dw.DimFecha df ON df.FechaID = fd.FechaDespachoID
INNER JOIN dw.DimPrecioRefSUNAT p ON p.Anio = df.Anio AND p.Mes = df.Mes
GROUP BY df.Anio, df.Mes
ORDER BY df.Anio, df.Mes;
GO

-- ============================================================
-- 7. Trazabilidad inversa (lote despacho -> proceso -> fundo)
-- ============================================================
PRINT '';
PRINT '7. EJEMPLO DE TRAZABILIDAD INVERSA (TOP 5 DESPACHOS)';
SELECT TOP 5
    fd.DespachoID,
    fd.ContenedorNum,
    df.Fecha AS FechaDespacho,
    c.RazonSocial AS Cliente,
    d.Pais AS Destino,
    fd.LoteProcesoID,
    fp.LoteCampoOrigenID,
    fc.FundoID,
    fc.CuadrillaID,
    fc.LoteCampoID
FROM dw.FactDespacho fd
LEFT JOIN dw.FactProceso fp ON fp.LoteProcesoID = fd.LoteProcesoID
LEFT JOIN dw.FactCosecha fc ON fc.LoteCampoID = fp.LoteCampoOrigenID
INNER JOIN dw.DimFecha df ON df.FechaID = fd.FechaDespachoID
INNER JOIN dw.DimCliente c ON c.ClienteID = fd.ClienteID
INNER JOIN dw.DimDestino d ON d.DestinoID = fd.DestinoID
ORDER BY fd.DespachoID DESC;
GO

-- ============================================================
-- 8. Log de la última carga
-- ============================================================
PRINT '';
PRINT '8. LOG DE LA ÚLTIMA CARGA';
WITH ultimo AS (
    SELECT TOP 1 BatchID FROM audit.ETLLog ORDER BY FechaEvento DESC
)
SELECT
    LogID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos, FechaEvento
FROM audit.ETLLog
WHERE BatchID = (SELECT BatchID FROM ultimo)
ORDER BY LogID;
GO

PRINT '========================================================================';
PRINT 'VALIDACIÓN COMPLETADA';
PRINT '========================================================================';

/*
================================================================================
Archivo:    26_views_powerbi.sql
Propósito:  Views en schema [rpt] que sirven como capa semántica para Power BI.

VENTAJA: Power BI consume las views, no las tablas directas. Esto permite:
    - Cambiar la implementación interna del DW sin tocar Power BI
    - Aplicar reglas de negocio (filtros, joins) en la capa de DB
    - Limitar columnas expuestas (seguridad y performance)
================================================================================
*/
USE PiquilloBI_DW;
GO

-- ==========================================================================
-- vw_DimFecha
-- ==========================================================================
IF OBJECT_ID('rpt.vw_DimFecha') IS NOT NULL DROP VIEW rpt.vw_DimFecha;
GO
CREATE VIEW rpt.vw_DimFecha AS
SELECT
    FechaID,
    Fecha,
    Anio,
    Trimestre,
    Mes,
    NombreMes,
    NombreMesCorto,
    AnioMes,
    Semana,
    DiaMes,
    DiaSemana,
    NombreDiaSemana,
    EsFinDeSemana,
    EsFeriado,
    Campania
FROM dw.DimFecha;
GO

-- ==========================================================================
-- vw_DimProductor (solo versión actual, los hechos ya tienen el SK histórico)
-- ==========================================================================
IF OBJECT_ID('rpt.vw_DimProductor') IS NOT NULL DROP VIEW rpt.vw_DimProductor;
GO
CREATE VIEW rpt.vw_DimProductor AS
SELECT
    ProductorSK,
    ProductorID,
    NombreProductor,
    RUC,
    Distrito,
    Categoria,
    Certificaciones,
    TieneGlobalGAP,
    TieneSMETA,
    TieneBRC,
    TieneOrganico,
    NumCertificaciones,
    FechaInicio,
    FechaFin,
    EsActual
FROM dw.DimProductor;
GO

-- ==========================================================================
-- Views de dimensiones simples (passthrough)
-- ==========================================================================
IF OBJECT_ID('rpt.vw_DimFundo') IS NOT NULL DROP VIEW rpt.vw_DimFundo;
GO
CREATE VIEW rpt.vw_DimFundo AS
SELECT FundoID, NombreFundo, ProductorID, Distrito, Provincia, HectareasTotales
FROM dw.DimFundo;
GO

IF OBJECT_ID('rpt.vw_DimParcela') IS NOT NULL DROP VIEW rpt.vw_DimParcela;
GO
CREATE VIEW rpt.vw_DimParcela AS
SELECT ParcelaID, CodParcela, FundoID, Variedad, AreaHa, AnioPlantacion, EdadPlantacion
FROM dw.DimParcela;
GO

IF OBJECT_ID('rpt.vw_DimCuadrilla') IS NOT NULL DROP VIEW rpt.vw_DimCuadrilla;
GO
CREATE VIEW rpt.vw_DimCuadrilla AS
SELECT CuadrillaID, CodCuadrilla, NombreSupervisor, NumPersonas FROM dw.DimCuadrilla;
GO

IF OBJECT_ID('rpt.vw_DimPlanta') IS NOT NULL DROP VIEW rpt.vw_DimPlanta;
GO
CREATE VIEW rpt.vw_DimPlanta AS
SELECT PlantaID, NombrePlanta, Ubicacion, CapacidadDiariaKg FROM dw.DimPlanta;
GO

IF OBJECT_ID('rpt.vw_DimLineaProceso') IS NOT NULL DROP VIEW rpt.vw_DimLineaProceso;
GO
CREATE VIEW rpt.vw_DimLineaProceso AS
SELECT LineaProcesoID, CodLinea, PlantaID, TipoFormatoDedicado, CapacidadKgHora
FROM dw.DimLineaProceso;
GO

IF OBJECT_ID('rpt.vw_DimFormato') IS NOT NULL DROP VIEW rpt.vw_DimFormato;
GO
CREATE VIEW rpt.vw_DimFormato AS
SELECT FormatoID, CodFormato, Tipo, Envase, PesoNetoGr, UnidadesPorCaja, PesoCajaKg
FROM dw.DimFormato;
GO

IF OBJECT_ID('rpt.vw_DimCliente') IS NOT NULL DROP VIEW rpt.vw_DimCliente;
GO
CREATE VIEW rpt.vw_DimCliente AS
SELECT ClienteID, RazonSocial, Pais, TipoCliente, AnioPrimerNegocio, AntiguedadAnios
FROM dw.DimCliente;
GO

IF OBJECT_ID('rpt.vw_DimDestino') IS NOT NULL DROP VIEW rpt.vw_DimDestino;
GO
CREATE VIEW rpt.vw_DimDestino AS
SELECT DestinoID, Pais, Puerto, Region FROM dw.DimDestino;
GO

IF OBJECT_ID('rpt.vw_DimNaviera') IS NOT NULL DROP VIEW rpt.vw_DimNaviera;
GO
CREATE VIEW rpt.vw_DimNaviera AS
SELECT NavieraID, NombreNaviera, RutaTipica FROM dw.DimNaviera;
GO

IF OBJECT_ID('rpt.vw_DimIncoterm') IS NOT NULL DROP VIEW rpt.vw_DimIncoterm;
GO
CREATE VIEW rpt.vw_DimIncoterm AS
SELECT IncotermID, Codigo, Descripcion FROM dw.DimIncoterm;
GO

IF OBJECT_ID('rpt.vw_DimPrecioRefSUNAT') IS NOT NULL DROP VIEW rpt.vw_DimPrecioRefSUNAT;
GO
CREATE VIEW rpt.vw_DimPrecioRefSUNAT AS
SELECT PrecioRefSK, Anio, Mes, AnioMes,
       FOBPromedioSector_USDxKg, FOBPromedioPais_USDxKg,
       FechaInicio, FechaFin, EsActual
FROM dw.DimPrecioRefSUNAT;
GO

-- ==========================================================================
-- vw_FactCosecha
-- ==========================================================================
IF OBJECT_ID('rpt.vw_FactCosecha') IS NOT NULL DROP VIEW rpt.vw_FactCosecha;
GO
CREATE VIEW rpt.vw_FactCosecha AS
SELECT
    CosechaID, FechaID, FundoID, ParcelaID, CuadrillaID, ProductorSK,
    LoteCampoID, Campania,
    KgCosechados, KgRechazadosCampo, KgLimpios,
    HorasHombre, CostoCosechaSoles,
    CostoUnitarioSolesXKg, TasaRechazoCampo, ProductividadKgXHH
FROM dw.FactCosecha;
GO

-- ==========================================================================
-- vw_FactProceso
-- ==========================================================================
IF OBJECT_ID('rpt.vw_FactProceso') IS NOT NULL DROP VIEW rpt.vw_FactProceso;
GO
CREATE VIEW rpt.vw_FactProceso AS
SELECT
    LoteProcesoID, FechaIngresoID, FechaSalidaID, PlantaID, LineaProcesoID,
    FormatoID, LoteCampoOrigenID, Campania,
    KgIngresoMP, KgProductoTerminado, KgMermaProceso, KgRechazoCalidad,
    HorasOperacion, CostoProcesoSoles,
    RendimientoProceso, TasaMermaProceso, TasaRechazoCalidad,
    CostoUnitarioSolesXKgPT, DiasEnPlanta
FROM dw.FactProceso;
GO

-- ==========================================================================
-- vw_FactDespacho
-- ==========================================================================
IF OBJECT_ID('rpt.vw_FactDespacho') IS NOT NULL DROP VIEW rpt.vw_FactDespacho;
GO
CREATE VIEW rpt.vw_FactDespacho AS
SELECT
    DespachoID, FechaDespachoID, ClienteID, DestinoID, FormatoID,
    NavieraID, IncotermID, LoteProcesoID, Campania, ContenedorNum,
    NumPallets, KgNetosExportados, ValorFOB_USD, CostoLogisticoUSD,
    DiasTransitoComprometidos, DiasTransitoReales, EstadoDespacho,
    FOBUnitarioUSDxKg, CostoLogisticoUnitarioUSDxKg,
    MargenBrutoUSD, DesvTransitoDias, EsOnTime
FROM dw.FactDespacho;
GO

PRINT 'Views rpt.* creadas.';
GO

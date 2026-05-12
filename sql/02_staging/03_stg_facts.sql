/*
================================================================================
Archivo:    03_stg_facts.sql
Propósito:  Crear tablas staging para hechos.
================================================================================
*/
USE PiquilloBI_DW;
GO

-- ===== stg.FactCosecha =====
IF OBJECT_ID('stg.FactCosecha') IS NOT NULL DROP TABLE stg.FactCosecha;
CREATE TABLE stg.FactCosecha (
    CosechaID NVARCHAR(20) NULL,
    FechaID NVARCHAR(20) NULL,
    FechaCosecha NVARCHAR(50) NULL,
    FundoID NVARCHAR(20) NULL,
    ParcelaID NVARCHAR(20) NULL,
    CuadrillaID NVARCHAR(20) NULL,
    ProductorID NVARCHAR(20) NULL,
    LoteCampoID NVARCHAR(50) NULL,
    Campania NVARCHAR(20) NULL,
    KgCosechados NVARCHAR(20) NULL,
    KgRechazadosCampo NVARCHAR(20) NULL,
    HorasHombre NVARCHAR(20) NULL,
    CostoCosechaSoles NVARCHAR(20) NULL
);
GO

-- ===== stg.FactProceso =====
IF OBJECT_ID('stg.FactProceso') IS NOT NULL DROP TABLE stg.FactProceso;
CREATE TABLE stg.FactProceso (
    LoteProcesoID NVARCHAR(50) NULL,
    FechaIngresoID NVARCHAR(20) NULL,
    FechaIngreso NVARCHAR(50) NULL,
    FechaSalidaID NVARCHAR(20) NULL,
    FechaSalida NVARCHAR(50) NULL,
    PlantaID NVARCHAR(20) NULL,
    LineaProcesoID NVARCHAR(20) NULL,
    FormatoID NVARCHAR(20) NULL,
    LoteCampoOrigenID NVARCHAR(50) NULL,
    Campania NVARCHAR(20) NULL,
    KgIngresoMP NVARCHAR(20) NULL,
    KgProductoTerminado NVARCHAR(20) NULL,
    KgMermaProceso NVARCHAR(20) NULL,
    KgRechazoCalidad NVARCHAR(20) NULL,
    HorasOperacion NVARCHAR(20) NULL,
    CostoProcesoSoles NVARCHAR(20) NULL
);
GO

-- ===== stg.FactDespacho =====
IF OBJECT_ID('stg.FactDespacho') IS NOT NULL DROP TABLE stg.FactDespacho;
CREATE TABLE stg.FactDespacho (
    DespachoID NVARCHAR(20) NULL,
    FechaDespachoID NVARCHAR(20) NULL,
    FechaDespacho NVARCHAR(50) NULL,
    ClienteID NVARCHAR(20) NULL,
    DestinoID NVARCHAR(20) NULL,
    FormatoID NVARCHAR(20) NULL,
    NavieraID NVARCHAR(20) NULL,
    IncotermID NVARCHAR(20) NULL,
    LoteProcesoID NVARCHAR(50) NULL,
    Campania NVARCHAR(20) NULL,
    ContenedorNum NVARCHAR(50) NULL,
    NumPallets NVARCHAR(20) NULL,
    KgNetosExportados NVARCHAR(20) NULL,
    ValorFOB_USD NVARCHAR(20) NULL,
    CostoLogisticoUSD NVARCHAR(20) NULL,
    DiasTransitoComprometidos NVARCHAR(20) NULL,
    DiasTransitoReales NVARCHAR(20) NULL,
    EstadoDespacho NVARCHAR(20) NULL
);
GO

PRINT 'Tablas de staging para hechos creadas.';
GO

/*
================================================================================
Archivo:    02_stg_dimensions.sql
Propósito:  Crear tablas de staging para dimensiones.
            Las staging reciben datos crudos del CSV y todas las columnas son NVARCHAR
            (es buena práctica en staging: que los CSVs siempre carguen sin fallos
            de tipo, y validar/convertir en el paso a dw).
================================================================================
*/
USE PiquilloBI_DW;
GO

-- ===== stg.DimFecha =====
IF OBJECT_ID('stg.DimFecha') IS NOT NULL DROP TABLE stg.DimFecha;
CREATE TABLE stg.DimFecha (
    FechaID NVARCHAR(20) NULL,
    Fecha NVARCHAR(50) NULL,
    Anio NVARCHAR(20) NULL,
    Trimestre NVARCHAR(20) NULL,
    Mes NVARCHAR(20) NULL,
    NombreMes NVARCHAR(50) NULL,
    Semana NVARCHAR(20) NULL,
    DiaMes NVARCHAR(20) NULL,
    DiaSemana NVARCHAR(20) NULL,
    NombreDiaSemana NVARCHAR(50) NULL,
    EsFinDeSemana NVARCHAR(20) NULL,
    EsFeriado NVARCHAR(20) NULL,
    Campania NVARCHAR(20) NULL
);
GO

-- ===== stg.DimProductor =====
IF OBJECT_ID('stg.DimProductor') IS NOT NULL DROP TABLE stg.DimProductor;
CREATE TABLE stg.DimProductor (
    ProductorSK NVARCHAR(20) NULL,
    ProductorID NVARCHAR(20) NULL,
    NombreProductor NVARCHAR(200) NULL,
    RUC NVARCHAR(20) NULL,
    Distrito NVARCHAR(100) NULL,
    Categoria NVARCHAR(50) NULL,
    Certificaciones NVARCHAR(500) NULL,
    TieneGlobalGAP NVARCHAR(20) NULL,
    TieneSMETA NVARCHAR(20) NULL,
    TieneBRC NVARCHAR(20) NULL,
    TieneOrganico NVARCHAR(20) NULL,
    FechaInicio NVARCHAR(50) NULL,
    FechaFin NVARCHAR(50) NULL,
    EsActual NVARCHAR(20) NULL
);
GO

-- ===== stg.DimFundo =====
IF OBJECT_ID('stg.DimFundo') IS NOT NULL DROP TABLE stg.DimFundo;
CREATE TABLE stg.DimFundo (
    FundoID NVARCHAR(20) NULL,
    NombreFundo NVARCHAR(200) NULL,
    ProductorID NVARCHAR(20) NULL,
    Distrito NVARCHAR(100) NULL,
    Provincia NVARCHAR(100) NULL,
    HectareasTotales NVARCHAR(20) NULL
);
GO

-- ===== stg.DimParcela =====
IF OBJECT_ID('stg.DimParcela') IS NOT NULL DROP TABLE stg.DimParcela;
CREATE TABLE stg.DimParcela (
    ParcelaID NVARCHAR(20) NULL,
    CodParcela NVARCHAR(50) NULL,
    FundoID NVARCHAR(20) NULL,
    Variedad NVARCHAR(100) NULL,
    AreaHa NVARCHAR(20) NULL,
    AnioPlantacion NVARCHAR(20) NULL
);
GO

-- ===== stg.DimCuadrilla =====
IF OBJECT_ID('stg.DimCuadrilla') IS NOT NULL DROP TABLE stg.DimCuadrilla;
CREATE TABLE stg.DimCuadrilla (
    CuadrillaID NVARCHAR(20) NULL,
    CodCuadrilla NVARCHAR(20) NULL,
    NombreSupervisor NVARCHAR(200) NULL,
    NumPersonas NVARCHAR(20) NULL
);
GO

-- ===== stg.DimPlanta =====
IF OBJECT_ID('stg.DimPlanta') IS NOT NULL DROP TABLE stg.DimPlanta;
CREATE TABLE stg.DimPlanta (
    PlantaID NVARCHAR(20) NULL,
    NombrePlanta NVARCHAR(200) NULL,
    Ubicacion NVARCHAR(200) NULL,
    CapacidadDiariaKg NVARCHAR(20) NULL
);
GO

-- ===== stg.DimLineaProceso =====
IF OBJECT_ID('stg.DimLineaProceso') IS NOT NULL DROP TABLE stg.DimLineaProceso;
CREATE TABLE stg.DimLineaProceso (
    LineaProcesoID NVARCHAR(20) NULL,
    CodLinea NVARCHAR(50) NULL,
    PlantaID NVARCHAR(20) NULL,
    TipoFormatoDedicado NVARCHAR(50) NULL,
    CapacidadKgHora NVARCHAR(20) NULL
);
GO

-- ===== stg.DimFormato =====
IF OBJECT_ID('stg.DimFormato') IS NOT NULL DROP TABLE stg.DimFormato;
CREATE TABLE stg.DimFormato (
    FormatoID NVARCHAR(20) NULL,
    CodFormato NVARCHAR(50) NULL,
    Tipo NVARCHAR(50) NULL,
    Envase NVARCHAR(50) NULL,
    PesoNetoGr NVARCHAR(20) NULL,
    UnidadesPorCaja NVARCHAR(20) NULL
);
GO

-- ===== stg.DimCliente =====
IF OBJECT_ID('stg.DimCliente') IS NOT NULL DROP TABLE stg.DimCliente;
CREATE TABLE stg.DimCliente (
    ClienteID NVARCHAR(20) NULL,
    RazonSocial NVARCHAR(300) NULL,
    Pais NVARCHAR(100) NULL,
    TipoCliente NVARCHAR(50) NULL,
    AnioPrimerNegocio NVARCHAR(20) NULL
);
GO

-- ===== stg.DimDestino =====
IF OBJECT_ID('stg.DimDestino') IS NOT NULL DROP TABLE stg.DimDestino;
CREATE TABLE stg.DimDestino (
    DestinoID NVARCHAR(20) NULL,
    Pais NVARCHAR(100) NULL,
    Puerto NVARCHAR(100) NULL,
    Region NVARCHAR(100) NULL
);
GO

-- ===== stg.DimNaviera =====
IF OBJECT_ID('stg.DimNaviera') IS NOT NULL DROP TABLE stg.DimNaviera;
CREATE TABLE stg.DimNaviera (
    NavieraID NVARCHAR(20) NULL,
    NombreNaviera NVARCHAR(200) NULL,
    RutaTipica NVARCHAR(200) NULL
);
GO

-- ===== stg.DimIncoterm =====
IF OBJECT_ID('stg.DimIncoterm') IS NOT NULL DROP TABLE stg.DimIncoterm;
CREATE TABLE stg.DimIncoterm (
    IncotermID NVARCHAR(20) NULL,
    Codigo NVARCHAR(20) NULL,
    Descripcion NVARCHAR(200) NULL
);
GO

-- ===== stg.DimPrecioRefSUNAT =====
IF OBJECT_ID('stg.DimPrecioRefSUNAT') IS NOT NULL DROP TABLE stg.DimPrecioRefSUNAT;
CREATE TABLE stg.DimPrecioRefSUNAT (
    PrecioRefSK NVARCHAR(20) NULL,
    Anio NVARCHAR(20) NULL,
    Mes NVARCHAR(20) NULL,
    FOBPromedioSector_USDxKg NVARCHAR(50) NULL,
    FOBPromedioPais_USDxKg NVARCHAR(50) NULL,
    FechaInicio NVARCHAR(50) NULL,
    FechaFin NVARCHAR(50) NULL,
    EsActual NVARCHAR(20) NULL
);
GO

PRINT 'Tablas de staging para dimensiones creadas.';
GO

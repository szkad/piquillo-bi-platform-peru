/*
================================================================================
Archivo:    22_sp_load_dimensions.sql
Propósito:  SPs de carga de dimensiones SCD1 (sobreescritura simple).
            Cada SP: TRUNCATE + INSERT desde staging con conversión de tipos.

            Las dimensiones SCD2 (Productor, PrecioRefSUNAT) tienen su propio archivo.
================================================================================
*/
USE PiquilloBI_DW;
GO

-- ==========================================================================
-- DimFecha
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimFecha') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimFecha;
GO
CREATE PROCEDURE dw.usp_LoadDimFecha
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    BEGIN TRY
        -- Borrar respetando FKs: primero borrar hechos no, eso lo hace sp_master

        INSERT INTO dw.DimFecha (
            FechaID, Fecha, Anio, Trimestre, Mes, NombreMes, Semana,
            DiaMes, DiaSemana, NombreDiaSemana, EsFinDeSemana, EsFeriado, Campania
        )
        SELECT
            CAST(FechaID AS INT),
            CAST(Fecha AS DATE),
            CAST(Anio AS SMALLINT),
            CAST(Trimestre AS TINYINT),
            CAST(Mes AS TINYINT),
            NombreMes,
            CAST(Semana AS TINYINT),
            CAST(DiaMes AS TINYINT),
            CAST(DiaSemana AS TINYINT),
            NombreDiaSemana,
            CAST(EsFinDeSemana AS BIT),
            CAST(EsFeriado AS BIT),
            CAST(Campania AS SMALLINT)
        FROM stg.DimFecha;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimFecha', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimFecha', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimFundo
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimFundo') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimFundo;
GO
CREATE PROCEDURE dw.usp_LoadDimFundo
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    BEGIN TRY
        INSERT INTO dw.DimFundo (FundoID, NombreFundo, ProductorID, Distrito, Provincia, HectareasTotales)
        SELECT FundoID, NombreFundo, ProductorID, Distrito, Provincia,
               CAST(HectareasTotales AS DECIMAL(10, 2))
        FROM stg.DimFundo;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimFundo', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimFundo', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimParcela
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimParcela') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimParcela;
GO
CREATE PROCEDURE dw.usp_LoadDimParcela
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    BEGIN TRY
        INSERT INTO dw.DimParcela (ParcelaID, CodParcela, FundoID, Variedad, AreaHa, AnioPlantacion)
        SELECT ParcelaID, CodParcela, FundoID, Variedad,
               CAST(AreaHa AS DECIMAL(8, 2)),
               CAST(AnioPlantacion AS SMALLINT)
        FROM stg.DimParcela;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimParcela', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimParcela', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimCuadrilla
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimCuadrilla') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimCuadrilla;
GO
CREATE PROCEDURE dw.usp_LoadDimCuadrilla
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();
    BEGIN TRY
        INSERT INTO dw.DimCuadrilla (CuadrillaID, CodCuadrilla, NombreSupervisor, NumPersonas)
        SELECT CuadrillaID, CodCuadrilla, NombreSupervisor, CAST(NumPersonas AS SMALLINT)
        FROM stg.DimCuadrilla;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimCuadrilla', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimCuadrilla', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimPlanta
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimPlanta') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimPlanta;
GO
CREATE PROCEDURE dw.usp_LoadDimPlanta
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();
    BEGIN TRY
        INSERT INTO dw.DimPlanta (PlantaID, NombrePlanta, Ubicacion, CapacidadDiariaKg)
        SELECT PlantaID, NombrePlanta, Ubicacion, CAST(CapacidadDiariaKg AS INT)
        FROM stg.DimPlanta;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimPlanta', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimPlanta', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimLineaProceso
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimLineaProceso') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimLineaProceso;
GO
CREATE PROCEDURE dw.usp_LoadDimLineaProceso
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();
    BEGIN TRY
        INSERT INTO dw.DimLineaProceso (LineaProcesoID, CodLinea, PlantaID, TipoFormatoDedicado, CapacidadKgHora)
        SELECT LineaProcesoID, CodLinea, PlantaID, TipoFormatoDedicado,
               CAST(CapacidadKgHora AS INT)
        FROM stg.DimLineaProceso;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimLineaProceso', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimLineaProceso', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimFormato
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimFormato') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimFormato;
GO
CREATE PROCEDURE dw.usp_LoadDimFormato
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();
    BEGIN TRY
        INSERT INTO dw.DimFormato (FormatoID, CodFormato, Tipo, Envase, PesoNetoGr, UnidadesPorCaja)
        SELECT FormatoID, CodFormato, Tipo, Envase,
               CAST(PesoNetoGr AS INT),
               CAST(UnidadesPorCaja AS SMALLINT)
        FROM stg.DimFormato;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimFormato', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimFormato', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimCliente
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimCliente') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimCliente;
GO
CREATE PROCEDURE dw.usp_LoadDimCliente
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();
    BEGIN TRY
        INSERT INTO dw.DimCliente (ClienteID, RazonSocial, Pais, TipoCliente, AnioPrimerNegocio)
        SELECT ClienteID, RazonSocial, Pais, TipoCliente,
               CAST(AnioPrimerNegocio AS SMALLINT)
        FROM stg.DimCliente;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimCliente', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimCliente', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimDestino
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimDestino') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimDestino;
GO
CREATE PROCEDURE dw.usp_LoadDimDestino
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();
    BEGIN TRY
        INSERT INTO dw.DimDestino (DestinoID, Pais, Puerto, Region)
        SELECT DestinoID, Pais, Puerto, Region FROM stg.DimDestino;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimDestino', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimDestino', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimNaviera
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimNaviera') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimNaviera;
GO
CREATE PROCEDURE dw.usp_LoadDimNaviera
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();
    BEGIN TRY
        INSERT INTO dw.DimNaviera (NavieraID, NombreNaviera, RutaTipica)
        SELECT NavieraID, NombreNaviera, RutaTipica FROM stg.DimNaviera;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimNaviera', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimNaviera', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimIncoterm
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimIncoterm') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimIncoterm;
GO
CREATE PROCEDURE dw.usp_LoadDimIncoterm
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();
    BEGIN TRY
        INSERT INTO dw.DimIncoterm (IncotermID, Codigo, Descripcion)
        SELECT IncotermID, Codigo, Descripcion FROM stg.DimIncoterm;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimIncoterm', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimIncoterm', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

PRINT 'SPs de carga de dimensiones SCD1 creados.';
GO

/*
================================================================================
Archivo:    24_sp_load_facts.sql
Propósito:  SPs de carga de hechos.

PUNTO IMPORTANTE: FactCosecha hace lookup del ProductorSK vigente al momento
                  de la cosecha (no del SK actual). Esto es la magia del SCD2.
================================================================================
*/
USE PiquilloBI_DW;
GO

-- ==========================================================================
-- FactCosecha
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadFactCosecha') IS NOT NULL DROP PROCEDURE dw.usp_LoadFactCosecha;
GO

CREATE PROCEDURE dw.usp_LoadFactCosecha
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    BEGIN TRY

        -- Lookup SCD2: ProductorSK vigente a la fecha de cosecha
        INSERT INTO dw.FactCosecha (
            CosechaID, FechaID, FundoID, ParcelaID, CuadrillaID, ProductorSK,
            LoteCampoID, Campania, KgCosechados, KgRechazadosCampo,
            HorasHombre, CostoCosechaSoles
        )
        SELECT
            CAST(s.CosechaID AS INT),
            CAST(s.FechaID AS INT),
            s.FundoID,
            s.ParcelaID,
            s.CuadrillaID,
            p.ProductorSK,
            s.LoteCampoID,
            CAST(s.Campania AS SMALLINT),
            CAST(s.KgCosechados AS DECIMAL(12, 2)),
            CAST(s.KgRechazadosCampo AS DECIMAL(12, 2)),
            CAST(s.HorasHombre AS DECIMAL(10, 2)),
            CAST(s.CostoCosechaSoles AS DECIMAL(12, 2))
        FROM stg.FactCosecha s
        INNER JOIN dw.DimProductor p
            ON p.ProductorID = s.ProductorID
            AND CAST(s.FechaCosecha AS DATE) BETWEEN p.FechaInicio AND p.FechaFin;

        DECLARE @InsertadasCosecha BIGINT = @@ROWCOUNT;
        DECLARE @StagingCosecha BIGINT = (SELECT COUNT(*) FROM stg.FactCosecha);

        IF @InsertadasCosecha < @StagingCosecha
        BEGIN
            INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
            VALUES (@BatchID, 'dw.usp_LoadFactCosecha', 'WARN',
                    CONCAT('Filas perdidas en lookup SCD2: ',
                           @StagingCosecha - @InsertadasCosecha,
                           ' de ', @StagingCosecha));
        END

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadFactCosecha', 'INFO', 'OK', @InsertadasCosecha,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadFactCosecha', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- FactProceso
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadFactProceso') IS NOT NULL DROP PROCEDURE dw.usp_LoadFactProceso;
GO

CREATE PROCEDURE dw.usp_LoadFactProceso
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    BEGIN TRY

        INSERT INTO dw.FactProceso (
            LoteProcesoID, FechaIngresoID, FechaSalidaID, PlantaID,
            LineaProcesoID, FormatoID, LoteCampoOrigenID, Campania,
            KgIngresoMP, KgProductoTerminado, KgMermaProceso, KgRechazoCalidad,
            HorasOperacion, CostoProcesoSoles
        )
        SELECT
            LoteProcesoID,
            CAST(FechaIngresoID AS INT),
            CAST(FechaSalidaID AS INT),
            PlantaID, LineaProcesoID, FormatoID, LoteCampoOrigenID,
            CAST(Campania AS SMALLINT),
            CAST(KgIngresoMP AS DECIMAL(12, 2)),
            CAST(KgProductoTerminado AS DECIMAL(12, 2)),
            CAST(KgMermaProceso AS DECIMAL(12, 2)),
            CAST(KgRechazoCalidad AS DECIMAL(12, 2)),
            CAST(HorasOperacion AS DECIMAL(10, 2)),
            CAST(CostoProcesoSoles AS DECIMAL(12, 2))
        FROM stg.FactProceso;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadFactProceso', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadFactProceso', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- FactDespacho
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadFactDespacho') IS NOT NULL DROP PROCEDURE dw.usp_LoadFactDespacho;
GO

CREATE PROCEDURE dw.usp_LoadFactDespacho
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    BEGIN TRY

        -- Filtrar despachos cuyo lote de proceso no exista (validación de integridad)
        INSERT INTO dw.FactDespacho (
            DespachoID, FechaDespachoID, ClienteID, DestinoID, FormatoID,
            NavieraID, IncotermID, LoteProcesoID, Campania, ContenedorNum,
            NumPallets, KgNetosExportados, ValorFOB_USD, CostoLogisticoUSD,
            DiasTransitoComprometidos, DiasTransitoReales, EstadoDespacho
        )
        SELECT
            CAST(s.DespachoID AS INT),
            CAST(s.FechaDespachoID AS INT),
            s.ClienteID, s.DestinoID, s.FormatoID, s.NavieraID, s.IncotermID,
            s.LoteProcesoID,
            CAST(s.Campania AS SMALLINT),
            s.ContenedorNum,
            CAST(s.NumPallets AS SMALLINT),
            CAST(s.KgNetosExportados AS DECIMAL(12, 2)),
            CAST(s.ValorFOB_USD AS DECIMAL(14, 2)),
            CAST(s.CostoLogisticoUSD AS DECIMAL(12, 2)),
            CAST(s.DiasTransitoComprometidos AS SMALLINT),
            CAST(s.DiasTransitoReales AS SMALLINT),
            s.EstadoDespacho
        FROM stg.FactDespacho s
        INNER JOIN dw.FactProceso p ON p.LoteProcesoID = s.LoteProcesoID;

        DECLARE @InsDesp BIGINT = @@ROWCOUNT;
        DECLARE @StgDesp BIGINT = (SELECT COUNT(*) FROM stg.FactDespacho);

        IF @InsDesp < @StgDesp
        BEGIN
            INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
            VALUES (@BatchID, 'dw.usp_LoadFactDespacho', 'WARN',
                    CONCAT('Despachos descartados por LoteProceso inexistente: ',
                           @StgDesp - @InsDesp));
        END

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadFactDespacho', 'INFO', 'OK', @InsDesp,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadFactDespacho', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

PRINT 'SPs de carga de hechos creados.';
GO

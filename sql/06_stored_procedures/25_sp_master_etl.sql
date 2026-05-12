/*
================================================================================
Archivo:    25_sp_master_etl.sql
Propósito:  SP maestro que orquesta toda la carga ETL en orden correcto.

USO:
    EXEC dw.usp_RunMasterETL @DataPath = N'C:\proyectos\piquillo-bi\data\raw\';

ORDEN DE EJECUCIÓN:
    1. Carga staging (todos los CSVs)
    2. Borrar hechos del DW (respeta FKs)
    3. Carga dimensiones SCD1
    4. Carga dimensiones SCD2 (Productor, PrecioRefSUNAT)
    5. Carga hechos (con lookups SCD2)
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.usp_RunMasterETL') IS NOT NULL DROP PROCEDURE dw.usp_RunMasterETL;
GO

CREATE PROCEDURE dw.usp_RunMasterETL
    @DataPath NVARCHAR(500),
    @ModoSCD2 NVARCHAR(20) = N'FULL'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchID UNIQUEIDENTIFIER = NEWID();
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
    VALUES (@BatchID, 'dw.usp_RunMasterETL', 'INICIO',
            CONCAT('Inicio ETL maestro. DataPath=', @DataPath, ' ModoSCD2=', @ModoSCD2));

    BEGIN TRY
        -- ===== 1. Cargar staging =====
        EXEC stg.usp_LoadStaging @DataPath = @DataPath, @BatchID = @BatchID;

        -- ===== 2. Borrar DW completo en orden FK-respetuoso =====
        -- Primero hechos (hijos), después dimensiones (padres).
        -- Dentro de dimensiones también hay jerarquía: Parcela depende de Fundo,
        -- LineaProceso depende de Planta.
        -- Usamos DELETE (no TRUNCATE) porque TRUNCATE falla con FKs referenciadoras.

        -- Hechos
        DELETE FROM dw.FactDespacho;
        DELETE FROM dw.FactProceso;
        DELETE FROM dw.FactCosecha;

        -- Dimensiones referenciadas por hijas
        DELETE FROM dw.DimParcela;       -- referencia DimFundo
        DELETE FROM dw.DimLineaProceso;  -- referencia DimPlanta
        DELETE FROM dw.DimFundo;
        DELETE FROM dw.DimPlanta;

        -- Dimensiones sin dependencias entre sí
        DELETE FROM dw.DimFecha;
        DELETE FROM dw.DimCuadrilla;
        DELETE FROM dw.DimFormato;
        DELETE FROM dw.DimCliente;
        DELETE FROM dw.DimDestino;
        DELETE FROM dw.DimNaviera;
        DELETE FROM dw.DimIncoterm;
        DELETE FROM dw.DimProductor;
        DELETE FROM dw.DimPrecioRefSUNAT;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_RunMasterETL', 'INFO', 'DW borrado completamente.');

        -- ===== 3. Cargar dimensiones SCD1 =====
        -- Orden: padres antes que hijos (Fundo -> Parcela; Planta -> LineaProceso)
        EXEC dw.usp_LoadDimFecha @BatchID;
        EXEC dw.usp_LoadDimFundo @BatchID;
        EXEC dw.usp_LoadDimParcela @BatchID;
        EXEC dw.usp_LoadDimCuadrilla @BatchID;
        EXEC dw.usp_LoadDimPlanta @BatchID;
        EXEC dw.usp_LoadDimLineaProceso @BatchID;
        EXEC dw.usp_LoadDimFormato @BatchID;
        EXEC dw.usp_LoadDimCliente @BatchID;
        EXEC dw.usp_LoadDimDestino @BatchID;
        EXEC dw.usp_LoadDimNaviera @BatchID;
        EXEC dw.usp_LoadDimIncoterm @BatchID;

        -- ===== 4. Cargar dimensiones SCD2 =====
        EXEC dw.usp_LoadDimProductorSCD2 @BatchID = @BatchID, @Modo = @ModoSCD2;
        EXEC dw.usp_LoadDimPrecioRefSUNATSCD2 @BatchID = @BatchID;

        -- ===== 5. Cargar hechos =====
        -- FactProceso antes que FactDespacho (FactDespacho referencia LoteProcesoID)
        EXEC dw.usp_LoadFactCosecha @BatchID;
        EXEC dw.usp_LoadFactProceso @BatchID;
        EXEC dw.usp_LoadFactDespacho @BatchID;

        -- ===== Resumen final =====
        DECLARE @TotalFilas BIGINT;
        SET @TotalFilas = (
            (SELECT COUNT(*) FROM dw.FactCosecha)
            + (SELECT COUNT(*) FROM dw.FactProceso)
            + (SELECT COUNT(*) FROM dw.FactDespacho)
        );

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_RunMasterETL', 'FIN',
                CONCAT('ETL completado OK. Total filas en hechos: ', @TotalFilas),
                @TotalFilas,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));

        PRINT CONCAT(N'ETL completado. BatchID = ', CAST(@BatchID AS NVARCHAR(50)));
        PRINT CONCAT(N'Total filas cargadas en hechos: ', @TotalFilas);
        PRINT CONCAT(N'Duración: ', DATEDIFF(SECOND, @Inicio, SYSDATETIME()), N's');
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_RunMasterETL', 'ERROR',
                CONCAT('Error en ETL: ', ERROR_MESSAGE(), ' Línea: ', ERROR_LINE()));
        THROW;
    END CATCH
END
GO

PRINT 'SP maestro dw.usp_RunMasterETL creado.';
GO

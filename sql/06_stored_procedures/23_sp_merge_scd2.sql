/*
================================================================================
Archivo:    23_sp_merge_scd2.sql
Propósito:  SPs de carga SCD Tipo 2 para DimProductor y DimPrecioRefSUNAT.

LÓGICA SCD2 (Kimball):
  - Si el ProductorID es nuevo → INSERT versión inicial (EsActual=1).
  - Si existe pero alguno de los atributos rastreados cambió:
      - UPDATE versión actual: EsActual=0, FechaFin = hoy - 1
      - INSERT nueva versión: EsActual=1, FechaInicio = hoy
  - Si no hay cambios → no hacer nada.

NOTA: Como en este proyecto el dato sintético YA viene con la historia SCD2 armada,
      en la primera carga simplemente hacemos TRUNCATE+INSERT respetando los
      surrogate keys originales. En cargas incrementales (escenario real) usaríamos
      la lógica de MERGE detectando cambios.

      Este SP soporta AMBOS modos via parámetro @Modo:
          'FULL'    = TRUNCATE + INSERT directo (carga inicial)
          'MERGE'   = lógica SCD2 incremental
================================================================================
*/
USE PiquilloBI_DW;
GO

-- ==========================================================================
-- DimProductor SCD2
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimProductorSCD2') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimProductorSCD2;
GO

CREATE PROCEDURE dw.usp_LoadDimProductorSCD2
    @BatchID UNIQUEIDENTIFIER,
    @Modo NVARCHAR(20) = N'FULL'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    BEGIN TRY
        IF @Modo = N'FULL'
        BEGIN

            INSERT INTO dw.DimProductor (
                ProductorSK, ProductorID, NombreProductor, RUC, Distrito, Categoria,
                Certificaciones, TieneGlobalGAP, TieneSMETA, TieneBRC, TieneOrganico,
                FechaInicio, FechaFin, EsActual
            )
            SELECT
                CAST(ProductorSK AS INT),
                ProductorID, NombreProductor, RUC, Distrito, Categoria,
                Certificaciones,
                CAST(TieneGlobalGAP AS BIT),
                CAST(TieneSMETA AS BIT),
                CAST(TieneBRC AS BIT),
                CAST(TieneOrganico AS BIT),
                CAST(FechaInicio AS DATE),
                CAST(FechaFin AS DATE),
                CAST(EsActual AS BIT)
            FROM stg.DimProductor;
        END
        ELSE IF @Modo = N'MERGE'
        BEGIN
            -- 1) Cerrar versiones cuyos atributos cambiaron
            UPDATE d
            SET d.EsActual = 0,
                d.FechaFin = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
            FROM dw.DimProductor d
            INNER JOIN stg.DimProductor s
                ON d.ProductorID = s.ProductorID
                AND d.EsActual = 1
            WHERE
                d.NombreProductor <> s.NombreProductor
                OR d.Categoria <> s.Categoria
                OR d.Certificaciones <> s.Certificaciones
                OR d.RUC <> s.RUC
                OR d.Distrito <> s.Distrito;

            -- 2) Insertar nuevas versiones (cambios) y productores nuevos
            DECLARE @MaxSK INT = (SELECT ISNULL(MAX(ProductorSK), 0) FROM dw.DimProductor);

            INSERT INTO dw.DimProductor (
                ProductorSK, ProductorID, NombreProductor, RUC, Distrito, Categoria,
                Certificaciones, TieneGlobalGAP, TieneSMETA, TieneBRC, TieneOrganico,
                FechaInicio, FechaFin, EsActual
            )
            SELECT
                @MaxSK + ROW_NUMBER() OVER (ORDER BY s.ProductorID),
                s.ProductorID, s.NombreProductor, s.RUC, s.Distrito, s.Categoria,
                s.Certificaciones,
                CAST(s.TieneGlobalGAP AS BIT),
                CAST(s.TieneSMETA AS BIT),
                CAST(s.TieneBRC AS BIT),
                CAST(s.TieneOrganico AS BIT),
                CAST(GETDATE() AS DATE),
                CAST('2099-12-31' AS DATE),
                1
            FROM stg.DimProductor s
            WHERE NOT EXISTS (
                SELECT 1 FROM dw.DimProductor d
                WHERE d.ProductorID = s.ProductorID AND d.EsActual = 1
            );
        END
        ELSE
            THROW 50001, 'Modo inválido. Use FULL o MERGE.', 1;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimProductorSCD2', 'INFO',
                CONCAT('Modo ', @Modo, ' OK'),
                (SELECT COUNT(*) FROM dw.DimProductor),
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimProductorSCD2', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ==========================================================================
-- DimPrecioRefSUNAT SCD2
-- ==========================================================================
IF OBJECT_ID('dw.usp_LoadDimPrecioRefSUNATSCD2') IS NOT NULL DROP PROCEDURE dw.usp_LoadDimPrecioRefSUNATSCD2;
GO

CREATE PROCEDURE dw.usp_LoadDimPrecioRefSUNATSCD2
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Inicio DATETIME2 = SYSDATETIME();

    BEGIN TRY

        INSERT INTO dw.DimPrecioRefSUNAT (
            PrecioRefSK, Anio, Mes,
            FOBPromedioSector_USDxKg, FOBPromedioPais_USDxKg,
            FechaInicio, FechaFin, EsActual
        )
        SELECT
            CAST(PrecioRefSK AS INT),
            CAST(Anio AS SMALLINT),
            CAST(Mes AS TINYINT),
            CAST(FOBPromedioSector_USDxKg AS DECIMAL(10, 4)),
            CAST(FOBPromedioPais_USDxKg AS DECIMAL(10, 4)),
            CAST(FechaInicio AS DATE),
            CAST(FechaFin AS DATE),
            CAST(EsActual AS BIT)
        FROM stg.DimPrecioRefSUNAT;

        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
        VALUES (@BatchID, 'dw.usp_LoadDimPrecioRefSUNATSCD2', 'INFO', 'OK', @@ROWCOUNT,
                DATEDIFF(SECOND, @Inicio, SYSDATETIME()));
    END TRY
    BEGIN CATCH
        INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
        VALUES (@BatchID, 'dw.usp_LoadDimPrecioRefSUNATSCD2', 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

PRINT 'SPs SCD2 creados.';
GO

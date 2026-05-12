/*
================================================================================
Archivo:    21_sp_load_staging.sql
Propósito:  Stored Procedures que cargan los CSVs a las tablas staging usando BULK INSERT.

PARÁMETROS GLOBALES:
    @DataPath  - Carpeta absoluta donde están los CSVs (ej: 'C:\proyectos\piquillo-bi\data\raw\')
    @BatchID   - GUID identificador del batch de carga (compartido entre SPs)

NOTA: SQL Server necesita que los CSVs estén en una ruta accesible por el motor.
      Si el archivo está en otra máquina, usar UNC path o copiar localmente.
================================================================================
*/
USE PiquilloBI_DW;
GO

-- ====================================================================
-- SP maestro: carga staging completa
-- ====================================================================
IF OBJECT_ID('stg.usp_LoadStaging') IS NOT NULL DROP PROCEDURE stg.usp_LoadStaging;
GO

CREATE PROCEDURE stg.usp_LoadStaging
    @DataPath NVARCHAR(500),
    @BatchID UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @BatchID IS NULL SET @BatchID = NEWID();

    DECLARE @InicioProc DATETIME2 = SYSDATETIME();
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TablaActual NVARCHAR(100);
    DECLARE @ArchivoActual NVARCHAR(500);
    DECLARE @InicioTabla DATETIME2;

    INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
    VALUES (@BatchID, 'stg.usp_LoadStaging', 'INICIO',
            CONCAT('Inicio de carga staging desde ', @DataPath));

    -- Tabla de control: lista de tablas a cargar
    DECLARE @Tablas TABLE (
        Orden INT,
        TablaDestino NVARCHAR(100),
        ArchivoCSV NVARCHAR(100)
    );

    INSERT INTO @Tablas VALUES
        (1,  'stg.DimFecha',         'DimFecha.csv'),
        (2,  'stg.DimProductor',     'DimProductor.csv'),
        (3,  'stg.DimFundo',         'DimFundo.csv'),
        (4,  'stg.DimParcela',       'DimParcela.csv'),
        (5,  'stg.DimCuadrilla',     'DimCuadrilla.csv'),
        (6,  'stg.DimPlanta',        'DimPlanta.csv'),
        (7,  'stg.DimLineaProceso',  'DimLineaProceso.csv'),
        (8,  'stg.DimFormato',       'DimFormato.csv'),
        (9,  'stg.DimCliente',       'DimCliente.csv'),
        (10, 'stg.DimDestino',       'DimDestino.csv'),
        (11, 'stg.DimNaviera',       'DimNaviera.csv'),
        (12, 'stg.DimIncoterm',      'DimIncoterm.csv'),
        (13, 'stg.DimPrecioRefSUNAT','DimPrecioRefSUNAT.csv'),
        (14, 'stg.FactCosecha',      'FactCosecha.csv'),
        (15, 'stg.FactProceso',      'FactProceso.csv'),
        (16, 'stg.FactDespacho',     'FactDespacho.csv');

    DECLARE cur_tablas CURSOR LOCAL FAST_FORWARD FOR
        SELECT TablaDestino, ArchivoCSV FROM @Tablas ORDER BY Orden;

    OPEN cur_tablas;
    FETCH NEXT FROM cur_tablas INTO @TablaActual, @ArchivoActual;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @InicioTabla = SYSDATETIME();

            -- Truncar staging
            SET @SQL = N'TRUNCATE TABLE ' + @TablaActual + N';';
            EXEC sp_executesql @SQL;

            -- Bulk insert
            -- ROWTERMINATOR = 0x0d0a (CRLF Windows). Los CSV se generaron en Windows.
            -- FORMAT = 'CSV' está disponible en SQL Server 2017+ y maneja
            -- comillas en campos de texto automáticamente.
            SET @SQL = N'
                BULK INSERT ' + @TablaActual + N'
                FROM ''' + @DataPath + @ArchivoActual + N'''
                WITH (
                    FORMAT = ''CSV'',
                    FIRSTROW = 2,
                    FIELDTERMINATOR = '','',
                    ROWTERMINATOR = ''0x0d0a'',
                    CODEPAGE = ''65001'',
                    TABLOCK
                );';
            EXEC sp_executesql @SQL;

            -- Limpieza defensiva: si por cualquier razón quedó CR (\r) o BOM
            -- pegados en alguna columna NVARCHAR, los quitamos.
            -- Genera dinámicamente: UPDATE tabla SET col = TRIM(REPLACE(REPLACE(col, CHAR(13), ''), NCHAR(65279), ''));
            DECLARE @ColsClean NVARCHAR(MAX);
            SELECT @ColsClean = STRING_AGG(
                QUOTENAME(c.name)
                + N' = LTRIM(RTRIM(REPLACE(REPLACE(' + QUOTENAME(c.name) + N', CHAR(13), N''''), NCHAR(65279), N'''')))',
                N', '
            )
            FROM sys.columns c
            INNER JOIN sys.tables t ON t.object_id = c.object_id
            INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
            WHERE s.name + N'.' + t.name = @TablaActual
              AND c.system_type_id IN (231, 239); -- NVARCHAR / NCHAR

            IF @ColsClean IS NOT NULL
            BEGIN
                SET @SQL = N'UPDATE ' + @TablaActual + N' SET ' + @ColsClean + N';';
                EXEC sp_executesql @SQL;
            END

            DECLARE @Filas BIGINT;
            SET @SQL = N'SELECT @c = COUNT(*) FROM ' + @TablaActual;
            EXEC sp_executesql @SQL, N'@c BIGINT OUTPUT', @c = @Filas OUTPUT;

            INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, FilasAfectadas, DuracionSegundos)
            VALUES (@BatchID, 'stg.usp_LoadStaging', 'INFO',
                    CONCAT('Cargado ', @TablaActual, ' desde ', @ArchivoActual),
                    @Filas,
                    DATEDIFF(SECOND, @InicioTabla, SYSDATETIME()));
        END TRY
        BEGIN CATCH
            INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje)
            VALUES (@BatchID, 'stg.usp_LoadStaging', 'ERROR',
                    CONCAT('Error cargando ', @TablaActual, ' (', @ArchivoActual, '): ', ERROR_MESSAGE()));

            CLOSE cur_tablas;
            DEALLOCATE cur_tablas;
            THROW;
        END CATCH

        FETCH NEXT FROM cur_tablas INTO @TablaActual, @ArchivoActual;
    END

    CLOSE cur_tablas;
    DEALLOCATE cur_tablas;

    INSERT INTO audit.ETLLog (BatchID, ProcedureName, EventoTipo, Mensaje, DuracionSegundos)
    VALUES (@BatchID, 'stg.usp_LoadStaging', 'FIN',
            'Carga staging completada',
            DATEDIFF(SECOND, @InicioProc, SYSDATETIME()));
END
GO

PRINT 'SP stg.usp_LoadStaging creado.';
GO

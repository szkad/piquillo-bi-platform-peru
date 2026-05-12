/*
================================================================================
Archivo:    99_deploy_all.sql
Propósito:  Script maestro que ejecuta TODOS los DDL en orden automáticamente.

USO:
    1. Abrir este archivo en SSMS.
    2. Habilitar modo SQLCMD: menú "Query" -> "SQLCMD Mode"
    3. Ejecutar (F5). Crea BD, schemas, tablas, índices, SPs y views.

NOTA: Este script NO carga datos. Para cargar:
    EXEC dw.usp_RunMasterETL @DataPath = N'C:\ruta\a\data\raw\';
================================================================================
*/

:setvar SQLPATH "."
:on error exit

PRINT '========================================================================';
PRINT 'PIQUILLO BI - Despliegue completo';
PRINT '========================================================================';

-- 1. Base de datos
:r .\00_database\00_create_database.sql

-- 2. Schemas
:r .\01_schemas\01_create_schemas.sql

-- 3. Staging
:r .\02_staging\02_stg_dimensions.sql
:r .\02_staging\03_stg_facts.sql

-- 4. Dimensiones
:r .\03_dimensions\04_dim_fecha.sql
:r .\03_dimensions\05_dim_productor_scd2.sql
:r .\03_dimensions\06_dim_fundo.sql
:r .\03_dimensions\07_dim_parcela.sql
:r .\03_dimensions\08_dim_cuadrilla.sql
:r .\03_dimensions\09_dim_planta.sql
:r .\03_dimensions\10_dim_linea_proceso.sql
:r .\03_dimensions\11_dim_formato.sql
:r .\03_dimensions\12_dim_cliente.sql
:r .\03_dimensions\13_dim_destino.sql
:r .\03_dimensions\14_dim_naviera.sql
:r .\03_dimensions\15_dim_incoterm.sql
:r .\03_dimensions\16_dim_precio_ref_sunat_scd2.sql

-- 5. Hechos
:r .\04_facts\17_fact_cosecha.sql
:r .\04_facts\18_fact_proceso.sql
:r .\04_facts\19_fact_despacho.sql

-- 6. Audit (ANTES de los SPs, porque los SPs lo usan)
:r .\08_audit\27_audit_log.sql

-- 7. Stored Procedures
:r .\06_stored_procedures\21_sp_load_staging.sql
:r .\06_stored_procedures\22_sp_load_dimensions.sql
:r .\06_stored_procedures\23_sp_merge_scd2.sql
:r .\06_stored_procedures\24_sp_load_facts.sql
:r .\06_stored_procedures\25_sp_master_etl.sql

-- 8. Índices
:r .\05_indexes\20_indexes.sql

-- 9. Views para Power BI
:r .\07_views\26_views_powerbi.sql

PRINT '========================================================================';
PRINT 'Despliegue completo. Siguiente paso:';
PRINT '  EXEC dw.usp_RunMasterETL @DataPath = N''<ruta>\data\raw\'';';
PRINT '========================================================================';
GO

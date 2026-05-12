/*
================================================================================
Archivo:    01_create_schemas.sql
Propósito:  Crear schemas lógicos del DW
            - stg : Staging (datos crudos importados)
            - dw  : Datawarehouse (modelo dimensional)
            - audit : Logs de carga
            - rpt : Views para Power BI (capa semántica)
================================================================================
*/
USE PiquilloBI_DW;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg AUTHORIZATION dbo');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC('CREATE SCHEMA dw AUTHORIZATION dbo');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit')
    EXEC('CREATE SCHEMA audit AUTHORIZATION dbo');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rpt')
    EXEC('CREATE SCHEMA rpt AUTHORIZATION dbo');
GO

PRINT 'Schemas creados: stg, dw, audit, rpt';
GO

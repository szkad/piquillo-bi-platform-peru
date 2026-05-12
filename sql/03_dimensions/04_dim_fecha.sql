/*
================================================================================
Archivo:    04_dim_fecha.sql
Propósito:  DimFecha - role-playing dimension para todas las fechas.
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimFecha') IS NOT NULL DROP TABLE dw.DimFecha;
GO

CREATE TABLE dw.DimFecha (
    FechaID INT NOT NULL,
    Fecha DATE NOT NULL,
    Anio SMALLINT NOT NULL,
    Trimestre TINYINT NOT NULL,
    Mes TINYINT NOT NULL,
    NombreMes NVARCHAR(20) NOT NULL,
    Semana TINYINT NOT NULL,
    DiaMes TINYINT NOT NULL,
    DiaSemana TINYINT NOT NULL,
    NombreDiaSemana NVARCHAR(20) NOT NULL,
    EsFinDeSemana BIT NOT NULL,
    EsFeriado BIT NOT NULL,
    Campania SMALLINT NOT NULL,
    AnioMes AS (Anio * 100 + Mes) PERSISTED,
    NombreMesCorto AS (LEFT(NombreMes, 3)) PERSISTED,
    CONSTRAINT PK_DimFecha PRIMARY KEY CLUSTERED (FechaID)
);
GO

PRINT 'dw.DimFecha creada.';
GO

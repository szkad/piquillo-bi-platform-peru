/*
================================================================================
Archivo:    16_dim_precio_ref_sunat_scd2.sql
Propósito:  DimPrecioRefSUNAT - precio FOB referencial mensual del sector.
            Usado para comparar nuestro precio FOB vs. promedio sector.
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimPrecioRefSUNAT') IS NOT NULL DROP TABLE dw.DimPrecioRefSUNAT;
GO

CREATE TABLE dw.DimPrecioRefSUNAT (
    PrecioRefSK INT NOT NULL,
    Anio SMALLINT NOT NULL,
    Mes TINYINT NOT NULL,
    AnioMes AS (Anio * 100 + Mes) PERSISTED,
    FOBPromedioSector_USDxKg DECIMAL(10, 4) NOT NULL,
    FOBPromedioPais_USDxKg DECIMAL(10, 4) NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    EsActual BIT NOT NULL,
    CONSTRAINT PK_DimPrecioRefSUNAT PRIMARY KEY CLUSTERED (PrecioRefSK),
    CONSTRAINT CK_DimPrecioRefSUNAT_Mes CHECK (Mes BETWEEN 1 AND 12)
);
GO

CREATE NONCLUSTERED INDEX IX_DimPrecioRefSUNAT_AnioMes
    ON dw.DimPrecioRefSUNAT (Anio, Mes)
    INCLUDE (FOBPromedioSector_USDxKg, FOBPromedioPais_USDxKg);
GO

PRINT 'dw.DimPrecioRefSUNAT creada.';
GO

/*
================================================================================
Archivo:    05_dim_productor_scd2.sql
Propósito:  DimProductor con historia SCD Tipo 2.
            ProductorSK = surrogate key (cambia con cada versión)
            ProductorID = business key (estable)
            Hechos referencian ProductorSK (versión vigente al momento del evento)
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimProductor') IS NOT NULL DROP TABLE dw.DimProductor;
GO

CREATE TABLE dw.DimProductor (
    ProductorSK INT NOT NULL,
    ProductorID NVARCHAR(20) NOT NULL,
    NombreProductor NVARCHAR(200) NOT NULL,
    RUC NVARCHAR(20) NOT NULL,
    Distrito NVARCHAR(100) NOT NULL,
    Categoria NVARCHAR(50) NOT NULL,
    Certificaciones NVARCHAR(500) NOT NULL,
    TieneGlobalGAP BIT NOT NULL,
    TieneSMETA BIT NOT NULL,
    TieneBRC BIT NOT NULL,
    TieneOrganico BIT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    EsActual BIT NOT NULL,
    NumCertificaciones AS (
        CAST(TieneGlobalGAP AS TINYINT)
        + CAST(TieneSMETA AS TINYINT)
        + CAST(TieneBRC AS TINYINT)
        + CAST(TieneOrganico AS TINYINT)
    ) PERSISTED,
    CONSTRAINT PK_DimProductor PRIMARY KEY CLUSTERED (ProductorSK),
    CONSTRAINT CK_DimProductor_Categoria CHECK (Categoria IN (N'Pequeño', N'Mediano', N'Grande')),
    CONSTRAINT CK_DimProductor_Fechas CHECK (FechaFin >= FechaInicio)
);
GO

CREATE NONCLUSTERED INDEX IX_DimProductor_BusinessKey
    ON dw.DimProductor (ProductorID, EsActual)
    INCLUDE (ProductorSK, Categoria, NumCertificaciones);
GO

PRINT 'dw.DimProductor creada.';
GO

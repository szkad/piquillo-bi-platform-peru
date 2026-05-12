/*
================================================================================
Archivo:    13_dim_destino.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimDestino') IS NOT NULL DROP TABLE dw.DimDestino;
GO

CREATE TABLE dw.DimDestino (
    DestinoID NVARCHAR(20) NOT NULL,
    Pais NVARCHAR(100) NOT NULL,
    Puerto NVARCHAR(100) NOT NULL,
    Region NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_DimDestino PRIMARY KEY CLUSTERED (DestinoID)
);
GO

PRINT 'dw.DimDestino creada.';
GO

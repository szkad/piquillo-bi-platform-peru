/*
================================================================================
Archivo:    11_dim_formato.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimFormato') IS NOT NULL DROP TABLE dw.DimFormato;
GO

CREATE TABLE dw.DimFormato (
    FormatoID NVARCHAR(20) NOT NULL,
    CodFormato NVARCHAR(50) NOT NULL,
    Tipo NVARCHAR(50) NOT NULL,
    Envase NVARCHAR(50) NOT NULL,
    PesoNetoGr INT NOT NULL,
    UnidadesPorCaja SMALLINT NOT NULL,
    PesoCajaKg AS (CAST(PesoNetoGr AS DECIMAL(10,2)) * UnidadesPorCaja / 1000.0) PERSISTED,
    CONSTRAINT PK_DimFormato PRIMARY KEY CLUSTERED (FormatoID)
);
GO

PRINT 'dw.DimFormato creada.';
GO

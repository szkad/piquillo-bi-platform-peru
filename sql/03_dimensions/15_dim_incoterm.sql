/*
================================================================================
Archivo:    15_dim_incoterm.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimIncoterm') IS NOT NULL DROP TABLE dw.DimIncoterm;
GO

CREATE TABLE dw.DimIncoterm (
    IncotermID NVARCHAR(20) NOT NULL,
    Codigo NVARCHAR(20) NOT NULL,
    Descripcion NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_DimIncoterm PRIMARY KEY CLUSTERED (IncotermID)
);
GO

PRINT 'dw.DimIncoterm creada.';
GO

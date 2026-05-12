/*
================================================================================
Archivo:    06_dim_fundo.sql
Propósito:  DimFundo (SCD1).
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimFundo') IS NOT NULL DROP TABLE dw.DimFundo;
GO

CREATE TABLE dw.DimFundo (
    FundoID NVARCHAR(20) NOT NULL,
    NombreFundo NVARCHAR(200) NOT NULL,
    ProductorID NVARCHAR(20) NOT NULL,
    Distrito NVARCHAR(100) NOT NULL,
    Provincia NVARCHAR(100) NOT NULL,
    HectareasTotales DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_DimFundo PRIMARY KEY CLUSTERED (FundoID)
);
GO

PRINT 'dw.DimFundo creada.';
GO

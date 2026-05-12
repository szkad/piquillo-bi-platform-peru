/*
================================================================================
Archivo:    14_dim_naviera.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimNaviera') IS NOT NULL DROP TABLE dw.DimNaviera;
GO

CREATE TABLE dw.DimNaviera (
    NavieraID NVARCHAR(20) NOT NULL,
    NombreNaviera NVARCHAR(200) NOT NULL,
    RutaTipica NVARCHAR(200) NOT NULL,
    CONSTRAINT PK_DimNaviera PRIMARY KEY CLUSTERED (NavieraID)
);
GO

PRINT 'dw.DimNaviera creada.';
GO

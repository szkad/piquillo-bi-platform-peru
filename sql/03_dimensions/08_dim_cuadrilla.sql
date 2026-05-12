/*
================================================================================
Archivo:    08_dim_cuadrilla.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimCuadrilla') IS NOT NULL DROP TABLE dw.DimCuadrilla;
GO

CREATE TABLE dw.DimCuadrilla (
    CuadrillaID NVARCHAR(20) NOT NULL,
    CodCuadrilla NVARCHAR(20) NOT NULL,
    NombreSupervisor NVARCHAR(200) NOT NULL,
    NumPersonas SMALLINT NOT NULL,
    CONSTRAINT PK_DimCuadrilla PRIMARY KEY CLUSTERED (CuadrillaID)
);
GO

PRINT 'dw.DimCuadrilla creada.';
GO

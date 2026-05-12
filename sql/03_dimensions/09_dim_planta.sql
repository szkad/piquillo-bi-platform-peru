/*
================================================================================
Archivo:    09_dim_planta.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimPlanta') IS NOT NULL DROP TABLE dw.DimPlanta;
GO

CREATE TABLE dw.DimPlanta (
    PlantaID NVARCHAR(20) NOT NULL,
    NombrePlanta NVARCHAR(200) NOT NULL,
    Ubicacion NVARCHAR(200) NOT NULL,
    CapacidadDiariaKg INT NOT NULL,
    CONSTRAINT PK_DimPlanta PRIMARY KEY CLUSTERED (PlantaID)
);
GO

PRINT 'dw.DimPlanta creada.';
GO

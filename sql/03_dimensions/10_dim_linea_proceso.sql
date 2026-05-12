/*
================================================================================
Archivo:    10_dim_linea_proceso.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimLineaProceso') IS NOT NULL DROP TABLE dw.DimLineaProceso;
GO

CREATE TABLE dw.DimLineaProceso (
    LineaProcesoID NVARCHAR(20) NOT NULL,
    CodLinea NVARCHAR(50) NOT NULL,
    PlantaID NVARCHAR(20) NOT NULL,
    TipoFormatoDedicado NVARCHAR(50) NOT NULL,
    CapacidadKgHora INT NOT NULL,
    CONSTRAINT PK_DimLineaProceso PRIMARY KEY CLUSTERED (LineaProcesoID),
    CONSTRAINT FK_DimLineaProceso_Planta FOREIGN KEY (PlantaID) REFERENCES dw.DimPlanta (PlantaID),
    CONSTRAINT CK_DimLineaProceso_Tipo CHECK (TipoFormatoDedicado IN (N'Entero', N'Tiras', N'Crema'))
);
GO

PRINT 'dw.DimLineaProceso creada.';
GO

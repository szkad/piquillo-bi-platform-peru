/*
================================================================================
Archivo:    07_dim_parcela.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimParcela') IS NOT NULL DROP TABLE dw.DimParcela;
GO

CREATE TABLE dw.DimParcela (
    ParcelaID NVARCHAR(20) NOT NULL,
    CodParcela NVARCHAR(50) NOT NULL,
    FundoID NVARCHAR(20) NOT NULL,
    Variedad NVARCHAR(100) NOT NULL,
    AreaHa DECIMAL(8, 2) NOT NULL,
    AnioPlantacion SMALLINT NOT NULL,
    EdadPlantacion AS (DATEPART(YEAR, GETDATE()) - AnioPlantacion),
    CONSTRAINT PK_DimParcela PRIMARY KEY CLUSTERED (ParcelaID),
    CONSTRAINT FK_DimParcela_Fundo FOREIGN KEY (FundoID) REFERENCES dw.DimFundo (FundoID)
);
GO

PRINT 'dw.DimParcela creada.';
GO

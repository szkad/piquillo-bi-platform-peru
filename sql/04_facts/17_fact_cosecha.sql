/*
================================================================================
Archivo:    17_fact_cosecha.sql
Propósito:  FactCosecha - hechos de cosecha por evento día/parcela/cuadrilla.
            ProductorSK referencia la versión SCD2 vigente al momento de la cosecha.
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.FactCosecha') IS NOT NULL DROP TABLE dw.FactCosecha;
GO

CREATE TABLE dw.FactCosecha (
    CosechaID INT NOT NULL,
    FechaID INT NOT NULL,
    FundoID NVARCHAR(20) NOT NULL,
    ParcelaID NVARCHAR(20) NOT NULL,
    CuadrillaID NVARCHAR(20) NOT NULL,
    ProductorSK INT NOT NULL,
    LoteCampoID NVARCHAR(50) NOT NULL,
    Campania SMALLINT NOT NULL,
    KgCosechados DECIMAL(12, 2) NOT NULL,
    KgRechazadosCampo DECIMAL(12, 2) NOT NULL,
    KgLimpios AS (KgCosechados - KgRechazadosCampo) PERSISTED,
    HorasHombre DECIMAL(10, 2) NOT NULL,
    CostoCosechaSoles DECIMAL(12, 2) NOT NULL,
    CostoUnitarioSolesXKg AS (
        CASE WHEN KgCosechados > 0 THEN CostoCosechaSoles / KgCosechados ELSE 0 END
    ) PERSISTED,
    TasaRechazoCampo AS (
        CASE WHEN KgCosechados > 0 THEN KgRechazadosCampo / KgCosechados ELSE 0 END
    ) PERSISTED,
    ProductividadKgXHH AS (
        CASE WHEN HorasHombre > 0 THEN KgCosechados / HorasHombre ELSE 0 END
    ) PERSISTED,
    CONSTRAINT PK_FactCosecha PRIMARY KEY CLUSTERED (CosechaID),
    CONSTRAINT FK_FactCosecha_Fecha FOREIGN KEY (FechaID) REFERENCES dw.DimFecha (FechaID),
    CONSTRAINT FK_FactCosecha_Fundo FOREIGN KEY (FundoID) REFERENCES dw.DimFundo (FundoID),
    CONSTRAINT FK_FactCosecha_Parcela FOREIGN KEY (ParcelaID) REFERENCES dw.DimParcela (ParcelaID),
    CONSTRAINT FK_FactCosecha_Cuadrilla FOREIGN KEY (CuadrillaID) REFERENCES dw.DimCuadrilla (CuadrillaID),
    CONSTRAINT FK_FactCosecha_Productor FOREIGN KEY (ProductorSK) REFERENCES dw.DimProductor (ProductorSK)
);
GO

PRINT 'dw.FactCosecha creada.';
GO

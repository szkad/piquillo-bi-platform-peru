/*
================================================================================
Archivo:    18_fact_proceso.sql
Propósito:  FactProceso - lote de proceso en planta.
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.FactProceso') IS NOT NULL DROP TABLE dw.FactProceso;
GO

CREATE TABLE dw.FactProceso (
    LoteProcesoID NVARCHAR(50) NOT NULL,
    FechaIngresoID INT NOT NULL,
    FechaSalidaID INT NOT NULL,
    PlantaID NVARCHAR(20) NOT NULL,
    LineaProcesoID NVARCHAR(20) NOT NULL,
    FormatoID NVARCHAR(20) NOT NULL,
    LoteCampoOrigenID NVARCHAR(50) NULL,
    Campania SMALLINT NOT NULL,
    KgIngresoMP DECIMAL(12, 2) NOT NULL,
    KgProductoTerminado DECIMAL(12, 2) NOT NULL,
    KgMermaProceso DECIMAL(12, 2) NOT NULL,
    KgRechazoCalidad DECIMAL(12, 2) NOT NULL,
    HorasOperacion DECIMAL(10, 2) NOT NULL,
    CostoProcesoSoles DECIMAL(12, 2) NOT NULL,
    RendimientoProceso AS (
        CASE WHEN KgIngresoMP > 0 THEN KgProductoTerminado / KgIngresoMP ELSE 0 END
    ) PERSISTED,
    TasaMermaProceso AS (
        CASE WHEN KgIngresoMP > 0 THEN KgMermaProceso / KgIngresoMP ELSE 0 END
    ) PERSISTED,
    TasaRechazoCalidad AS (
        CASE WHEN KgIngresoMP > 0 THEN KgRechazoCalidad / KgIngresoMP ELSE 0 END
    ) PERSISTED,
    CostoUnitarioSolesXKgPT AS (
        CASE WHEN KgProductoTerminado > 0 THEN CostoProcesoSoles / KgProductoTerminado ELSE 0 END
    ) PERSISTED,
    DiasEnPlanta AS (DATEDIFF(DAY,
        CONVERT(DATE, CAST(FechaIngresoID AS VARCHAR(8)), 112),
        CONVERT(DATE, CAST(FechaSalidaID AS VARCHAR(8)), 112)
    )),
    CONSTRAINT PK_FactProceso PRIMARY KEY CLUSTERED (LoteProcesoID),
    CONSTRAINT FK_FactProceso_FechaIng FOREIGN KEY (FechaIngresoID) REFERENCES dw.DimFecha (FechaID),
    CONSTRAINT FK_FactProceso_FechaSal FOREIGN KEY (FechaSalidaID) REFERENCES dw.DimFecha (FechaID),
    CONSTRAINT FK_FactProceso_Planta FOREIGN KEY (PlantaID) REFERENCES dw.DimPlanta (PlantaID),
    CONSTRAINT FK_FactProceso_Linea FOREIGN KEY (LineaProcesoID) REFERENCES dw.DimLineaProceso (LineaProcesoID),
    CONSTRAINT FK_FactProceso_Formato FOREIGN KEY (FormatoID) REFERENCES dw.DimFormato (FormatoID)
);
GO

PRINT 'dw.FactProceso creada.';
GO

/*
================================================================================
Archivo:    19_fact_despacho.sql
Propósito:  FactDespacho - despacho/contenedor exportado.
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.FactDespacho') IS NOT NULL DROP TABLE dw.FactDespacho;
GO

CREATE TABLE dw.FactDespacho (
    DespachoID INT NOT NULL,
    FechaDespachoID INT NOT NULL,
    ClienteID NVARCHAR(20) NOT NULL,
    DestinoID NVARCHAR(20) NOT NULL,
    FormatoID NVARCHAR(20) NOT NULL,
    NavieraID NVARCHAR(20) NOT NULL,
    IncotermID NVARCHAR(20) NOT NULL,
    LoteProcesoID NVARCHAR(50) NOT NULL,
    Campania SMALLINT NOT NULL,
    ContenedorNum NVARCHAR(50) NOT NULL,
    NumPallets SMALLINT NOT NULL,
    KgNetosExportados DECIMAL(12, 2) NOT NULL,
    ValorFOB_USD DECIMAL(14, 2) NOT NULL,
    CostoLogisticoUSD DECIMAL(12, 2) NOT NULL,
    DiasTransitoComprometidos SMALLINT NOT NULL,
    DiasTransitoReales SMALLINT NOT NULL,
    EstadoDespacho NVARCHAR(20) NOT NULL,
    FOBUnitarioUSDxKg AS (
        CASE WHEN KgNetosExportados > 0 THEN ValorFOB_USD / KgNetosExportados ELSE 0 END
    ) PERSISTED,
    CostoLogisticoUnitarioUSDxKg AS (
        CASE WHEN KgNetosExportados > 0 THEN CostoLogisticoUSD / KgNetosExportados ELSE 0 END
    ) PERSISTED,
    MargenBrutoUSD AS (ValorFOB_USD - CostoLogisticoUSD) PERSISTED,
    DesvTransitoDias AS (DiasTransitoReales - DiasTransitoComprometidos) PERSISTED,
    EsOnTime AS (CAST(CASE WHEN EstadoDespacho IN (N'OnTime', N'Early') THEN 1 ELSE 0 END AS BIT)) PERSISTED,
    CONSTRAINT PK_FactDespacho PRIMARY KEY CLUSTERED (DespachoID),
    CONSTRAINT FK_FactDespacho_Fecha FOREIGN KEY (FechaDespachoID) REFERENCES dw.DimFecha (FechaID),
    CONSTRAINT FK_FactDespacho_Cliente FOREIGN KEY (ClienteID) REFERENCES dw.DimCliente (ClienteID),
    CONSTRAINT FK_FactDespacho_Destino FOREIGN KEY (DestinoID) REFERENCES dw.DimDestino (DestinoID),
    CONSTRAINT FK_FactDespacho_Formato FOREIGN KEY (FormatoID) REFERENCES dw.DimFormato (FormatoID),
    CONSTRAINT FK_FactDespacho_Naviera FOREIGN KEY (NavieraID) REFERENCES dw.DimNaviera (NavieraID),
    CONSTRAINT FK_FactDespacho_Incoterm FOREIGN KEY (IncotermID) REFERENCES dw.DimIncoterm (IncotermID),
    CONSTRAINT FK_FactDespacho_Proceso FOREIGN KEY (LoteProcesoID) REFERENCES dw.FactProceso (LoteProcesoID),
    CONSTRAINT CK_FactDespacho_Estado CHECK (EstadoDespacho IN (N'OnTime', N'Late', N'Early'))
);
GO

PRINT 'dw.FactDespacho creada.';
GO

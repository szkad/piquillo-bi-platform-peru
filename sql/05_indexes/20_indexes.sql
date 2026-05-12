/*
================================================================================
Archivo:    20_indexes.sql
Propósito:  Índices nonclustered para acelerar queries típicas de Power BI
            (filtros por campaña, agregaciones por fecha, joins frecuentes).
================================================================================
*/
USE PiquilloBI_DW;
GO

-- ===== FactCosecha =====
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactCosecha_Fecha' AND object_id = OBJECT_ID('dw.FactCosecha'))
    DROP INDEX IX_FactCosecha_Fecha ON dw.FactCosecha;
CREATE NONCLUSTERED INDEX IX_FactCosecha_Fecha
    ON dw.FactCosecha (FechaID)
    INCLUDE (KgCosechados, KgRechazadosCampo, CostoCosechaSoles, ParcelaID, FundoID, ProductorSK);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactCosecha_Campania' AND object_id = OBJECT_ID('dw.FactCosecha'))
    DROP INDEX IX_FactCosecha_Campania ON dw.FactCosecha;
CREATE NONCLUSTERED INDEX IX_FactCosecha_Campania
    ON dw.FactCosecha (Campania)
    INCLUDE (KgCosechados, ParcelaID, FundoID);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactCosecha_Productor' AND object_id = OBJECT_ID('dw.FactCosecha'))
    DROP INDEX IX_FactCosecha_Productor ON dw.FactCosecha;
CREATE NONCLUSTERED INDEX IX_FactCosecha_Productor
    ON dw.FactCosecha (ProductorSK)
    INCLUDE (KgCosechados, FechaID);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactCosecha_LoteCampo' AND object_id = OBJECT_ID('dw.FactCosecha'))
    DROP INDEX IX_FactCosecha_LoteCampo ON dw.FactCosecha;
CREATE NONCLUSTERED INDEX IX_FactCosecha_LoteCampo
    ON dw.FactCosecha (LoteCampoID);
GO

-- ===== FactProceso =====
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactProceso_FechaIng' AND object_id = OBJECT_ID('dw.FactProceso'))
    DROP INDEX IX_FactProceso_FechaIng ON dw.FactProceso;
CREATE NONCLUSTERED INDEX IX_FactProceso_FechaIng
    ON dw.FactProceso (FechaIngresoID)
    INCLUDE (KgIngresoMP, KgProductoTerminado, FormatoID, PlantaID);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactProceso_Campania' AND object_id = OBJECT_ID('dw.FactProceso'))
    DROP INDEX IX_FactProceso_Campania ON dw.FactProceso;
CREATE NONCLUSTERED INDEX IX_FactProceso_Campania
    ON dw.FactProceso (Campania)
    INCLUDE (KgIngresoMP, KgProductoTerminado, FormatoID);
GO

-- ===== FactDespacho =====
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactDespacho_Fecha' AND object_id = OBJECT_ID('dw.FactDespacho'))
    DROP INDEX IX_FactDespacho_Fecha ON dw.FactDespacho;
CREATE NONCLUSTERED INDEX IX_FactDespacho_Fecha
    ON dw.FactDespacho (FechaDespachoID)
    INCLUDE (KgNetosExportados, ValorFOB_USD, ClienteID, DestinoID, FormatoID);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactDespacho_Cliente' AND object_id = OBJECT_ID('dw.FactDespacho'))
    DROP INDEX IX_FactDespacho_Cliente ON dw.FactDespacho;
CREATE NONCLUSTERED INDEX IX_FactDespacho_Cliente
    ON dw.FactDespacho (ClienteID)
    INCLUDE (KgNetosExportados, ValorFOB_USD, FechaDespachoID);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactDespacho_Destino' AND object_id = OBJECT_ID('dw.FactDespacho'))
    DROP INDEX IX_FactDespacho_Destino ON dw.FactDespacho;
CREATE NONCLUSTERED INDEX IX_FactDespacho_Destino
    ON dw.FactDespacho (DestinoID)
    INCLUDE (KgNetosExportados, ValorFOB_USD);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactDespacho_Campania' AND object_id = OBJECT_ID('dw.FactDespacho'))
    DROP INDEX IX_FactDespacho_Campania ON dw.FactDespacho;
CREATE NONCLUSTERED INDEX IX_FactDespacho_Campania
    ON dw.FactDespacho (Campania)
    INCLUDE (KgNetosExportados, ValorFOB_USD, ClienteID, DestinoID);
GO

PRINT 'Índices creados.';
GO

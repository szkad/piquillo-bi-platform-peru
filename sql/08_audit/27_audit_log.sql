/*
================================================================================
Archivo:    27_audit_log.sql
Propósito:  Tabla de log de ejecuciones del ETL para trazabilidad y debugging.
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('audit.ETLLog') IS NOT NULL DROP TABLE audit.ETLLog;
GO

CREATE TABLE audit.ETLLog (
    LogID INT IDENTITY(1, 1) NOT NULL,
    BatchID UNIQUEIDENTIFIER NOT NULL,
    ProcedureName NVARCHAR(128) NOT NULL,
    EventoTipo NVARCHAR(20) NOT NULL,
    Mensaje NVARCHAR(MAX) NULL,
    FilasAfectadas BIGINT NULL,
    FechaEvento DATETIME2(0) NOT NULL CONSTRAINT DF_ETLLog_Fecha DEFAULT (SYSDATETIME()),
    DuracionSegundos INT NULL,
    CONSTRAINT PK_ETLLog PRIMARY KEY CLUSTERED (LogID),
    CONSTRAINT CK_ETLLog_Tipo CHECK (EventoTipo IN (N'INFO', N'WARN', N'ERROR', N'INICIO', N'FIN'))
);
GO

CREATE NONCLUSTERED INDEX IX_ETLLog_Batch
    ON audit.ETLLog (BatchID, FechaEvento);
GO

PRINT 'audit.ETLLog creada.';
GO

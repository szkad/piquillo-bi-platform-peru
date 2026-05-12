/*
================================================================================
Archivo:    12_dim_cliente.sql
================================================================================
*/
USE PiquilloBI_DW;
GO

IF OBJECT_ID('dw.DimCliente') IS NOT NULL DROP TABLE dw.DimCliente;
GO

CREATE TABLE dw.DimCliente (
    ClienteID NVARCHAR(20) NOT NULL,
    RazonSocial NVARCHAR(300) NOT NULL,
    Pais NVARCHAR(100) NOT NULL,
    TipoCliente NVARCHAR(50) NOT NULL,
    AnioPrimerNegocio SMALLINT NOT NULL,
    AntiguedadAnios AS (DATEPART(YEAR, GETDATE()) - AnioPrimerNegocio),
    CONSTRAINT PK_DimCliente PRIMARY KEY CLUSTERED (ClienteID),
    CONSTRAINT CK_DimCliente_Tipo CHECK (TipoCliente IN (N'Distribuidor', N'Retailer', N'Foodservice'))
);
GO

PRINT 'dw.DimCliente creada.';
GO

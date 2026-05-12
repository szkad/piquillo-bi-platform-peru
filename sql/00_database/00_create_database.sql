/*
================================================================================
Proyecto:   Piquillo BI - AgroPiura Conservas S.A.C.
Archivo:    00_create_database.sql
Propósito:  Crear la base de datos PiquilloBI_DW
Autor:      Alexis Zapata
Fecha:      2026
================================================================================
USO:        Ejecutar UNA SOLA VEZ al inicio del despliegue.
            Si la BD ya existe, este script no la recrea (idempotente).
================================================================================
*/

USE master;
GO

IF DB_ID('PiquilloBI_DW') IS NULL
BEGIN
    PRINT 'Creando base de datos PiquilloBI_DW...';

    CREATE DATABASE PiquilloBI_DW
    COLLATE Modern_Spanish_CI_AS;

    -- Recovery model SIMPLE para DW (no necesitamos transaction log para PITR)
    ALTER DATABASE PiquilloBI_DW SET RECOVERY SIMPLE;

    -- Snapshot isolation para evitar lecturas bloqueadas durante cargas
    ALTER DATABASE PiquilloBI_DW SET ALLOW_SNAPSHOT_ISOLATION ON;
    ALTER DATABASE PiquilloBI_DW SET READ_COMMITTED_SNAPSHOT ON;

    PRINT 'Base de datos creada correctamente.';
END
ELSE
BEGIN
    PRINT 'La base de datos PiquilloBI_DW ya existe. No se hizo nada.';
END
GO

USE PiquilloBI_DW;
GO

PRINT 'Contexto cambiado a PiquilloBI_DW.';
GO

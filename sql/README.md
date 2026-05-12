# SQL Server — Datawarehouse PiquilloBI_DW

Capa de almacenamiento y procesamiento del proyecto. Implementa el modelo dimensional Kimball con SQL Server 2019.

## Arquitectura

```
        [CSVs]                [stg.*]            [dw.*]              [rpt.*]
   data/raw/*.csv  ───►  staging (NVARCHAR) ──► star schema   ──►  vistas para
                          BULK INSERT           tipado + FKs        Power BI
```

**Schemas:**
- `stg` — Staging crudo (NVARCHAR para tolerancia a errores de CSV)
- `dw` — Modelo dimensional tipado (3 hechos + 13 dimensiones)
- `audit` — Log de ejecuciones de ETL
- `rpt` — Capa semántica de views para Power BI

## Cómo desplegar

### Opción A — Despliegue automático (recomendado)

1. Abrir SSMS, conectar a tu instancia.
2. Abrir `99_deploy_all.sql`.
3. Activar **SQLCMD Mode**: menú `Query` → `SQLCMD Mode`.
4. F5. Crea BD, schemas, tablas, índices, SPs y views en orden.

### Opción B — Manual (script por script)

Ejecutar en SSMS uno por uno, en este orden:

```
00_database/00_create_database.sql
01_schemas/01_create_schemas.sql
02_staging/02_stg_dimensions.sql
02_staging/03_stg_facts.sql
03_dimensions/04_dim_fecha.sql  ... 16_dim_precio_ref_sunat_scd2.sql
04_facts/17_fact_cosecha.sql  ... 19_fact_despacho.sql
08_audit/27_audit_log.sql       (ANTES que los SPs)
06_stored_procedures/21_sp_load_staging.sql  ... 25_sp_master_etl.sql
05_indexes/20_indexes.sql
07_views/26_views_powerbi.sql
```

## Cómo cargar los datos

Una vez desplegada la estructura, generar los CSVs con Python y luego:

```sql
EXEC dw.usp_RunMasterETL
    @DataPath = N'C:\proyectos\piquillo-bi-platform-peru\data\raw\',
    @ModoSCD2 = N'FULL';
```

El SP maestro:
1. Carga staging (BULK INSERT de 16 CSVs)
2. Trunca hechos del DW
3. Carga dimensiones SCD1 (11 SPs)
4. Carga dimensiones SCD2 (Productor, PrecioRefSUNAT)
5. Carga hechos con lookup SCD2 al momento del evento
6. Loguea todo en `audit.ETLLog`

Duración esperada: 10-30 segundos para los ~19k hechos.

## Validación post-carga

Ejecutar `99_validacion_post_etl.sql` en SSMS. Valida:

- Conteo de filas
- Integridad SCD2 (cada productor con exactamente 1 fila `EsActual=1`)
- KPIs agrícolas en rango (14-28k kg/ha)
- KPIs industriales en rango (60-72% rendimiento)
- KPIs comerciales (FOB $2.80-$4.20/kg, DIFOT ~85%)
- Brecha FOB nuestro vs SUNAT
- Trazabilidad inversa Despacho → Proceso → Fundo
- Log de la última corrida

## Decisiones técnicas relevantes

| Decisión | Razón |
|---|---|
| Schema separado `stg` con NVARCHAR | Los CSV nunca fallan al cargar; conversión y validación en el paso a `dw` |
| Surrogate keys SCD2 (`ProductorSK`) | Soporta historia de cambios en categorías y certificaciones del productor |
| Computed columns persisted (Rendimiento, FOB unit, etc.) | Cálculos ya almacenados; Power BI los lee sin recalcular |
| Snapshot isolation (`READ_COMMITTED_SNAPSHOT ON`) | Evita lecturas bloqueadas durante cargas |
| `audit.ETLLog` con BatchID único por corrida | Trazabilidad y debugging |
| Views en schema `rpt` | Capa de aislamiento entre DW y Power BI |
| Índices nonclustered en FKs de hechos | Aceleran joins y filtros típicos de Power BI |
| `BULK INSERT` con `CODEPAGE = '65001'` | Soporta UTF-8 con BOM de los CSV |

## Lookup SCD2 en `FactCosecha`

El SP `usp_LoadFactCosecha` resuelve el `ProductorSK` correcto haciendo:

```sql
INNER JOIN dw.DimProductor p
    ON p.ProductorID = s.ProductorID
   AND CAST(s.FechaCosecha AS DATE) BETWEEN p.FechaInicio AND p.FechaFin
```

Esto garantiza que un evento de cosecha en 2023 referencia la versión del productor vigente en 2023, no la actual. Esa es la magia del SCD2.

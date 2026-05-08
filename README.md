# Piquillo BI - Plataforma de Análisis Agroindustrial

Dashboard de Business Intelligence end-to-end para una agroexportadora peruana
ficticia (AgroPiura Conservas S.A.C.) dedicada a la exportación de pimiento
piquillo en conserva.

**Stack:** Python · SQL Server · Power BI · Tabular Editor · DAX

## Estado del proyecto

🟡 **En construcción** — Fase 2 de 5 completada (generación de datos sintéticos).

## Estructura

```
piquillo-bi-platform-peru/
├── python/         # Generador de datos sintéticos
├── sql/            # DDL + Stored Procedures + Views (próximo)
├── powerbi/        # Modelo y dashboard (próximo)
├── docs/           # Documentación técnica
└── data/
    └── samples/    # Muestras 10% (versionadas)
```

## Quickstart

```bash
cd python
python -m venv .venv
source .venv/bin/activate  # o .venv\Scripts\activate en Windows
pip install -r requirements.txt
python orchestrator.py
```

Genera los CSVs en `data/raw/` (no versionado).

## Volumetría

| Tabla | Filas |
|---|---|
| FactCosecha | ~13,000 |
| FactProceso | ~2,700 |
| FactDespacho | ~3,400 |
| Total hechos | ~19,000 |

## KPIs validados

- Rendimiento agrícola: 18,000 kg/ha promedio (rango 14-28k)
- Rendimiento proceso: 70% (rango realista 60-72%)
- FOB promedio: $3.86 USD/kg
- DIFOT: 85%

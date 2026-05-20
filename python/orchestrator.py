"""
Orquestador maestro - Genera todos los CSVs del proyecto Piquillo BI.

Uso:
    cd python
    python orchestrator.py

Salida: archivos CSV en data/raw/ (ignorado por git)
        muestras 10% en data/samples/ (sí versionadas)
"""
from __future__ import annotations

import logging
import sys
from datetime import date
from pathlib import Path

import numpy as np
import pandas as pd
import yaml
from faker import Faker
from tqdm import tqdm

from generators import dim_generator as dg
from generators.fact_cosecha_generator import generar_fact_cosecha
from generators.fact_proceso_generator import generar_fact_proceso
from generators.fact_despacho_generator import generar_fact_despacho


# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger("piquillo-bi")


def cargar_config(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def guardar_csv(df: pd.DataFrame, path: Path, config_out: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(
        path,
        index=False,
        encoding=config_out["encoding"],
        sep=config_out["separador"],
        decimal=config_out["decimal"],
    )


def guardar_muestra(df: pd.DataFrame, path: Path, pct: float, config_out: dict, rng) -> None:
    """Guarda una muestra del df en samples (versionada en git)."""
    if df.empty:
        return
    n = max(50, int(len(df) * pct))
    n = min(n, len(df))
    muestra = df.sample(n=n, random_state=42).sort_index()
    guardar_csv(muestra, path, config_out)


def main():
    # ----------------------------------------------------------------------
    # 1. Cargar configuración
    # ----------------------------------------------------------------------
    base_dir = Path(__file__).resolve().parent
    config_path = base_dir / "config.yaml"
    config = cargar_config(config_path)

    seed = config["random_seed"]
    rng = np.random.default_rng(seed)
    fake = Faker("es_ES")
    Faker.seed(seed)

    data_raw = (base_dir / config["output"]["data_dir"]).resolve()
    data_samples = (base_dir / config["output"]["samples_dir"]).resolve()
    cfg_out = config["output"]

    log.info("=" * 70)
    log.info("PIQUILLO BI - Generador de datos sintéticos")
    log.info("AgroPiura Conservas S.A.C.")
    log.info("=" * 70)
    log.info("Output raw:     %s", data_raw)
    log.info("Output samples: %s", data_samples)
    log.info("Campañas:       %s", config["campanias"])
    log.info("Random seed:    %d", seed)

    # ----------------------------------------------------------------------
    # 2. Generar dimensiones
    # ----------------------------------------------------------------------
    log.info("")
    log.info("[1/4] Generando dimensiones...")

    fecha_ini = date(min(config["campanias"]) - 1, 1, 1)
    fecha_fin = date(max(config["campanias"]) + 1, 12, 31)

    dimensiones = {}
    pasos_dim = [
        ("DimFecha", lambda: dg.generar_dim_fecha(fecha_ini, fecha_fin)),
        ("DimProductor", lambda: dg.generar_dim_productor_scd2(config, rng, fake)),
        ("DimFundo", lambda: dg.generar_dim_fundo(dimensiones["DimProductor"], config, rng, fake)),
        ("DimParcela", lambda: dg.generar_dim_parcela(dimensiones["DimFundo"], dimensiones["DimProductor"], config, rng)),
        ("DimCuadrilla", lambda: dg.generar_dim_cuadrilla(config, rng, fake)),
        ("DimPlanta", lambda: dg.generar_dim_planta(config)),
        ("DimLineaProceso", lambda: dg.generar_dim_linea_proceso(dimensiones["DimPlanta"], config)),
        ("DimFormato", lambda: dg.generar_dim_formato(config)),
        ("DimCliente", lambda: dg.generar_dim_cliente(config, rng, fake)),
        ("DimDestino", lambda: dg.generar_dim_destino(config)),
        ("DimNaviera", lambda: dg.generar_dim_naviera(config)),
        ("DimIncoterm", lambda: dg.generar_dim_incoterm(config)),
        ("DimPrecioRefSUNAT", lambda: dg.generar_dim_precio_ref_sunat_scd2(config, rng)),
    ]

    for nombre, fn in tqdm(pasos_dim, desc="Dimensiones", ncols=80):
        df = fn()
        dimensiones[nombre] = df
        guardar_csv(df, data_raw / f"{nombre}.csv", cfg_out)
        if cfg_out.get("generar_muestras"):
            guardar_muestra(df, data_samples / f"sample_{nombre}.csv",
                            cfg_out["porcentaje_muestra"], cfg_out, rng)

    # ----------------------------------------------------------------------
    # 3. Generar hechos
    # ----------------------------------------------------------------------
    log.info("")
    log.info("[2/4] Generando FactCosecha...")
    df_cosecha = generar_fact_cosecha(
        dimensiones["DimParcela"],
        dimensiones["DimFundo"],
        dimensiones["DimProductor"],
        dimensiones["DimCuadrilla"],
        config, rng,
    )
    guardar_csv(df_cosecha, data_raw / "FactCosecha.csv", cfg_out)
    if cfg_out.get("generar_muestras"):
        guardar_muestra(df_cosecha, data_samples / "sample_FactCosecha.csv",
                        cfg_out["porcentaje_muestra"], cfg_out, rng)
    log.info("    -> %d filas", len(df_cosecha))

    log.info("")
    log.info("[3/4] Generando FactProceso...")
    df_proceso = generar_fact_proceso(
        df_cosecha,
        dimensiones["DimPlanta"],
        dimensiones["DimLineaProceso"],
        dimensiones["DimFormato"],
        config, rng,
    )
    guardar_csv(df_proceso, data_raw / "FactProceso.csv", cfg_out)
    if cfg_out.get("generar_muestras"):
        guardar_muestra(df_proceso, data_samples / "sample_FactProceso.csv",
                        cfg_out["porcentaje_muestra"], cfg_out, rng)
    log.info("    -> %d filas", len(df_proceso))

    log.info("")
    log.info("[4/4] Generando FactDespacho...")
    df_despacho = generar_fact_despacho(
        df_proceso,
        dimensiones["DimProductor"],
        df_cosecha,
        dimensiones["DimCliente"],
        dimensiones["DimDestino"],
        dimensiones["DimNaviera"],
        dimensiones["DimIncoterm"],
        dimensiones["DimFormato"],
        dimensiones["DimPrecioRefSUNAT"],
        config, rng,
    )
    guardar_csv(df_despacho, data_raw / "FactDespacho.csv", cfg_out)
    if cfg_out.get("generar_muestras"):
        guardar_muestra(df_despacho, data_samples / "sample_FactDespacho.csv",
                        cfg_out["porcentaje_muestra"], cfg_out, rng)
    log.info("    -> %d filas", len(df_despacho))

    # ----------------------------------------------------------------------
    # 4. Resumen final
    # ----------------------------------------------------------------------
    log.info("")
    log.info("=" * 70)
    log.info("RESUMEN")
    log.info("=" * 70)
    resumen = []
    for nombre, df in dimensiones.items():
        resumen.append((nombre, len(df)))
    resumen.append(("FactCosecha", len(df_cosecha)))
    resumen.append(("FactProceso", len(df_proceso)))
    resumen.append(("FactDespacho", len(df_despacho)))

    for nombre, n in resumen:
        log.info("  %-25s %8d filas", nombre, n)

    total_hechos = len(df_cosecha) + len(df_proceso) + len(df_despacho)
    log.info("  %-25s %8d filas", "TOTAL HECHOS", total_hechos)
    log.info("=" * 70)
    log.info("Archivos en: %s", data_raw)
    log.info("OK")


if __name__ == "__main__":
    main()

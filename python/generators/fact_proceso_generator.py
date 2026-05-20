"""
Generador de FactProceso.

Cada fila = un lote de proceso en planta.
Agrupa lotes de campo cercanos en el tiempo y los procesa.
Volumetría objetivo: ~3,500 filas.
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import List

import numpy as np
import pandas as pd

from generators.seasonality import lag_proceso_dias


def generar_fact_proceso(
    df_cosecha: pd.DataFrame,
    df_planta: pd.DataFrame,
    df_linea: pd.DataFrame,
    df_formato: pd.DataFrame,
    config: dict,
    rng: np.random.Generator,
) -> pd.DataFrame:
    """
    Agrupa cosechas en lotes de proceso.
    Estrategia: cada lote de proceso consume kg "limpios" (cosechado - rechazo)
    de varios lotes de campo del mismo periodo.
    """
    rend_cfg = config["industria"]["rendimiento_proceso"]
    rechazo_cfg = config["industria"]["tasa_rechazo_calidad"]
    prod_cfg = config["industria"]["productividad_kg_hora"]
    costo_cfg = config["industria"]["costo_proceso_soles_kg_pt"]

    # Pre-cálculo: kg limpios disponibles por lote de campo
    df_cosecha = df_cosecha.copy()
    df_cosecha["KgLimpios"] = df_cosecha["KgCosechados"] - df_cosecha["KgRechazadosCampo"]
    df_cosecha = df_cosecha.sort_values("FechaCosecha").reset_index(drop=True)

    # Mapeo línea -> tipo, planta
    df_linea_idx = df_linea.set_index("LineaProcesoID")
    formatos_por_tipo = {
        "Entero": df_formato[df_formato["Tipo"] == "Entero"]["FormatoID"].tolist(),
        "Tiras": df_formato[df_formato["Tipo"] == "Tiras"]["FormatoID"].tolist(),
        "Crema": df_formato[df_formato["Tipo"] == "Crema"]["FormatoID"].tolist(),
    }

    # Agrupar cosechas por ventanas de 3 días para crear lotes de proceso
    df_cosecha["FechaIngresoEstimada"] = df_cosecha["FechaCosecha"].apply(
        lambda d: d + timedelta(days=lag_proceso_dias(rng))
    )

    # Agrupar por fecha de ingreso (día calendario)
    df_cosecha["GrupoIngresoFecha"] = df_cosecha["FechaIngresoEstimada"]

    rows: List[dict] = []
    lote_proceso_id = 1

    # Para cada día de ingreso, crear varios lotes de proceso
    for fecha_ing, grupo in df_cosecha.groupby("GrupoIngresoFecha"):
        kg_limpios_dia = grupo["KgLimpios"].sum()
        if kg_limpios_dia < 100:
            continue

        # Elegir cuántos lotes de proceso para este día (1-4)
        n_lotes = int(rng.integers(1, 5))
        # Repartir kg entre lotes
        pesos = rng.dirichlet(np.ones(n_lotes) * 1.5)
        kgs_por_lote = pesos * kg_limpios_dia

        # Lotes de campo origen (string concatenado para trazabilidad)
        lotes_campo = grupo["LoteCampoID"].tolist()

        for kg_mp in kgs_por_lote:
            kg_mp = max(50.0, float(kg_mp))

            # Asignar línea de proceso (probabilidad por mix de formatos)
            linea_id = str(rng.choice(df_linea["LineaProcesoID"].tolist()))
            tipo_linea = df_linea_idx.loc[linea_id, "TipoFormatoDedicado"]
            planta_id = df_linea_idx.loc[linea_id, "PlantaID"]
            cap_hora = df_linea_idx.loc[linea_id, "CapacidadKgHora"]

            # Formato producido por esa línea
            formato_id = str(rng.choice(formatos_por_tipo[tipo_linea]))

            # Rendimiento de proceso
            r_cfg = rend_cfg[tipo_linea]
            rendimiento = float(np.clip(
                rng.normal(r_cfg["media"], r_cfg["desv_est"]), 0.45, 0.85
            ))
            kg_pt = round(kg_mp * rendimiento, 2)
            kg_merma_total = kg_mp - kg_pt

            # De la merma, una parte es rechazo de calidad y otra merma normal
            tasa_rechazo = float(np.clip(
                rng.normal(rechazo_cfg["media"], rechazo_cfg["desv_est"]), 0.005, 0.10
            ))
            kg_rechazo = round(kg_mp * tasa_rechazo, 2)
            kg_merma_normal = round(max(0, kg_merma_total - kg_rechazo), 2)

            # Horas operación
            horas_op = round(kg_pt / cap_hora * float(rng.uniform(1.05, 1.25)), 2)

            # Costo proceso
            costo_unit = max(2.5, float(rng.normal(costo_cfg["media"], costo_cfg["desv_est"])))
            costo_total = round(kg_pt * costo_unit, 2)

            # Fechas
            fecha_ingreso = fecha_ing
            dias_proceso = int(rng.choice([1, 2, 3], p=[0.6, 0.3, 0.1]))
            fecha_salida = fecha_ingreso + timedelta(days=dias_proceso)

            # Lote campo principal (el más representativo - el primero del grupo)
            lote_campo_principal = lotes_campo[0] if lotes_campo else None

            rows.append({
                "LoteProcesoID": f"LP-{fecha_ingreso.year}-{lote_proceso_id:06d}",
                "FechaIngresoID": int(fecha_ingreso.strftime("%Y%m%d")),
                "FechaIngreso": fecha_ingreso,
                "FechaSalidaID": int(fecha_salida.strftime("%Y%m%d")),
                "FechaSalida": fecha_salida,
                "PlantaID": planta_id,
                "LineaProcesoID": linea_id,
                "FormatoID": formato_id,
                "LoteCampoOrigenID": lote_campo_principal,
                "Campania": fecha_ingreso.year,
                "KgIngresoMP": round(kg_mp, 2),
                "KgProductoTerminado": kg_pt,
                "KgMermaProceso": kg_merma_normal,
                "KgRechazoCalidad": kg_rechazo,
                "HorasOperacion": horas_op,
                "CostoProcesoSoles": costo_total,
            })
            lote_proceso_id += 1

    return pd.DataFrame(rows)

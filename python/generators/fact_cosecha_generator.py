"""
Generador de FactCosecha.

Cada fila = un evento de cosecha (fundo, parcela, cuadrilla, día).
Volumetría objetivo: ~12,000 filas para 4 campañas.
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import Dict, List

import numpy as np
import pandas as pd

from generators.seasonality import (
    factor_climatico_anio,
    get_dias_cosecha_campania,
)


def generar_fact_cosecha(
    df_parcela: pd.DataFrame,
    df_fundo: pd.DataFrame,
    df_productor: pd.DataFrame,
    df_cuadrilla: pd.DataFrame,
    config: dict,
    rng: np.random.Generator,
) -> pd.DataFrame:
    """Genera FactCosecha con eventos diarios por parcela activa."""
    rows: List[dict] = []
    cosecha_id = 1
    lote_campo_id = 1

    # Mapeos rápidos
    fundo_to_productor = df_fundo.set_index("FundoID")["ProductorID"].to_dict()
    productor_actual = (
        df_productor[df_productor["EsActual"] == 1]
        .set_index("ProductorID")["Categoria"]
        .to_dict()
    )

    # Lista de cuadrillas (ID)
    cuadrillas_ids = df_cuadrilla["CuadrillaID"].tolist()

    rend_cfg = config["agricultura"]["rendimiento_kg_por_ha"]
    rechazo_cfg = config["agricultura"]["tasa_rechazo_campo"]
    prod_cfg = config["agricultura"]["productividad_cuadrilla_kg_hh"]
    costo_cfg = config["agricultura"]["costo_cosecha_soles_kg"]
    distribucion_mensual = config["estacionalidad"]["cosecha_mes"]

    for anio in config["campanias"]:
        factor_clima = factor_climatico_anio(anio)

        # Para cada parcela activa, decidir cuántos eventos de cosecha tendrá esa campaña
        for _, parcela in df_parcela.iterrows():
            # Edad de la planta
            edad = anio - parcela["AnioPlantacion"]
            if edad < 1 or edad > 10:
                continue  # parcela no productiva

            # Factor edad (curva típica: pico a los 3-5 años)
            if edad <= 2:
                factor_edad = 0.7 + 0.15 * edad
            elif edad <= 5:
                factor_edad = 1.0
            else:
                factor_edad = max(0.6, 1.0 - 0.07 * (edad - 5))

            area = parcela["AreaHa"]
            kg_anuales_objetivo = (
                float(rng.normal(rend_cfg["media"], rend_cfg["desv_est"]))
                * area * factor_clima * factor_edad
            )
            # Clipping con rangos correctos por hectárea
            kg_min = rend_cfg["minimo"] * area * factor_clima * 0.7
            kg_max = rend_cfg["maximo"] * area * factor_clima
            kg_anuales_objetivo = max(kg_min, min(kg_max, kg_anuales_objetivo))

            # Repartir en eventos de cosecha (5-22 eventos por campaña según área)
            n_eventos = max(5, int(area * float(rng.uniform(1.5, 2.8))))
            n_eventos = min(n_eventos, 25)

            fechas_cosecha = get_dias_cosecha_campania(
                anio, n_eventos, distribucion_mensual, rng
            )

            # Distribuir kg entre eventos con variabilidad
            pesos_evento = rng.dirichlet(np.ones(len(fechas_cosecha)) * 2.0)
            kgs_evento = pesos_evento * kg_anuales_objetivo

            for fecha, kg_cosechado in zip(fechas_cosecha, kgs_evento):
                kg_cosechado = max(50, float(kg_cosechado))

                # Tasa rechazo campo (clipping)
                tasa_rechazo = float(np.clip(
                    rng.normal(rechazo_cfg["media"], rechazo_cfg["desv_est"]),
                    0.005, rechazo_cfg["maximo"]
                ))
                kg_rechazado = round(kg_cosechado * tasa_rechazo, 2)

                # Productividad cuadrilla
                prod_kg_hh = max(40.0, float(rng.normal(prod_cfg["media"], prod_cfg["desv_est"])))
                horas_hombre = round(kg_cosechado / prod_kg_hh, 2)

                # Costo cosecha
                costo_unit = max(0.45, float(rng.normal(costo_cfg["media"], costo_cfg["desv_est"])))
                costo_total = round(kg_cosechado * costo_unit, 2)

                productor_id = fundo_to_productor.get(parcela["FundoID"])
                cuadrilla_id = str(rng.choice(cuadrillas_ids))

                rows.append({
                    "CosechaID": cosecha_id,
                    "FechaID": int(fecha.strftime("%Y%m%d")),
                    "FechaCosecha": fecha,
                    "FundoID": parcela["FundoID"],
                    "ParcelaID": parcela["ParcelaID"],
                    "CuadrillaID": cuadrilla_id,
                    "ProductorID": productor_id,
                    "LoteCampoID": f"LC-{anio}-{lote_campo_id:06d}",
                    "Campania": anio,
                    "KgCosechados": round(kg_cosechado, 2),
                    "KgRechazadosCampo": kg_rechazado,
                    "HorasHombre": horas_hombre,
                    "CostoCosechaSoles": costo_total,
                })
                cosecha_id += 1
                lote_campo_id += 1

    df = pd.DataFrame(rows)
    return df

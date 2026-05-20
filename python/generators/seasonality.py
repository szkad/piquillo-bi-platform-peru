"""
Estacionalidad - Curvas realistas de cosecha del piquillo en Piura.
Distribuye eventos a lo largo del año respetando la fenología del cultivo.
"""
from __future__ import annotations

import calendar
from datetime import date, timedelta
from typing import Dict, List

import numpy as np


def get_dias_cosecha_campania(
    anio: int,
    eventos_objetivo: int,
    distribucion_mensual: Dict[int, float],
    rng: np.random.Generator,
) -> List[date]:
    """
    Genera lista de fechas de cosecha distribuidas según estacionalidad.

    Args:
        anio: Año de la campaña.
        eventos_objetivo: Cantidad total de eventos de cosecha a generar.
        distribucion_mensual: Dict {mes: porcentaje} sumando ~1.0.
        rng: Generador aleatorio numpy.

    Returns:
        Lista de fechas (date) de cosecha.
    """
    fechas: List[date] = []

    # Normalizar distribución
    total_pct = sum(distribucion_mensual.values())
    dist_normalizada = {m: p / total_pct for m, p in distribucion_mensual.items()}

    for mes, pct in dist_normalizada.items():
        eventos_mes = int(round(eventos_objetivo * pct))
        if eventos_mes == 0:
            continue

        dias_en_mes = calendar.monthrange(anio, mes)[1]

        # Excluir domingos para realismo (cosecha lun-sab)
        dias_validos = [
            d for d in range(1, dias_en_mes + 1)
            if date(anio, mes, d).weekday() != 6
        ]

        # Sample con reemplazo (varios eventos por día son normales)
        dias_elegidos = rng.choice(dias_validos, size=eventos_mes, replace=True)

        for d in dias_elegidos:
            fechas.append(date(anio, mes, int(d)))

    return sorted(fechas)


def factor_estacional_precio(mes: int) -> float:
    """
    Factor multiplicativo del precio FOB según mes.
    Precios suelen ser mayores en contraestación (Q1 europeo).
    """
    factores = {
        1: 1.08, 2: 1.10, 3: 1.12, 4: 1.10,
        5: 1.05, 6: 1.00, 7: 0.96, 8: 0.93,
        9: 0.94, 10: 0.97, 11: 1.02, 12: 1.05,
    }
    return factores.get(mes, 1.0)


def factor_climatico_anio(anio: int) -> float:
    """
    Factor de rendimiento agrícola por año.
    2023 tuvo Niño Costero en Piura -> menor rendimiento.
    """
    factores = {
        2022: 1.00,
        2023: 0.78,  # Niño Costero - impacto fuerte en Piura
        2024: 0.92,  # Recuperación parcial
        2025: 1.05,  # Año bueno
    }
    return factores.get(anio, 1.0)


def lag_proceso_dias(rng: np.random.Generator) -> int:
    """Días entre cosecha e ingreso a planta. Usualmente 1-3 días."""
    return int(rng.choice([1, 2, 3], p=[0.5, 0.35, 0.15]))


def lag_despacho_dias(rng: np.random.Generator) -> int:
    """Días entre salida de planta y despacho a puerto. 5-25 días."""
    return int(rng.integers(low=5, high=26))

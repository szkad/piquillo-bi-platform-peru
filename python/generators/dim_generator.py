"""
Generador de dimensiones para el DW Piquillo BI.

Genera 13 dimensiones, dos de ellas SCD Tipo 2:
- DimProductor (cambian categorías y certificaciones entre campañas)
- DimPrecioRefSUNAT (cambia mensualmente)

El resto son SCD Tipo 1 (snapshot actual).
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import Dict, List, Tuple

import numpy as np
import pandas as pd
from faker import Faker

# ==============================================================================
# DimFecha
# ==============================================================================
def generar_dim_fecha(fecha_inicio: date, fecha_fin: date) -> pd.DataFrame:
    """Genera DimFecha desde fecha_inicio hasta fecha_fin (inclusive)."""
    fechas = pd.date_range(fecha_inicio, fecha_fin, freq="D")

    df = pd.DataFrame({"Fecha": fechas})
    df["FechaID"] = df["Fecha"].dt.strftime("%Y%m%d").astype(int)
    df["Anio"] = df["Fecha"].dt.year
    df["Trimestre"] = df["Fecha"].dt.quarter
    df["Mes"] = df["Fecha"].dt.month
    df["NombreMes"] = df["Fecha"].dt.month_name(locale=None)
    df["Semana"] = df["Fecha"].dt.isocalendar().week.astype(int)
    df["DiaMes"] = df["Fecha"].dt.day
    df["DiaSemana"] = df["Fecha"].dt.dayofweek + 1  # 1=Lunes
    df["NombreDiaSemana"] = df["Fecha"].dt.day_name(locale=None)
    df["EsFinDeSemana"] = df["DiaSemana"].isin([6, 7]).astype(int)

    # Campaña (Mar-Feb del año siguiente para piquillo, simplificado a año calendario)
    df["Campania"] = df["Anio"]

    # Feriados Perú (simplificado - principales)
    feriados_peru = _feriados_peru(fecha_inicio.year, fecha_fin.year)
    df["EsFeriado"] = df["Fecha"].dt.date.isin(feriados_peru).astype(int)

    # Mes nombre en español
    meses_es = {
        1: "Enero", 2: "Febrero", 3: "Marzo", 4: "Abril",
        5: "Mayo", 6: "Junio", 7: "Julio", 8: "Agosto",
        9: "Setiembre", 10: "Octubre", 11: "Noviembre", 12: "Diciembre",
    }
    df["NombreMes"] = df["Mes"].map(meses_es)

    dias_es = {
        0: "Lunes", 1: "Martes", 2: "Miércoles", 3: "Jueves",
        4: "Viernes", 5: "Sábado", 6: "Domingo",
    }
    df["NombreDiaSemana"] = df["Fecha"].dt.dayofweek.map(dias_es)

    # Orden de columnas
    cols = [
        "FechaID", "Fecha", "Anio", "Trimestre", "Mes", "NombreMes",
        "Semana", "DiaMes", "DiaSemana", "NombreDiaSemana",
        "EsFinDeSemana", "EsFeriado", "Campania",
    ]
    return df[cols]


def _feriados_peru(anio_ini: int, anio_fin: int) -> set:
    """Feriados peruanos principales (fechas fijas)."""
    feriados = set()
    for anio in range(anio_ini, anio_fin + 1):
        feriados.update([
            date(anio, 1, 1),    # Año Nuevo
            date(anio, 5, 1),    # Día del Trabajo
            date(anio, 6, 7),    # Bandera
            date(anio, 6, 29),   # San Pedro y San Pablo
            date(anio, 7, 28),   # Independencia
            date(anio, 7, 29),   # Independencia
            date(anio, 8, 30),   # Santa Rosa
            date(anio, 10, 8),   # Combate Angamos
            date(anio, 11, 1),   # Todos los Santos
            date(anio, 12, 8),   # Inmaculada
            date(anio, 12, 25),  # Navidad
        ])
    return feriados


# ==============================================================================
# DimProductor (SCD Tipo 2)
# ==============================================================================
def generar_dim_productor_scd2(
    config: dict, rng: np.random.Generator, fake: Faker
) -> pd.DataFrame:
    """
    Genera productores con historia SCD2.
    Cada productor tiene 1-3 versiones a lo largo de las campañas
    (cambios de categoría o certificaciones).
    """
    cantidad = config["dimensiones"]["productores"]["cantidad"]
    distribucion = config["dimensiones"]["productores"]["distribucion_categoria"]
    certificaciones_pool = config["dimensiones"]["certificaciones"]
    campanias = config["campanias"]

    distritos_piura = [
        "Chulucanas", "Tambogrande", "Salitral", "Las Lomas",
        "Sullana", "Bellavista", "Marcavelica", "Querecotillo",
        "Castilla", "Catacaos", "La Arena", "La Unión",
    ]

    # Distribución de categorías
    categorias = (
        ["Pequeño"] * int(cantidad * distribucion["Pequeño"])
        + ["Mediano"] * int(cantidad * distribucion["Mediano"])
        + ["Grande"] * int(cantidad * distribucion["Grande"])
    )
    while len(categorias) < cantidad:
        categorias.append("Pequeño")
    rng.shuffle(categorias)

    rows = []
    productor_sk = 1  # surrogate key incremental

    for i in range(cantidad):
        productor_id = f"PROD{i+1:03d}"
        nombre = _generar_nombre_productor(fake, rng, categorias[i])
        ruc = f"20{rng.integers(100000000, 999999999)}"
        distrito = rng.choice(distritos_piura)
        categoria_inicial = categorias[i]

        # Decidir cuántas versiones tendrá este productor (1, 2 o 3)
        prob_cambios = {"Pequeño": [0.7, 0.25, 0.05],
                        "Mediano": [0.5, 0.4, 0.1],
                        "Grande": [0.3, 0.5, 0.2]}
        n_versiones = int(rng.choice([1, 2, 3], p=prob_cambios[categoria_inicial]))

        # Versiones espaciadas en campañas
        if n_versiones == 1:
            cortes = []
        elif n_versiones == 2:
            cortes = [rng.choice(campanias[1:])]
        else:
            cortes = sorted(rng.choice(campanias[1:], size=2, replace=False))

        # Estado inicial
        certs_actuales = _certs_iniciales(rng, certificaciones_pool, categoria_inicial)
        cat_actual = categoria_inicial

        fecha_inicio = date(campanias[0] - 1, 1, 1)

        for v in range(n_versiones):
            if v < len(cortes):
                fecha_fin = date(cortes[v], 12, 31)
                es_actual = 0
            else:
                fecha_fin = date(2099, 12, 31)
                es_actual = 1

            rows.append({
                "ProductorSK": productor_sk,
                "ProductorID": productor_id,
                "NombreProductor": nombre,
                "RUC": ruc,
                "Distrito": distrito,
                "Categoria": cat_actual,
                "Certificaciones": "|".join(sorted(certs_actuales)) if certs_actuales else "Ninguna",
                "TieneGlobalGAP": int("GlobalGAP" in certs_actuales),
                "TieneSMETA": int("SMETA" in certs_actuales),
                "TieneBRC": int("BRC" in certs_actuales),
                "TieneOrganico": int("Orgánico" in certs_actuales),
                "FechaInicio": fecha_inicio,
                "FechaFin": fecha_fin,
                "EsActual": es_actual,
            })
            productor_sk += 1

            # Evolucionar para siguiente versión
            fecha_inicio = date(cortes[v] + 1, 1, 1) if v < len(cortes) else fecha_inicio
            cat_actual = _evolucionar_categoria(cat_actual, rng)
            certs_actuales = _evolucionar_certs(certs_actuales, certificaciones_pool, rng)

    return pd.DataFrame(rows)


def _generar_nombre_productor(fake: Faker, rng: np.random.Generator, categoria: str) -> str:
    if categoria == "Grande":
        sufijos = ["S.A.C.", "S.A.", "Agroindustrial S.A.C."]
        prefijos = ["Agroexportadora", "Agrícola", "Sociedad Agrícola", "Agroindustria"]
        nombre = f"{rng.choice(prefijos)} {fake.last_name()} {rng.choice(sufijos)}"
    elif categoria == "Mediano":
        nombre = f"Agropecuaria {fake.last_name()} E.I.R.L."
    else:
        nombre = f"{fake.first_name()} {fake.last_name()}"
    return nombre


def _certs_iniciales(rng, pool, categoria) -> List[str]:
    if categoria == "Grande":
        n = int(rng.integers(2, 4))
    elif categoria == "Mediano":
        n = int(rng.integers(0, 3))
    else:
        n = int(rng.integers(0, 2))
    if n == 0:
        return []
    return list(rng.choice(pool, size=min(n, len(pool)), replace=False))


def _evolucionar_categoria(actual: str, rng) -> str:
    # Pequeños suben a Medianos a veces, Medianos a Grandes raramente
    if actual == "Pequeño" and rng.random() < 0.35:
        return "Mediano"
    if actual == "Mediano" and rng.random() < 0.20:
        return "Grande"
    return actual


def _evolucionar_certs(actuales: List[str], pool: List[str], rng) -> List[str]:
    nuevas = list(actuales)
    candidatas = [c for c in pool if c not in nuevas]
    if candidatas and rng.random() < 0.6:
        nuevas.append(str(rng.choice(candidatas)))
    return nuevas


# ==============================================================================
# DimFundo, DimParcela, DimCuadrilla
# ==============================================================================
def generar_dim_fundo(
    df_productor: pd.DataFrame, config: dict, rng: np.random.Generator, fake: Faker
) -> pd.DataFrame:
    """Un productor tiene 1-4 fundos según categoría."""
    rows = []
    fundo_id = 1
    rangos = config["dimensiones"]["fundos_por_productor"]

    productores_unicos = df_productor[df_productor["EsActual"] == 1][
        ["ProductorID", "Categoria", "Distrito"]
    ].drop_duplicates()

    for _, row in productores_unicos.iterrows():
        rango = rangos[row["Categoria"]]
        n_fundos = int(rng.integers(rango[0], rango[1] + 1))
        for f in range(n_fundos):
            ha_total = float(rng.uniform(8, 80) if row["Categoria"] != "Pequeño" else rng.uniform(3, 15))
            rows.append({
                "FundoID": f"FND{fundo_id:04d}",
                "NombreFundo": f"Fundo {fake.last_name()} {f+1}",
                "ProductorID": row["ProductorID"],
                "Distrito": row["Distrito"],
                "Provincia": "Piura" if row["Distrito"] != "Sullana" else "Sullana",
                "HectareasTotales": round(ha_total, 2),
            })
            fundo_id += 1
    return pd.DataFrame(rows)


def generar_dim_parcela(
    df_fundo: pd.DataFrame, df_productor: pd.DataFrame,
    config: dict, rng: np.random.Generator,
) -> pd.DataFrame:
    """Cada fundo tiene 1-8 parcelas."""
    rows = []
    parcela_id = 1
    rangos = config["dimensiones"]["parcelas_por_fundo"]
    ha_min = config["dimensiones"]["hectareas_por_parcela"]["min"]
    ha_max = config["dimensiones"]["hectareas_por_parcela"]["max"]

    productor_categoria = df_productor[df_productor["EsActual"] == 1].set_index(
        "ProductorID"
    )["Categoria"].to_dict()

    for _, fundo in df_fundo.iterrows():
        cat = productor_categoria.get(fundo["ProductorID"], "Pequeño")
        rango = rangos[cat]
        n_parcelas = int(rng.integers(rango[0], rango[1] + 1))
        for p in range(n_parcelas):
            area = round(float(rng.uniform(ha_min, ha_max)), 2)
            anio_plant = int(rng.integers(2015, 2024))
            rows.append({
                "ParcelaID": f"PAR{parcela_id:05d}",
                "CodParcela": f"{fundo['FundoID']}-P{p+1:02d}",
                "FundoID": fundo["FundoID"],
                "Variedad": rng.choice(["Piquillo Coronado", "Piquillo Lodosa Adaptado"], p=[0.7, 0.3]),
                "AreaHa": area,
                "AnioPlantacion": anio_plant,
            })
            parcela_id += 1
    return pd.DataFrame(rows)


def generar_dim_cuadrilla(config: dict, rng: np.random.Generator, fake: Faker) -> pd.DataFrame:
    """Cuadrillas de cosecha."""
    cantidad = config["dimensiones"]["cuadrillas"]["cantidad"]
    rows = []
    for i in range(cantidad):
        rows.append({
            "CuadrillaID": f"CUAD{i+1:03d}",
            "CodCuadrilla": f"C-{i+1:02d}",
            "NombreSupervisor": fake.name(),
            "NumPersonas": int(rng.integers(8, 22)),
        })
    return pd.DataFrame(rows)


# ==============================================================================
# DimPlanta, DimLineaProceso, DimFormato
# ==============================================================================
def generar_dim_planta(config: dict) -> pd.DataFrame:
    rows = []
    for i, p in enumerate(config["dimensiones"]["plantas"], start=1):
        rows.append({
            "PlantaID": f"PLT{i:02d}",
            "NombrePlanta": p["nombre"],
            "Ubicacion": p["ubicacion"],
            "CapacidadDiariaKg": p["capacidad_diaria_kg"],
        })
    return pd.DataFrame(rows)


def generar_dim_linea_proceso(
    df_planta: pd.DataFrame, config: dict
) -> pd.DataFrame:
    """Cada planta tiene N líneas de proceso. Cada línea está dedicada a un tipo."""
    rows = []
    linea_id = 1
    n_lineas = config["dimensiones"]["lineas_proceso_por_planta"]
    tipos_disponibles = ["Entero", "Entero", "Tiras", "Crema"]  # 2 líneas entero, 1 tiras, 1 crema

    for _, planta in df_planta.iterrows():
        for ln in range(n_lineas):
            tipo = tipos_disponibles[ln % len(tipos_disponibles)]
            cap = config["industria"]["productividad_kg_hora"][tipo]
            rows.append({
                "LineaProcesoID": f"LIN{linea_id:03d}",
                "CodLinea": f"{planta['PlantaID']}-L{ln+1}",
                "PlantaID": planta["PlantaID"],
                "TipoFormatoDedicado": tipo,
                "CapacidadKgHora": cap,
            })
            linea_id += 1
    return pd.DataFrame(rows)


def generar_dim_formato(config: dict) -> pd.DataFrame:
    rows = []
    for i, f in enumerate(config["dimensiones"]["formatos"], start=1):
        rows.append({
            "FormatoID": f"FMT{i:02d}",
            "CodFormato": f["cod"],
            "Tipo": f["tipo"],
            "Envase": f["envase"],
            "PesoNetoGr": f["peso_neto_gr"],
            "UnidadesPorCaja": f["unidades_caja"],
        })
    return pd.DataFrame(rows)


# ==============================================================================
# DimCliente, DimDestino, DimNaviera, DimIncoterm
# ==============================================================================
def generar_dim_cliente(
    config: dict, rng: np.random.Generator, fake: Faker
) -> pd.DataFrame:
    cantidad = config["dimensiones"]["clientes"]["cantidad"]
    distribucion = config["dimensiones"]["clientes"]["distribucion_pais"]
    paises = list(distribucion.keys())
    pesos = list(distribucion.values())

    tipos_cliente = ["Distribuidor", "Retailer", "Foodservice"]
    pesos_tipo = [0.45, 0.35, 0.20]

    rows = []
    for i in range(cantidad):
        pais = rng.choice(paises, p=pesos)
        tipo = rng.choice(tipos_cliente, p=pesos_tipo)
        razon = _nombre_cliente(fake, pais, tipo, rng)
        rows.append({
            "ClienteID": f"CLI{i+1:04d}",
            "RazonSocial": razon,
            "Pais": pais,
            "TipoCliente": tipo,
            "AnioPrimerNegocio": int(rng.integers(2018, 2023)),
        })
    return pd.DataFrame(rows)


def _nombre_cliente(fake, pais, tipo, rng):
    sufijos_pais = {
        "España": ["S.L.", "S.A."],
        "Estados Unidos": ["Inc.", "LLC"],
        "Países Bajos": ["B.V."],
        "Italia": ["S.r.l.", "S.p.A."],
        "Alemania": ["GmbH"],
        "Reino Unido": ["Ltd."],
        "Francia": ["S.A.S.", "S.A."],
        "Australia": ["Pty Ltd"],
        "Canadá": ["Inc.", "Corp."],
    }
    sufijo = rng.choice(sufijos_pais.get(pais, ["Inc."]))
    if tipo == "Retailer":
        prefijos = ["Foods", "Gourmet", "Premium", "Market"]
    elif tipo == "Foodservice":
        prefijos = ["Catering", "Servicios", "HoReCa"]
    else:
        prefijos = ["Distribuidora", "Importadora", "Trading"]
    return f"{rng.choice(prefijos)} {fake.last_name()} {sufijo}"


def generar_dim_destino(config: dict) -> pd.DataFrame:
    """Países destino con su puerto de descarga típico."""
    puertos = {
        "España": ("Algeciras", "Europa"),
        "Estados Unidos": ("Long Beach", "Norteamérica"),
        "Países Bajos": ("Róterdam", "Europa"),
        "Italia": ("Génova", "Europa"),
        "Alemania": ("Hamburgo", "Europa"),
        "Reino Unido": ("Felixstowe", "Europa"),
        "Francia": ("Le Havre", "Europa"),
        "Australia": ("Sídney", "Oceanía"),
        "Canadá": ("Montreal", "Norteamérica"),
    }
    rows = []
    for i, (pais, (puerto, region)) in enumerate(puertos.items(), start=1):
        rows.append({
            "DestinoID": f"DST{i:02d}",
            "Pais": pais,
            "Puerto": puerto,
            "Region": region,
        })
    return pd.DataFrame(rows)


def generar_dim_naviera(config: dict) -> pd.DataFrame:
    rows = []
    for i, n in enumerate(config["dimensiones"]["navieras"], start=1):
        rows.append({
            "NavieraID": f"NAV{i:02d}",
            "NombreNaviera": n["nombre"],
            "RutaTipica": n["ruta"],
        })
    return pd.DataFrame(rows)


def generar_dim_incoterm(config: dict) -> pd.DataFrame:
    rows = []
    for i, ic in enumerate(config["dimensiones"]["incoterms"], start=1):
        rows.append({
            "IncotermID": f"INC{i:02d}",
            "Codigo": ic["cod"],
            "Descripcion": ic["desc"],
        })
    return pd.DataFrame(rows)


# ==============================================================================
# DimPrecioRefSUNAT (SCD2) - Precio FOB promedio del sector por mes
# ==============================================================================
def generar_dim_precio_ref_sunat_scd2(
    config: dict, rng: np.random.Generator
) -> pd.DataFrame:
    """
    Precio FOB promedio del sector piquillo Perú por mes/año.
    Inspirado en rangos públicos reales de SUNAT (no son los datos reales).
    """
    rows = []
    sk = 1
    base = 3.20  # USD/kg promedio sector

    for anio in config["campanias"]:
        # Tendencia anual
        tendencia = {2022: 1.00, 2023: 1.08, 2024: 1.05, 2025: 1.10}.get(anio, 1.0)

        for mes in range(1, 13):
            # Estacionalidad (precios más altos en contraestación europea)
            est = {1: 1.06, 2: 1.08, 3: 1.10, 4: 1.07, 5: 1.02, 6: 0.98,
                   7: 0.94, 8: 0.92, 9: 0.93, 10: 0.96, 11: 1.00, 12: 1.04}[mes]

            ruido = float(rng.normal(1.0, 0.025))
            fob_sector = round(base * tendencia * est * ruido, 4)
            fob_pais = round(fob_sector * float(rng.normal(1.005, 0.01)), 4)

            fecha_inicio = date(anio, mes, 1)
            # último día del mes
            if mes == 12:
                fecha_fin = date(anio, 12, 31)
            else:
                fecha_fin = date(anio, mes + 1, 1) - timedelta(days=1)

            rows.append({
                "PrecioRefSK": sk,
                "Anio": anio,
                "Mes": mes,
                "FOBPromedioSector_USDxKg": fob_sector,
                "FOBPromedioPais_USDxKg": fob_pais,
                "FechaInicio": fecha_inicio,
                "FechaFin": fecha_fin,
                "EsActual": 1 if (anio == max(config["campanias"]) and mes == 12) else 0,
            })
            sk += 1

    return pd.DataFrame(rows)

"""
Generador de FactDespacho.

Cada fila = un despacho/contenedor exportado.
Volumetría objetivo: ~2,800 filas.
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import List

import numpy as np
import pandas as pd

from generators.seasonality import (
    factor_estacional_precio,
    lag_despacho_dias,
)


def generar_fact_despacho(
    df_proceso: pd.DataFrame,
    df_productor: pd.DataFrame,
    df_cosecha: pd.DataFrame,
    df_cliente: pd.DataFrame,
    df_destino: pd.DataFrame,
    df_naviera: pd.DataFrame,
    df_incoterm: pd.DataFrame,
    df_formato: pd.DataFrame,
    df_precio_ref: pd.DataFrame,
    config: dict,
    rng: np.random.Generator,
) -> pd.DataFrame:
    """
    Agrupa lotes de proceso en despachos (contenedores).
    Un contenedor lleva 18-22 pallets, con kg_por_pallet entre 850-1100.
    """
    cfg_com = config["comercial"]
    fob_cfg = cfg_com["fob_usd_kg"]
    premium_cert = cfg_com["premium_certificacion"]
    premium_cliente = cfg_com["premium_tipo_cliente"]
    costo_log_cfg = cfg_com["costo_logistico_usd_kg"]
    transito_cfg = cfg_com["dias_transito_por_destino"]
    difot_target = cfg_com["difot_target"]

    pallets_min = cfg_com["pallets_por_contenedor"]["min"]
    pallets_max = cfg_com["pallets_por_contenedor"]["max"]
    kg_pallet_min = cfg_com["kg_por_pallet"]["min"]
    kg_pallet_max = cfg_com["kg_por_pallet"]["max"]

    # Mapeos
    formato_envase = df_formato.set_index("FormatoID")["Envase"].to_dict()
    cliente_pais = df_cliente.set_index("ClienteID")["Pais"].to_dict()
    cliente_tipo = df_cliente.set_index("ClienteID")["TipoCliente"].to_dict()
    pais_a_destino = df_destino.set_index("Pais")["DestinoID"].to_dict()

    # Productor a certificaciones (versión actual al momento - simplificado)
    cosecha_to_productor = df_cosecha.set_index("LoteCampoID")["ProductorID"].to_dict()
    productor_certs_actuales = (
        df_productor[df_productor["EsActual"] == 1]
        .set_index("ProductorID")["Certificaciones"].to_dict()
    )

    # Precio referencia por (año, mes)
    df_precio_ref_idx = df_precio_ref.set_index(["Anio", "Mes"])

    # Clientes mapeados a su país (para asignar destinos coherentes)
    clientes_ids = df_cliente["ClienteID"].tolist()
    naviera_ids = df_naviera["NavieraID"].tolist()
    incoterm_ids = df_incoterm["IncotermID"].tolist()

    # Ordenar lotes de proceso por fecha de salida
    df_proc = df_proceso.sort_values("FechaSalida").reset_index(drop=True)

    # Agrupar lotes en "pools" semanales por formato
    fecha_salida_dt = pd.to_datetime(df_proc["FechaSalida"])
    iso = fecha_salida_dt.dt.isocalendar()
    df_proc["AnioSemana"] = (
        iso["year"].astype(str)
        + "-W" +
        iso["week"].astype(str).str.zfill(2)
    )

    rows: List[dict] = []
    despacho_id = 1

    for (anio_sem, formato_id), grupo in df_proc.groupby(["AnioSemana", "FormatoID"]):
        kg_disponibles = grupo["KgProductoTerminado"].sum()

        # Crear contenedores hasta agotar el inventario (con un poco que queda como stock)
        kg_a_despachar = kg_disponibles * float(rng.uniform(0.85, 0.97))

        while kg_a_despachar > kg_pallet_min * pallets_min:
            n_pallets = int(rng.integers(pallets_min, pallets_max + 1))
            kg_pallet = float(rng.uniform(kg_pallet_min, kg_pallet_max))
            kg_contenedor = round(n_pallets * kg_pallet, 2)

            if kg_contenedor > kg_a_despachar:
                kg_contenedor = round(kg_a_despachar, 2)
                if kg_contenedor < kg_pallet_min * pallets_min:
                    break

            kg_a_despachar -= kg_contenedor

            # Cliente y destino coherente
            cliente_id = str(rng.choice(clientes_ids))
            pais = cliente_pais[cliente_id]
            destino_id = pais_a_destino.get(pais, "DST01")
            tipo_cliente = cliente_tipo[cliente_id]

            # Lote de proceso principal (para trazabilidad)
            lote_proceso_principal = str(grupo.iloc[0]["LoteProcesoID"])
            lote_campo_origen = grupo.iloc[0]["LoteCampoOrigenID"]
            productor_id = cosecha_to_productor.get(lote_campo_origen)
            certs_str = productor_certs_actuales.get(productor_id, "Ninguna")
            certs_list = certs_str.split("|") if certs_str != "Ninguna" else []

            # FOB base por envase
            envase = formato_envase[formato_id]
            fob_base_cfg = fob_cfg.get(envase, fob_cfg["Lata"])
            fob_unit = float(rng.normal(fob_base_cfg["media"], fob_base_cfg["desv_est"]))

            # Aplicar premiums
            for cert in certs_list:
                fob_unit *= (1 + premium_cert.get(cert, 0))
            fob_unit *= (1 + premium_cliente.get(tipo_cliente, 0))

            # Estacionalidad
            fecha_despacho_estimada = grupo.iloc[0]["FechaSalida"] + timedelta(
                days=lag_despacho_dias(rng)
            )
            fob_unit *= factor_estacional_precio(fecha_despacho_estimada.month)

            fob_unit = max(2.0, round(fob_unit, 4))
            valor_fob = round(kg_contenedor * fob_unit, 2)

            # Costo logístico
            costo_log_unit = max(0.20, float(rng.normal(
                costo_log_cfg["media"], costo_log_cfg["desv_est"]
            )))
            costo_log = round(kg_contenedor * costo_log_unit, 2)

            # Tránsito - se calcula dentro de lógica DIFOT
            t_cfg = transito_cfg.get(pais, {"comprometido": 25, "desv_est": 4})
            dias_comp = t_cfg["comprometido"]

            # Estado despacho (DIFOT) - target ~85% OnTime
            margen_difot = 2  # tolerancia ±2 días
            # Decidir primero si será OnTime según probabilidad target
            sera_ontime = rng.random() < difot_target
            if sera_ontime:
                # Forzar tránsito dentro del rango aceptable
                dias_real = max(8, int(rng.normal(dias_comp, max(1, t_cfg["desv_est"] - 1))))
                if dias_real <= dias_comp - 3:
                    estado = "Early"
                else:
                    estado = "OnTime"
            else:
                # Forzar Late con tránsito largo
                dias_real = dias_comp + int(rng.integers(margen_difot + 2, t_cfg["desv_est"] * 2 + 5))
                estado = "Late"

            naviera_id = str(rng.choice(naviera_ids))
            incoterm_id = str(rng.choice(incoterm_ids))

            num_contenedor = f"{rng.choice(['MSKU', 'HLBU', 'MEDU', 'CMAU'])}{rng.integers(1000000, 9999999)}"

            rows.append({
                "DespachoID": despacho_id,
                "FechaDespachoID": int(fecha_despacho_estimada.strftime("%Y%m%d")),
                "FechaDespacho": fecha_despacho_estimada,
                "ClienteID": cliente_id,
                "DestinoID": destino_id,
                "FormatoID": formato_id,
                "NavieraID": naviera_id,
                "IncotermID": incoterm_id,
                "LoteProcesoID": lote_proceso_principal,
                "Campania": fecha_despacho_estimada.year,
                "ContenedorNum": num_contenedor,
                "NumPallets": n_pallets,
                "KgNetosExportados": kg_contenedor,
                "ValorFOB_USD": valor_fob,
                "CostoLogisticoUSD": costo_log,
                "DiasTransitoComprometidos": dias_comp,
                "DiasTransitoReales": dias_real,
                "EstadoDespacho": estado,
            })
            despacho_id += 1

    return pd.DataFrame(rows)

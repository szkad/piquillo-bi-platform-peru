// =============================================================================
// Piquillo BI - Script de creación de medidas DAX
// Tabular Editor 2 - Pegar en Advanced Scripting y ejecutar (F5)
// =============================================================================
// Tabla anfitriona: FactDespacho (donde aparecen todas las medidas)
// Si tu tabla se llama distinto, cambia el var aquí abajo.

var tablaMedidas = Model.Tables["FactDespacho"];
var tablaCosecha = Model.Tables["FactCosecha"];
var tablaProceso = Model.Tables["FactProceso"];

// Helper para crear o reemplazar una medida
Action<Table, string, string, string> M = (tabla, nombre, expr, carpeta) => {
    var existing = tabla.Measures.FirstOrDefault(m => m.Name == nombre);
    if (existing != null) existing.Delete();
    var med = tabla.AddMeasure(nombre, expr, carpeta);
    med.DisplayFolder = carpeta;
};

// =============================================================================
// BLOQUE 1 - AGRÍCOLAS (en FactCosecha)
// =============================================================================
M(tablaCosecha, "Total Kg Cosechados",
    "SUM ( FactCosecha[KgCosechados] )",
    "01 Agricolas");

M(tablaCosecha, "Total Kg Rechazados Campo",
    "SUM ( FactCosecha[KgRechazadosCampo] )",
    "01 Agricolas");

M(tablaCosecha, "Total Kg Limpios",
    "SUM ( FactCosecha[KgLimpios] )",
    "01 Agricolas");

M(tablaCosecha, "Hectareas Productivas",
    @"CALCULATE (
        SUM ( DimParcela[AreaHa] ),
        FILTER (
            DimParcela,
            DimParcela[ParcelaID] IN VALUES ( FactCosecha[ParcelaID] )
        )
    )",
    "01 Agricolas");

M(tablaCosecha, "Rendimiento Kg por Ha",
    @"DIVIDE (
        [Total Kg Cosechados],
        [Hectareas Productivas]
    )",
    "01 Agricolas");

M(tablaCosecha, "Tasa Rechazo Campo %",
    @"DIVIDE (
        [Total Kg Rechazados Campo],
        [Total Kg Cosechados]
    )",
    "01 Agricolas");

M(tablaCosecha, "Productividad Cuadrilla Kg HH",
    @"DIVIDE (
        [Total Kg Cosechados],
        SUM ( FactCosecha[HorasHombre] )
    )",
    "01 Agricolas");

M(tablaCosecha, "Costo Cosecha S/. Kg",
    @"DIVIDE (
        SUM ( FactCosecha[CostoCosechaSoles] ),
        [Total Kg Cosechados]
    )",
    "01 Agricolas");

// =============================================================================
// BLOQUE 2 - INDUSTRIALES (en FactProceso)
// =============================================================================
M(tablaProceso, "Total Kg Ingreso MP",
    "SUM ( FactProceso[KgIngresoMP] )",
    "02 Industriales");

M(tablaProceso, "Total Kg PT",
    "SUM ( FactProceso[KgProductoTerminado] )",
    "02 Industriales");

M(tablaProceso, "Total Kg Merma",
    "SUM ( FactProceso[KgMermaProceso] )",
    "02 Industriales");

M(tablaProceso, "Total Kg Rechazo Calidad",
    "SUM ( FactProceso[KgRechazoCalidad] )",
    "02 Industriales");

M(tablaProceso, "Rendimiento Proceso %",
    @"DIVIDE (
        [Total Kg PT],
        [Total Kg Ingreso MP]
    )",
    "02 Industriales");

M(tablaProceso, "Tasa Merma %",
    @"DIVIDE (
        [Total Kg Merma],
        [Total Kg Ingreso MP]
    )",
    "02 Industriales");

M(tablaProceso, "Tasa Rechazo Calidad %",
    @"DIVIDE (
        [Total Kg Rechazo Calidad],
        [Total Kg Ingreso MP]
    )",
    "02 Industriales");

M(tablaProceso, "Costo Proceso S/. Kg PT",
    @"DIVIDE (
        SUM ( FactProceso[CostoProcesoSoles] ),
        [Total Kg PT]
    )",
    "02 Industriales");

// =============================================================================
// BLOQUE 3 - COMERCIALES (en FactDespacho)
// =============================================================================
M(tablaMedidas, "Kg Exportados",
    "SUM ( FactDespacho[KgNetosExportados] )",
    "03 Comerciales");

M(tablaMedidas, "Valor FOB USD",
    "SUM ( FactDespacho[ValorFOB_USD] )",
    "03 Comerciales");

M(tablaMedidas, "FOB USD por Kg",
    @"DIVIDE (
        [Valor FOB USD],
        [Kg Exportados]
    )",
    "03 Comerciales");

M(tablaMedidas, "Costo Logistico USD",
    "SUM ( FactDespacho[CostoLogisticoUSD] )",
    "03 Comerciales");

M(tablaMedidas, "Costo Logistico USD por Kg",
    @"DIVIDE (
        [Costo Logistico USD],
        [Kg Exportados]
    )",
    "03 Comerciales");

M(tablaMedidas, "Margen Bruto USD",
    "[Valor FOB USD] - [Costo Logistico USD]",
    "03 Comerciales");

M(tablaMedidas, "Margen Bruto %",
    @"DIVIDE (
        [Margen Bruto USD],
        [Valor FOB USD]
    )",
    "03 Comerciales");

M(tablaMedidas, "Despachos",
    "DISTINCTCOUNT ( FactDespacho[DespachoID] )",
    "03 Comerciales");

M(tablaMedidas, "FOB Sector SUNAT USD por Kg",
    @"AVERAGE ( DimPrecioRefSUNAT[FOBPromedioSector_USDxKg] )",
    "03 Comerciales");

M(tablaMedidas, "Brecha FOB vs Sector",
    "[FOB USD por Kg] - [FOB Sector SUNAT USD por Kg]",
    "03 Comerciales");

// =============================================================================
// BLOQUE 4 - OPERACIONALES / LOGÍSTICOS (en FactDespacho)
// =============================================================================
M(tablaMedidas, "Despachos OnTime",
    @"CALCULATE (
        [Despachos],
        FactDespacho[EsOnTime] = TRUE ()
    )",
    "04 Operacionales");

M(tablaMedidas, "DIFOT %",
    @"DIVIDE (
        [Despachos OnTime],
        [Despachos]
    )",
    "04 Operacionales");

M(tablaMedidas, "Dias Transito Promedio",
    "AVERAGE ( FactDespacho[DiasTransitoReales] )",
    "04 Operacionales");

M(tablaMedidas, "Desv Transito Dias",
    "AVERAGE ( FactDespacho[DesvTransitoDias] )",
    "04 Operacionales");

// =============================================================================
// BLOQUE 5 - TIME INTELLIGENCE (variaciones interanuales)
// =============================================================================
M(tablaMedidas, "Valor FOB USD AA",
    @"CALCULATE (
        [Valor FOB USD],
        SAMEPERIODLASTYEAR ( DimFecha[Fecha] )
    )",
    "05 Time Intelligence");

M(tablaMedidas, "Var Valor FOB vs AA %",
    @"DIVIDE (
        [Valor FOB USD] - [Valor FOB USD AA],
        [Valor FOB USD AA]
    )",
    "05 Time Intelligence");

M(tablaMedidas, "Kg Exportados AA",
    @"CALCULATE (
        [Kg Exportados],
        SAMEPERIODLASTYEAR ( DimFecha[Fecha] )
    )",
    "05 Time Intelligence");

M(tablaMedidas, "Var Kg Exportados vs AA %",
    @"DIVIDE (
        [Kg Exportados] - [Kg Exportados AA],
        [Kg Exportados AA]
    )",
    "05 Time Intelligence");

Info("Medidas creadas: 32 (incluye 4 de time intelligence adicionales).");

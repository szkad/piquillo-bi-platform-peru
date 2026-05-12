// =============================================================================
// Piquillo BI - Validación de organización de medidas en carpetas
// =============================================================================
// El script 01 ya asigna DisplayFolder al crear cada medida.
// Este script es para auditar/reorganizar si hace falta.

var folderMap = new Dictionary<string, string> {
    { "Total Kg Cosechados", "01 Agricolas" },
    { "Total Kg Rechazados Campo", "01 Agricolas" },
    { "Total Kg Limpios", "01 Agricolas" },
    { "Hectareas Productivas", "01 Agricolas" },
    { "Rendimiento Kg por Ha", "01 Agricolas" },
    { "Tasa Rechazo Campo %", "01 Agricolas" },
    { "Productividad Cuadrilla Kg HH", "01 Agricolas" },
    { "Costo Cosecha S/. Kg", "01 Agricolas" },

    { "Total Kg Ingreso MP", "02 Industriales" },
    { "Total Kg PT", "02 Industriales" },
    { "Total Kg Merma", "02 Industriales" },
    { "Total Kg Rechazo Calidad", "02 Industriales" },
    { "Rendimiento Proceso %", "02 Industriales" },
    { "Tasa Merma %", "02 Industriales" },
    { "Tasa Rechazo Calidad %", "02 Industriales" },
    { "Costo Proceso S/. Kg PT", "02 Industriales" },

    { "Kg Exportados", "03 Comerciales" },
    { "Valor FOB USD", "03 Comerciales" },
    { "FOB USD por Kg", "03 Comerciales" },
    { "Costo Logistico USD", "03 Comerciales" },
    { "Costo Logistico USD por Kg", "03 Comerciales" },
    { "Margen Bruto USD", "03 Comerciales" },
    { "Margen Bruto %", "03 Comerciales" },
    { "Despachos", "03 Comerciales" },
    { "FOB Sector SUNAT USD por Kg", "03 Comerciales" },
    { "Brecha FOB vs Sector", "03 Comerciales" },

    { "Despachos OnTime", "04 Operacionales" },
    { "DIFOT %", "04 Operacionales" },
    { "Dias Transito Promedio", "04 Operacionales" },
    { "Desv Transito Dias", "04 Operacionales" },

    { "Valor FOB USD AA", "05 Time Intelligence" },
    { "Var Valor FOB vs AA %", "05 Time Intelligence" },
    { "Kg Exportados AA", "05 Time Intelligence" },
    { "Var Kg Exportados vs AA %", "05 Time Intelligence" }
};

int actualizadas = 0;
foreach (var t in Model.Tables) {
    foreach (var m in t.Measures.ToList()) {
        if (folderMap.ContainsKey(m.Name) && m.DisplayFolder != folderMap[m.Name]) {
            m.DisplayFolder = folderMap[m.Name];
            actualizadas++;
        }
    }
}
Info("Carpetas validadas. Medidas actualizadas: " + actualizadas);

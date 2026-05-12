// =============================================================================
// Piquillo BI - Formatos de visualización para las medidas
// =============================================================================

var formatos = new Dictionary<string, string> {
    // Kg con separador de miles, sin decimales
    { "Total Kg Cosechados", "#,0 \"kg\"" },
    { "Total Kg Rechazados Campo", "#,0 \"kg\"" },
    { "Total Kg Limpios", "#,0 \"kg\"" },
    { "Total Kg Ingreso MP", "#,0 \"kg\"" },
    { "Total Kg PT", "#,0 \"kg\"" },
    { "Total Kg Merma", "#,0 \"kg\"" },
    { "Total Kg Rechazo Calidad", "#,0 \"kg\"" },
    { "Kg Exportados", "#,0 \"kg\"" },
    { "Kg Exportados AA", "#,0 \"kg\"" },

    // Hectáreas
    { "Hectareas Productivas", "#,0.0 \"ha\"" },

    // Ratios con 1 decimal
    { "Rendimiento Kg por Ha", "#,0 \"kg/ha\"" },
    { "Productividad Cuadrilla Kg HH", "#,0.0 \"kg/HH\"" },

    // Porcentajes
    { "Tasa Rechazo Campo %", "0.0%" },
    { "Rendimiento Proceso %", "0.0%" },
    { "Tasa Merma %", "0.0%" },
    { "Tasa Rechazo Calidad %", "0.0%" },
    { "DIFOT %", "0.0%" },
    { "Margen Bruto %", "0.0%" },
    { "Var Valor FOB vs AA %", "+0.0%;-0.0%;0.0%" },
    { "Var Kg Exportados vs AA %", "+0.0%;-0.0%;0.0%" },

    // Soles
    { "Costo Cosecha S/. Kg", "\"S/.\" #,0.00" },
    { "Costo Proceso S/. Kg PT", "\"S/.\" #,0.00" },

    // USD
    { "Valor FOB USD", "\"$\" #,0" },
    { "Valor FOB USD AA", "\"$\" #,0" },
    { "Margen Bruto USD", "\"$\" #,0" },
    { "Costo Logistico USD", "\"$\" #,0" },
    { "FOB USD por Kg", "\"$\" #,0.00" },
    { "FOB Sector SUNAT USD por Kg", "\"$\" #,0.00" },
    { "Brecha FOB vs Sector", "+\"$\" #,0.00;-\"$\" #,0.00;\"$\" 0.00" },
    { "Costo Logistico USD por Kg", "\"$\" #,0.00" },

    // Conteos
    { "Despachos", "#,0" },
    { "Despachos OnTime", "#,0" },

    // Días
    { "Dias Transito Promedio", "0.0 \"días\"" },
    { "Desv Transito Dias", "+0.0;-0.0;0.0" }
};

int aplicados = 0;
foreach (var t in Model.Tables) {
    foreach (var m in t.Measures) {
        if (formatos.ContainsKey(m.Name)) {
            m.FormatString = formatos[m.Name];
            aplicados++;
        }
    }
}
Info("Formatos aplicados: " + aplicados);

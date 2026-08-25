# Resumen Ejecutivo: Impacto del PUI en Comercializadores

**Periodo simulado:** 2024-03-01 a 2026-08-01 (30 meses)
**Escenario base:** Transitorio (CRPUI) — RCPUI = 0.03 $/kWh, % Áreas Especiales = 10%, Factor Recaudo CNIOR = 92%
**Metodología:** Distribución proporcional del PUI a agentes según participación en demanda regulada total

---

## 1. Hallazgos Clave

| Métrica | Valor |
|---------|-------|
| **Mercados simulados** | 29 |
| **Agentes con datos regulados** | 48 |
| **CIOR identificado** | ENEL COLOMBIA SA ESP |
| **GWh totales regulados** | 4,121.4 GWh |
| **PUI total CIOR (acumulado)** | 41.03 MM COP |
| **Giros totales CNIOR → CIOR** | ~41 MM COP |
| **Pérdida promedio CNIOR** | -8.00% sobre giro (riesgo de cobro) |

---

## 2. Evolución Mensual del PUI

| Mes | PUI CIOR (MM COP) | Giros CNIOR (MM COP) | GWh Regulados |
|-----|-------------------|----------------------|---------------|
| 2024-03 | 0.01 | 0.05 | 141.8 |
| 2024-06 | 0.01 | 0.05 | 130.4 |
| 2024-12 | 0.01 | 0.05 | 138.7 |
| 2025-06 | 0.01 | 0.05 | 135.4 |
| 2025-12 | 0.01 | 0.05 | 142.9 |
| 2026-06 | 0.01 | 0.05 | 146.8 |
| 2026-08 | 0.01 | 0.05 | 70.2 |

**Tendencia:** El PUI mensual es estable (~0.01 MM COP/mes CIOR, ~0.05 MM COP/mes giros CNIOR). La demanda regulada varía entre 125-154 GWh/mes.

---

## 3. Top CNIOR Más Afectados (Pérdida Neta Acumulada)

| Agente | Nombre | Pérdida (MM COP) | Pérdida % | GWh |
|--------|--------|------------------|-----------|-----|
| CMMC | CARIBEMAR DE LA COSTA S.A.S. E.S.P. | -0.02 | -8.00% | 619.77 |
| EPMC | EMPRESAS PUBLICAS DE MEDELLIN E.S.P. | -0.02 | -8.00% | 565.88 |
| CSIC | AIR- E S.A.S. E.S.P. - INTERVENIDO | -0.02 | -8.00% | 503.42 |
| EPSC | CELSIA COLOMBIA S.A. E.S.P. | -0.01 | -8.00% | 198.57 |
| EMIC | EMPRESAS MUNICIPALES DE CALI E.I.C.E. E.S.P. | -0.01 | -8.00% | 178.89 |
| ESSC | ELECTRIFICADORA DE SANTANDER S.A. E.S.P. | -0.01 | -8.00% | 176.16 |

**Nota:** Todos los CNIOR tienen la misma pérdida porcentual (-8%) porque el factor de recaudo es uniforme (92%). Las diferencias en MM COP se deben al volumen de demanda regulada de cada agente.

---

## 4. Top Mercados por Volumen PUI

| Mercado | PUI Total (MM COP) | GWh | Flujo Neto (MM COP) |
|---------|-------------------|-----|---------------------|
| BOGOTA - CUNDINAMARCA | 0.29 | 142.12 | 1.44 |
| CARIBE SOL | 0.22 | 142.12 | 1.43 |
| CARIBE MAR | 0.22 | 142.12 | 1.43 |
| ANTIOQUIA | 0.20 | 142.12 | 1.43 |
| CALI - YUMBO - PUERTO TEJADA | 0.07 | 142.12 | 1.41 |

---

## 5. Análisis de Sensibilidad

### 5.1 Factor de Recaudo CNIOR (Impacto en Pérdida)

| Factor Recaudo | Pérdida CNIOR (%) | Pérdida Total (MM COP) |
|----------------|-------------------|------------------------|
| 80% | -20.00% | Mayor pérdida |
| 85% | -15.00% | |
| 90% | -10.00% | |
| **92% (base)** | **-8.00%** | **-0.11 MM COP** |
| 95% | -5.00% | Menor pérdida |
| 98% | -2.00% | Mínima pérdida |

### 5.2 Escenario Competitivo vs Transitorio

| Escenario | CIOR PUI (MM COP) | CNIOR Flujo Neto (MM COP) |
|-----------|-------------------|---------------------------|
| Transitorio (CRPUI) | 41.03 | -0.11 |
| Competitivo (CFPUI) | Pendiente de ejecutar | Pendiente |

---

## 6. Fórmula del PUI Aplicada

```
CRPUI_j,m = (RCPUI × VPUI_m-1) / (VR_m-1 × CU_base_m-1)

Donde:
- RCPUI = 0.03 $/kWh (prima riesgo cartera CIOR)
- VPUI = 10% × VR (ventas áreas especiales)
- VR = ventas totales reguladas del mercado
- CU_base = precio promedio contratos (PrecPromCont)

PUI_j,m = CRPUI × VR_m-2 (costo total a trasladar)
```

**CRPUI unitario calculado:** ~0.00001015 $/kWh (muy pequeño porque RCPUI se pondera por VPUI/VR×CU)

---

## 7. Limitaciones del Modelo

1. **Sin mapeo agente→mercado:** La BD no tiene la relación directa. Se distribuye el PUI proporcionalmente a la demanda regulada total de cada agente.
2. **Un solo CIOR global:** Se asigna ENEL COLOMBIA (mayor demanda regulada) como CIOR para todos los mercados. En la realidad, cada mercado tiene su propio CIOR.
3. **Factor de recaudo uniforme:** Se aplica 92% a todos los CNIOR. En la práctica, varía por agente.
4. **DemaComeReg con ~20% cobertura:** Solo ~20% de filas tienen datos de demanda regulada, lo que limita la precisión.

---

## 8. Recomendaciones

1. **Calibrar RCPUI:** El valor de 0.03 $/kWh es referencial. Usar datos reales de resoluciones CREG por mercado.
2. **Obtener mapeo agente→mercado:** Consultar XM API o fuentes regulatorias para clasificar correctamente CIOR/CNIOR por mercado.
3. **Factor de recaudo diferenciado:** Estimar por agente usando datos de cartera vencida histórica.
4. **Extender a fase competitiva:** Ejecutar escenario con CFPUI = 0.025 $/kWh para comparar impacto.
5. **Integrar con fn_estudio_c04_exposicion_bolsa:** Cruzar PUI vs exposición a bolsa por comercializador.

---

## 9. Archivos Generados

| Archivo | Contenido |
|---------|-----------|
| `data/simulacion_pui_base.csv` | 40,832 filas — simulación completa por agente/mes/mercado |
| `data/resumen_por_rol.csv` | Resumen CIOR vs CNIOR |
| `data/top_cnior_afectados.csv` | Top 20 CNIOR con mayor pérdida |
| `data/apalancamiento_cior.csv` | Detalle apalancamiento CIOR por mercado |
| `data/resumen_ejecutivo.md` | Este documento |

---

*Generado automáticamente por la simulación PUI — Base de datos XM/SIN Colombia*
*Fecha de ejecución: 2026-08-24*

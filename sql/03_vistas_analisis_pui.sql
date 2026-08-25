-- Vistas analíticas derivadas de v_simulacion_pui

-- 1. Resumen por Rol (CIOR vs CNIOR)
DROP VIEW IF EXISTS v_resumen_por_rol CASCADE;
CREATE VIEW v_resumen_por_rol AS
SELECT
    rol_pui,
    param_rcpui,
    param_pct_ae,
    param_factor_recaudo,
    param_competitivo,
    param_cfpui,
    COUNT(DISTINCT agente_code) AS n_agentes,
    COUNT(DISTINCT mercado_code) AS n_mercados,
    SUM(ventas_reg_kwh)/1e6 AS gwh_totales,
    SUM(ingresos_pui_facturado)/1e9 AS ingresos_pui_miles_millones_cop,
    SUM(egreso_giro_cior)/1e9 AS egresos_giro_miles_millones_cop,
    SUM(flujo_neto_caja_pui)/1e9 AS flujo_neto_caja_miles_millones_cop,
    AVG(pct_perdida_sobre_giro_cnior) AS pct_prom_perdida_cnior,
    AVG(pct_apalancamiento_cior) AS pct_prom_apalancamiento_cior,
    MIN(mes) AS mes_inicio,
    MAX(mes) AS mes_fin
FROM v_simulacion_pui
GROUP BY rol_pui, param_rcpui, param_pct_ae, param_factor_recaudo, param_competitivo, param_cfpui;

-- 2. Top CNIOR más afectados (pérdida neta)
DROP VIEW IF EXISTS v_top_cnior_afectados CASCADE;
CREATE VIEW v_top_cnior_afectados AS
SELECT
    mercado_name,
    mes,
    agente_name,
    flujo_neto_caja_pui/1e6 AS perdida_millones_cop,
    pct_perdida_sobre_giro_cnior,
    ingresos_pui_facturado/1e6 AS facturado_millones_cop,
    egreso_giro_cior/1e6 AS giro_millones_cop,
    param_factor_recaudo
FROM v_simulacion_pui
WHERE rol_pui = 'CNIOR' AND flujo_neto_caja_pui < 0
ORDER BY flujo_neto_caja_pui ASC
LIMIT 20;

-- 3. CIOR: Apalancamiento por giros CNIOR (usa v_simulacion_pui filtrado CIOR)
DROP VIEW IF EXISTS v_apalancamiento_cior CASCADE;
CREATE VIEW v_apalancamiento_cior AS
SELECT
    s.mercado_name,
    s.mes,
    s.agente_name,
    -- VTPUI = recaudo propio + giros recibidos
    (s.ingresos_pui_facturado + s.egreso_giro_cior)/1e9 AS vtpui_miles_millones_cop,
    s.ingresos_pui_facturado/1e9 AS recaudo_propio_miles_millones_cop,
    s.egreso_giro_cior/1e9 AS giros_recibidos_miles_millones_cop,
    s.pct_apalancamiento_cior,
    s.param_rcpui,
    s.param_competitivo,
    s.param_cfpui
FROM v_simulacion_pui s
WHERE s.rol_pui = 'CIOR'
ORDER BY s.pct_apalancamiento_cior DESC;

-- 4. Sensibilidad Competitivo vs Transitorio (comparación lado a lado)
DROP VIEW IF EXISTS v_sensibilidad_competitivo CASCADE;
CREATE VIEW v_sensibilidad_competitivo AS
WITH base AS (
    SELECT * FROM v_simulacion_pui WHERE param_competitivo = false
),
comp AS (
    SELECT * FROM v_simulacion_pui WHERE param_competitivo = true
)
SELECT
    b.mercado_name,
    b.agente_name,
    b.rol_pui,
    b.mes,
    b.flujo_neto_caja_pui/1e6 AS flujo_base_millones_cop,
    c.flujo_neto_caja_pui/1e6 AS flujo_comp_millones_cop,
    (c.flujo_neto_caja_pui - b.flujo_neto_caja_pui)/1e6 AS delta_millones_cop,
    CASE WHEN b.flujo_neto_caja_pui != 0
         THEN (c.flujo_neto_caja_pui - b.flujo_neto_caja_pui) / ABS(b.flujo_neto_caja_pui) * 100
    END AS pct_cambio
FROM base b
JOIN comp c ON b.mercado_code = c.mercado_code AND b.agente_code = c.agente_code AND b.mes = c.mes
ORDER BY b.rol_pui, delta_millones_cop;

-- 5. Sensibilidad Factor Recaudo CNIOR (barrido)
DROP VIEW IF EXISTS v_sensibilidad_recaudo CASCADE;
CREATE VIEW v_sensibilidad_recaudo AS
SELECT
    param_factor_recaudo,
    rol_pui,
    COUNT(DISTINCT agente_code) AS n_agentes,
    SUM(ventas_reg_kwh)/1e6 AS gwh_totales,
    SUM(flujo_neto_caja_pui)/1e9 AS flujo_neto_miles_millones_cop,
    AVG(pct_perdida_sobre_giro_cnior) AS pct_prom_perdida_cnior,
    MIN(flujo_neto_caja_pui)/1e6 AS min_flujo_millones_cop,
    MAX(flujo_neto_caja_pui)/1e6 AS max_flujo_millones_cop
FROM v_simulacion_pui
WHERE rol_pui = 'CNIOR'
GROUP BY param_factor_recaudo, rol_pui
ORDER BY param_factor_recaudo;

-- 6. Resumen de Independientes (todos los agentes independientes)
DROP VIEW IF EXISTS v_resumen_independientes CASCADE;
CREATE VIEW v_resumen_independientes AS
SELECT
    es_miembro_asociacion,
    tipo_independiente,
    param_rcpui,
    param_factor_recaudo,
    COUNT(DISTINCT agente_code) AS n_agentes,
    COUNT(DISTINCT mercado_code) AS n_mercados,
    SUM(ventas_reg_kwh)/1e6 AS gwh_totales,
    SUM(ingresos_pui_facturado)/1e9 AS ingresos_pui_miles_millones_cop,
    SUM(egreso_giro_cior)/1e9 AS egresos_giro_miles_millones_cop,
    SUM(flujo_neto_caja_pui)/1e9 AS flujo_neto_caja_miles_millones_cop,
    AVG(sobrecosto_pui)/1e6 AS promedio_sobrecosto_millones_cop,
    AVG(pct_perdida_incobrabilidad) AS promedio_perdida_incobrabilidad,
    AVG(riesgo_flujo_caja) AS promedio_riesgo_flujo,
    MIN(mes) AS mes_inicio,
    MAX(mes) AS mes_fin
FROM v_simulacion_pui
WHERE es_independiente = true
GROUP BY es_miembro_asociacion, tipo_independiente, param_rcpui, param_factor_recaudo;

-- 7. Comparación entre Miembros y No Miembros de la Asociación
DROP VIEW IF EXISTS v_comparacion_grupos CASCADE;
CREATE VIEW v_comparacion_grupos AS
SELECT
    CASE WHEN es_miembro_asociacion THEN 'Miembros (pagaron estudio)' ELSE 'No miembros' END AS grupo,
    COUNT(DISTINCT agente_code) AS n_agentes,
    SUM(ventas_reg_kwh)/1e6 AS gwh_totales,
    AVG(sobrecosto_pui)/1e6 AS promedio_sobrecosto_millones,
    AVG(pct_perdida_incobrabilidad) AS promedio_perdida_incobrabilidad,
    AVG(riesgo_flujo_caja) AS promedio_riesgo_flujo,
    SUM(flujo_neto_caja_pui)/1e9 AS flujo_neto_total_miles_millones,
    AVG(flujo_neto_caja_pui)/1e6 AS promedio_flujo_neto_millones,
    MIN(flujo_neto_caja_pui)/1e6 AS peor_flujo_millones,
    MAX(flujo_neto_caja_pui)/1e6 AS mejor_flujo_millones
FROM v_simulacion_pui
WHERE es_independiente = true
GROUP BY es_miembro_asociacion;

-- 8. Top Independientes Más Afectados (por pérdida absoluta)
DROP VIEW IF EXISTS v_top_afectados CASCADE;
CREATE VIEW v_top_afectados AS
SELECT
    mercado_name,
    mes,
    agente_name,
    es_miembro_asociacion,
    tipo_independiente,
    flujo_neto_caja_pui/1e6 AS perdida_millones_cop,
    sobrecosto_pui/1e6 AS sobrecosto_millones_cop,
    pct_perdida_incobrabilidad,
    riesgo_flujo_caja,
    ventas_reg_kwh/1e6 AS ventas_gwh,
    param_factor_recaudo
FROM v_simulacion_pui
WHERE es_independiente = true AND flujo_neto_caja_pui < 0
ORDER BY flujo_neto_caja_pui ASC
LIMIT 30;

-- 9. Independientes con Mayor Riesgo de Flujo de Caja
DROP VIEW IF EXISTS v_riesgo_flujo_caja CASCADE;
CREATE VIEW v_riesgo_flujo_caja AS
SELECT
    mercado_name,
    mes,
    agente_name,
    es_miembro_asociacion,
    riesgo_flujo_caja,
    egreso_giro_cior/1e6 AS giro_obligatorio_millones,
    ventas_reg_kwh/1e6 AS ventas_gwh,
    tipo_independiente
FROM v_simulacion_pui
WHERE es_independiente = true AND riesgo_flujo_caja > 10  -- más del 10% de ventas comprometidas
ORDER BY riesgo_flujo_caja DESC
LIMIT 30;
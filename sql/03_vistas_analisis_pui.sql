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
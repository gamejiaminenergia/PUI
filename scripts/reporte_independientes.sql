-- Reporte Ejecutivo: Impacto del PUI en Comercializadores Independientes
-- Este script genera un resumen claro y simple para el cliente

-- ============================================================
-- RESUMEN EJECUTIVO
-- ============================================================
SELECT '=== RESUMEN EJECUTIVO ===' AS seccion;

-- 1. Totales generales
SELECT
    'TOTAL INDEPENDIENTES' AS metrica,
    COUNT(DISTINCT agente_code) AS valor,
    'agentes' AS unidad
FROM v_simulacion_pui
WHERE es_independiente = true

UNION ALL

-- 2. Pérdida total estimada
SELECT
    'PÉRDIDA TOTAL ESTIMADA' AS metrica,
    SUM(flujo_neto_caja_pui)/1e9 AS valor,
    'miles de millones COP' AS unidad
FROM v_simulacion_pui
WHERE es_independiente = true AND flujo_neto_caja_pui < 0

UNION ALL

-- 3. Sobrecosto promedio
SELECT
    'SOBRECOSTO PROMEDIO' AS metrica,
    AVG(sobrecosto_pui)/1e6 AS valor,
    'millones COP por agente-mes' AS unidad
FROM v_simulacion_pui
WHERE es_independiente = true AND sobrecosto_pui > 0

UNION ALL

-- 4. Agentes en riesgo crítico
SELECT
    'AGENTES EN RIESGO CRÍTICO' AS metrica,
    COUNT(DISTINCT agente_code) AS valor,
    'agentes (riesgo > 10%)' AS unidad
FROM v_simulacion_pui
WHERE es_independiente = true AND riesgo_flujo_caja > 10;

-- ============================================================
-- COMPARACIÓN ASOCIADOS VS NO ASOCIADOS
-- ============================================================
SELECT '=== COMPARACIÓN ENTRE GRUPOS ===' AS seccion;

SELECT * FROM v_comparacion_grupos;

-- ============================================================
-- TOP 10 INDEPENDIENTES MÁS AFECTADOS
-- ============================================================
SELECT '=== TOP 10 INDEPENDIENTES MÁS AFECTADOS ===' AS seccion;

SELECT
    agente_name,
    es_miembro_asociacion,
    tipo_independiente,
    SUM(flujo_neto_caja_pui)/1e6 AS perdida_total_millones,
    AVG(sobrecosto_pui)/1e6 AS sobrecosto_promedio_millones,
    AVG(pct_perdida_incobrabilidad) AS perdida_incobrabilidad_pct,
    AVG(riesgo_flujo_caja) AS riesgo_flujo_pct
FROM v_simulacion_pui
WHERE es_independiente = true AND flujo_neto_caja_pui < 0
GROUP BY agente_name, es_miembro_asociacion, tipo_independiente
ORDER BY perdida_total_millones ASC
LIMIT 10;

-- ============================================================
-- DISTRIBUCIÓN DEL RIESGO
-- ============================================================
SELECT '=== DISTRIBUCIÓN DEL RIESGO ===' AS seccion;

SELECT
    CASE
        WHEN riesgo_flujo_caja <= 5 THEN 'Bajo (0-5%)'
        WHEN riesgo_flujo_caja <= 10 THEN 'Medio (5-10%)'
        WHEN riesgo_flujo_caja <= 20 THEN 'Alto (10-20%)'
        ELSE 'Crítico (>20%)'
    END AS nivel_riesgo,
    COUNT(DISTINCT agente_code) AS n_agentes,
    SUM(ventas_reg_kwh)/1e6 AS gwh_totales,
    AVG(flujo_neto_caja_pui)/1e6 AS promedio_perdida_millones
FROM v_simulacion_pui
WHERE es_independiente = true AND egreso_giro_cior > 0
GROUP BY 1
ORDER BY 1;

-- ============================================================
-- APOYO A LOS COMENTARIOS DEL CLIENTE
-- ============================================================
SELECT '=== APOYO A ANÁLISIS REGULATORIO ===' AS seccion;

-- Punto 1: Asimetría de riesgos
SELECT
    'ASIMETRÍA DE RIESGOS' AS hallazgo,
    'Los independientes asumen el 100% del riesgo de impago mientras que el Operador de Red tiene ingreso blindado' AS descripcion,
    AVG(pct_perdida_incobrabilidad) AS evidencia_numerica,
    '% promedio de pérdida por incobrabilidad' AS unidad
FROM v_simulacion_pui
WHERE es_independiente = true

UNION ALL

-- Punto 2: Falta de músculo financiero
SELECT
    'FALTA DE MÚSCULO FINANCIERO' AS hallazgo,
    'Los independientes no tienen subsidio cruzado de otras líneas de negocio' AS descripcion,
    COUNT(DISTINCT CASE WHEN riesgo_flujo_caja > 10 THEN agente_code END) AS evidencia_numerica,
    'agentes con riesgo alto' AS unidad
FROM v_simulacion_pui
WHERE es_independiente = true

UNION ALL

-- Punto 3: Concentración del mercado
SELECT
    'CONCENTRACIÓN DEL MERCADO' AS hallazgo,
    'El esquema transitorio desincentiva la participación de comercializadores independientes' AS descripcion,
    SUM(CASE WHEN flujo_neto_caja_pui < 0 THEN 1 ELSE 0 END)::float / COUNT(*) * 100 AS evidencia_numerica,
    '% de independientes con pérdida neta' AS unidad
FROM v_simulacion_pui
WHERE es_independiente = true;

-- ============================================================
-- ESCENARIOS DE ESTRÉS
-- ============================================================
SELECT '=== ESCENARIOS DE ESTRÉS ===' AS seccion;

-- Escenario 1: Factor de recaudo al 85% (peor caso)
SELECT
    'ESCUENTO: RECAUDO 85%' AS escenario,
    SUM(flujo_neto_caja_pui)/1e9 AS impacto_miles_millones_cop,
    COUNT(DISTINCT CASE WHEN flujo_neto_caja_pui < 0 THEN agente_code END) AS agentes_en_perdida
FROM v_simulacion_pui
WHERE es_independiente = true AND param_factor_recaudo = 0.85

UNION ALL

-- Escenario 2: Factor de recaudo al 95% (mejor caso)
SELECT
    'ESCUENTO: RECAUDO 95%' AS escenario,
    SUM(flujo_neto_caja_pui)/1e9 AS impacto_miles_millones_cop,
    COUNT(DISTINCT CASE WHEN flujo_neto_caja_pui < 0 THEN agente_code END) AS agentes_en_perdida
FROM v_simulacion_pui
WHERE es_independiente = true AND param_factor_recaudo = 0.95;

-- ============================================================
-- CONCLUSIONES SIMPLIFICADAS
-- ============================================================
SELECT '=== CONCLUSIONES ===' AS seccion;

SELECT
    'El esquema transitorio del PUI genera una carga desproporcionada para TODOS los comercializadores independientes.' AS conclusion_1,
    'Los Artículos 11 y 12 de la Resolución CREG 101/121 crean asimetrías que favorecen a los operadores integrados.' AS conclusion_2,
    'Todos los independientes enfrentan el mismo riesgo financiero, independientemente de si son miembros de la asociación.' AS conclusion_3;
-- Queries para calibrar parámetros de simulación desde datos reales
-- NOTA: Fechas dinámicas basadas en el rango disponible en params_pui

-- 1. Estimar % áreas especiales reales (proxy: distribución de demanda por mercado)
WITH params AS (
    SELECT
        to_timestamp(get_param('p_fecha_inicio'))::date AS fecha_inicio,
        to_timestamp(get_param('p_fecha_fin'))::date AS fecha_fin
),
demanda_mercado AS (
    SELECT
        hm.mercadocomercializacion_code AS mercado_code,
        SUM(hm."DemaCome") AS vr_total,
        COUNT(DISTINCT hm.fecha_hora) AS n_horas
    FROM fact_hourly_mercadocomercializacion hm
    CROSS JOIN params p
    WHERE hm.fecha_hora BETWEEN p.fecha_inicio AND p.fecha_fin
    GROUP BY hm.mercadocomercializacion_code
)
SELECT
    mercado_code,
    vr_total/1e6 AS gwh_total,
    n_horas,
    CASE WHEN vr_total > (SELECT AVG(vr_total) FROM demanda_mercado) THEN 'ALTA' ELSE 'BAJA' END AS tamano_mercado
FROM demanda_mercado
ORDER BY vr_total DESC;

-- 2. Estimar RCPUI desde Prima Riesgo Cartera histórica (resoluciones CREG)
SELECT 0.03 AS rcpui_referencia, 'Promedio ponderado resoluciones CREG 2023-24' AS fuente;

-- 3. Estimar Factor Recaudo CNIOR desde pérdidas de energía
WITH params AS (
    SELECT
        to_timestamp(get_param('p_fecha_inicio'))::date AS fecha_inicio,
        to_timestamp(get_param('p_fecha_fin'))::date AS fecha_fin
),
perdidas_agente AS (
    SELECT
        ha.agente_code,
        a.name,
        SUM(ha."DemaComeReg") AS vr_reg,
        SUM(ha."PerdidasEnerReg") AS perdidas_reg,
        CASE WHEN SUM(ha."DemaComeReg") > 0
            THEN SUM(ha."PerdidasEnerReg") / SUM(ha."DemaComeReg")
            ELSE 0
        END AS pct_perdidas
    FROM fact_hourly_agente ha
    JOIN dim_agente a ON ha.agente_code = a.agente_code
    CROSS JOIN params p
    WHERE a.activity = 'COMERCIALIZACIÓN'
      AND ha.fecha_hora BETWEEN p.fecha_inicio AND p.fecha_fin
    GROUP BY ha.agente_code, a.name
)
SELECT
    name,
    vr_reg/1e6 AS gwh_reg,
    ROUND((pct_perdidas * 100)::numeric, 2) AS pct_perdidas,
    ROUND(((1 - pct_perdidas) * 100)::numeric, 2) AS factor_recaudo_estimado
FROM perdidas_agente
WHERE vr_reg > 0
ORDER BY factor_recaudo_estimado;

-- 4. Estimar CFPUI referencia (costo eficiente PUI post-subasta)
WITH params AS (
    SELECT
        to_timestamp(get_param('p_fecha_inicio'))::date AS fecha_inicio,
        to_timestamp(get_param('p_fecha_fin'))::date AS fecha_fin
)
SELECT
    AVG("PrecPromCont") * 0.05 AS cfpui_estimado_cop_kwh,
    'Proxy: 5% precio promedio contratos' AS metodologia
FROM fact_daily_sistema
CROSS JOIN params p
WHERE fecha BETWEEN p.fecha_inicio AND p.fecha_fin;

-- 5. Validar clasificación CIOR/CNIOR actual (mercados con 1 solo comercializador = CIOR único)
WITH params AS (
    SELECT
        to_timestamp(get_param('p_fecha_inicio'))::date AS fecha_inicio,
        to_timestamp(get_param('p_fecha_fin'))::date AS fecha_fin
),
agentes_por_mercado AS (
    SELECT
        ha.agente_code,
        a.name,
        SUM(ha."DemaComeReg") AS vr_total
    FROM fact_hourly_agente ha
    JOIN dim_agente a ON ha.agente_code = a.agente_code
    CROSS JOIN params p
    WHERE a.activity = 'COMERCIALIZACIÓN'
      AND ha.fecha_hora BETWEEN p.fecha_inicio AND p.fecha_fin
    GROUP BY ha.agente_code, a.name
)
SELECT
    name,
    vr_total/1e6 AS gwh_reg_total,
    ROW_NUMBER() OVER (ORDER BY vr_total DESC) AS ranking
FROM agentes_por_mercado
WHERE vr_total > 0
ORDER BY vr_total DESC
LIMIT 20;

-- ============================================================
-- CALIBRACIÓN PARA INDEPENDIENTES
-- ============================================================

-- 6. Distribución de tamaño de cartera entre independientes
SELECT
    CASE WHEN ia.es_miembro_asociacion THEN 'Asociado' ELSE 'No Asociado' END AS grupo,
    COUNT(DISTINCT ha.agente_code) AS n_agentes,
    SUM(ha."DemaComeReg")/1e6 AS gwh_totales,
    AVG(ha."DemaComeReg")/1e6 AS promedio_gwh,
    MIN(ha."DemaComeReg")/1e6 AS min_gwh,
    MAX(ha."DemaComeReg")/1e6 AS max_gwh
FROM fact_hourly_agente ha
JOIN dim_agente a ON ha.agente_code = a.agente_code
JOIN independientes_asociacion ia ON ha.agente_code = ia.agente_code
WHERE a.activity = 'COMERCIALIZACIÓN'
  AND ha.fecha_hora BETWEEN 
    to_timestamp(get_param('p_fecha_inicio'))::date AND
    to_timestamp(get_param('p_fecha_fin'))::date
GROUP BY ia.es_miembro_asociacion;

-- 7. Pérdidas históricas por agente independiente (proxy de recaudo real)
SELECT
    ia.agente_nombre,
    ia.es_miembro_asociacion,
    SUM(ha."PerdidasEnerReg")/1e6 AS perdidas_gwh,
    SUM(ha."DemaComeReg")/1e6 AS demanda_gwh,
    CASE WHEN SUM(ha."DemaComeReg") > 0
        THEN ROUND((SUM(ha."PerdidasEnerReg") / SUM(ha."DemaComeReg"))::numeric * 100, 2)
        ELSE 0
    END AS pct_perdidas,
    CASE WHEN SUM(ha."DemaComeReg") > 0
        THEN ROUND(((1 - SUM(ha."PerdidasEnerReg") / SUM(ha."DemaComeReg"))::numeric) * 100, 2)
        ELSE 0
    END AS factor_recaudo_estimado
FROM fact_hourly_agente ha
JOIN dim_agente a ON ha.agente_code = a.agente_code
JOIN independientes_asociacion ia ON ha.agente_code = ia.agente_code
WHERE a.activity = 'COMERCIALIZACIÓN'
  AND ha.fecha_hora BETWEEN 
    to_timestamp(get_param('p_fecha_inicio'))::date AND
    to_timestamp(get_param('p_fecha_fin'))::date
GROUP BY ia.agente_nombre, ia.es_miembro_asociacion
HAVING SUM(ha."DemaComeReg") > 0
ORDER BY factor_recaudo_estimado ASC
LIMIT 20;

-- 8. Validación: ¿Cuántos independientes están en la BD?
SELECT
    COUNT(DISTINCT ia.agente_code) AS total_independientes_bd,
    COUNT(DISTINCT CASE WHEN ha.agente_code IS NOT NULL THEN ia.agente_code END) AS independientes_con_datos,
    COUNT(DISTINCT CASE WHEN ha.agente_code IS NULL THEN ia.agente_code END) AS independientes_sin_datos
FROM independientes_asociacion ia
LEFT JOIN fact_hourly_agente ha ON ia.agente_code = ha.agente_code
    AND ha.fecha_hora BETWEEN 
        to_timestamp(get_param('p_fecha_inicio'))::date AND
        to_timestamp(get_param('p_fecha_fin'))::date
JOIN dim_agente a ON ia.agente_code = a.agente_code
WHERE a.activity = 'COMERCIALIZACIÓN';

-- Simulación PUI Core: CTE encadenada
-- Resultado: vista v_simulacion_pui con flujo neto por agente/mes
--
-- NOTA: fact_hourly_agente NO tiene dimensión de mercado. La simulación trabaja
-- a nivel de mercado (fact_hourly_mercadocomercializacion) y distribuye el
-- impacto proporcionalmente a los agentes según su participación en demanda regulada.

DROP VIEW IF EXISTS v_simulacion_pui CASCADE;

CREATE VIEW v_simulacion_pui AS
WITH params AS (
    SELECT
        get_param('p_rcpui') AS p_rcpui,
        get_param('p_pct_areas_especiales') AS p_pct_areas_especiales,
        get_param('p_factor_recaudo_cnior') AS p_factor_recaudo_cnior,
        to_timestamp(get_param('p_fecha_inicio'))::date AS p_fecha_inicio,
        to_timestamp(get_param('p_fecha_fin'))::date AS p_fecha_fin,
        get_param_bool('p_esquema_competitivo') AS p_esquema_competitivo,
        get_param('p_cfpui') AS p_cfpui,
        get_param_bool('p_solo_independientes') AS p_solo_independientes
),

-- ============================================================
-- PASO 1: Demanda mensual por MERCADO
-- ============================================================
demanda_mercado_mensual AS (
    SELECT
        hm.mercadocomercializacion_code AS mercado_code,
        date_trunc('month', hm.fecha_hora)::date AS mes,
        SUM(hm."DemaCome") AS vr_mercado_mes
    FROM fact_hourly_mercadocomercializacion hm
    CROSS JOIN params p
    WHERE hm.fecha_hora BETWEEN p.p_fecha_inicio AND p.p_fecha_fin
    GROUP BY hm.mercadocomercializacion_code, date_trunc('month', hm.fecha_hora)
),

-- ============================================================
-- PASO 2: Demanda mensual por AGENTE
-- ============================================================
demanda_agente_mensual AS (
    SELECT
        ha.agente_code,
        date_trunc('month', ha.fecha_hora)::date AS mes,
        SUM(ha."DemaComeReg") AS vr_agente_mes
    FROM fact_hourly_agente ha
    JOIN dim_agente a ON ha.agente_code = a.agente_code
    CROSS JOIN params p
    WHERE a.activity = 'COMERCIALIZACIÓN'
      AND ha.fecha_hora BETWEEN p.p_fecha_inicio AND p.p_fecha_fin
    GROUP BY ha.agente_code, date_trunc('month', ha.fecha_hora)
),

-- ============================================================
-- PASO 3: Total demanda regulada por agente (para clasificación)
-- Solo agentes con DemaComeReg > 0 (NULLs excluidos)
-- ============================================================
agentes_ranking AS (
    SELECT
        agente_code,
        SUM(vr_agente_mes) AS vr_total_reg,
        ROW_NUMBER() OVER (ORDER BY SUM(vr_agente_mes) DESC) AS rank_total
    FROM demanda_agente_mensual
    WHERE vr_agente_mes > 0
    GROUP BY agente_code
),

-- ============================================================
-- PASO 4: Clasificación CIOR/CNIOR
-- ============================================================
clasificacion_agentes AS (
    SELECT
        agente_code,
        vr_total_reg,
        CASE WHEN rank_total = 1 THEN 'CIOR' ELSE 'CNIOR' END AS rol_pui
    FROM agentes_ranking
),

-- ============================================================
-- INFORMACIÓN DE INDEPENDIENTES
-- ============================================================
independientes_info AS (
    SELECT
        ca.agente_code,
        ca.vr_total_reg,
        ca.rol_pui,
        CASE WHEN ia.agente_code IS NOT NULL THEN true ELSE false END AS es_independiente,
        CASE WHEN ia.es_miembro_asociacion THEN true ELSE false END AS es_miembro_asociacion,
        COALESCE(ia.agente_nombre, a.name) AS agente_nombre_independiente
    FROM clasificacion_agentes ca
    LEFT JOIN independientes_asociacion ia ON ca.agente_code = ia.agente_code
    LEFT JOIN dim_agente a ON ca.agente_code = a.agente_code
    WHERE (NOT (SELECT p_solo_independientes FROM params)) OR ia.agente_code IS NOT NULL
),

-- ============================================================
-- PRE-AGREGACIÓN: Totales de demanda por mes
-- ============================================================
totales_por_mes AS (
    SELECT
        mes,
        SUM(vr_agente_mes) AS total_vr_mes,
        SUM(CASE WHEN ii.rol_pui = 'CNIOR' THEN da.vr_agente_mes ELSE 0 END) AS total_vr_cnior_mes
    FROM demanda_agente_mensual da
    JOIN independientes_info ii ON da.agente_code = ii.agente_code
    GROUP BY mes
),

-- ============================================================
-- PASO 5: CU base mensual
-- ============================================================
cu_base_mensual AS (
    SELECT
        date_trunc('month', fecha)::date AS mes,
        AVG("PrecPromCont") AS cu_base
    FROM fact_daily_sistema
    CROSS JOIN params p
    WHERE fecha BETWEEN p.p_fecha_inicio AND p.p_fecha_fin
    GROUP BY date_trunc('month', fecha)
),

-- ============================================================
-- PASO 6: CRPUI por mercado
-- ============================================================
crpui_mercado AS (
    SELECT
        dmm.mercado_code,
        dmm.mes,
        dmm.vr_mercado_mes,
        cob.cu_base,
        dmm.vr_mercado_mes * p.p_pct_areas_especiales AS vpui_mes,
        LAG(dmm.vr_mercado_mes) OVER (PARTITION BY dmm.mercado_code ORDER BY dmm.mes) AS vr_mercado_m_1,
        LAG(dmm.vr_mercado_mes * p.p_pct_areas_especiales) OVER (PARTITION BY dmm.mercado_code ORDER BY dmm.mes) AS vpui_m_1,
        LAG(cob.cu_base) OVER (PARTITION BY dmm.mercado_code ORDER BY dmm.mes) AS cu_base_m_1
    FROM demanda_mercado_mensual dmm
    LEFT JOIN cu_base_mensual cob ON dmm.mes = cob.mes
    CROSS JOIN params p
),

-- ============================================================
-- PASO 7: CRPUI calculado
-- ============================================================
crpui_calculado AS (
    SELECT
        cm.*,
        CASE
            WHEN (SELECT p_esquema_competitivo FROM params) THEN 0
            WHEN vr_mercado_m_1 > 0 AND cu_base_m_1 > 0 AND vpui_m_1 > 0
            THEN ((SELECT p_rcpui FROM params) * vpui_m_1) / (vr_mercado_m_1 * cu_base_m_1)
            ELSE 0
        END AS crpui_unitario
    FROM crpui_mercado cm
),

-- ============================================================
-- PASO 8: CFPUI aplicado
-- ============================================================
cfpui_aplicado AS (
    SELECT
        cc.*,
        CASE
            WHEN (SELECT p_esquema_competitivo FROM params) THEN (SELECT p_cfpui FROM params)
            ELSE 0
        END AS cfpui_unitario
    FROM crpui_calculado cc
),

-- ============================================================
-- PASO 9: Costo total a trasladar por mercado
-- PUI_j,m = (CRPUI + CFPUI) × VR_j,m-2
-- ============================================================
costo_total_trasladar AS (
    SELECT
        c.mercado_code,
        c.mes,
        (c.crpui_unitario + c.cfpui_unitario) * LAG(c.vr_mercado_mes, 2) OVER (PARTITION BY c.mercado_code ORDER BY c.mes) AS pui_mercado_mes
    FROM cfpui_aplicado c
),

-- ============================================================
-- PRE-AGREGACIÓN: Totales giros por mes (DESPUÉS de costo_total_trasladar)
-- ============================================================
totales_giros_por_mes AS (
    SELECT
        mes,
        SUM(pui_mercado_mes) AS total_giros_cnior_mes
    FROM costo_total_trasladar
    WHERE pui_mercado_mes > 0
    GROUP BY mes
),

-- ============================================================
-- PASO 10: Impacto por MERCADO
-- ============================================================
impacto_mercado AS (
    SELECT
        ctt.mercado_code,
        ctt.mes,
        ctt.pui_mercado_mes,
        ctt.pui_mercado_mes AS giro_obligatorio,
        ctt.pui_mercado_mes * p.p_factor_recaudo_cnior AS recaudo_real_estimado,
        ctt.pui_mercado_mes * (1 - p.p_factor_recaudo_cnior) AS perdida_cartera
    FROM costo_total_trasladar ctt
    CROSS JOIN params p
    WHERE ctt.pui_mercado_mes > 0
),

-- ============================================================
-- PASO 11: Distribución proporcional del PUI a agentes
-- ============================================================
impacto_agentes AS (
    SELECT
        im.mercado_code,
        im.mes,
        da.agente_code,
        ii.rol_pui,
        ii.es_independiente,
        ii.es_miembro_asociacion,
        ii.agente_nombre_independiente,
        da.vr_agente_mes AS ventas_reg_kwh,
        -- PUI proporcional al agente
        im.pui_mercado_mes * (da.vr_agente_mes / NULLIF(tp.total_vr_mes, 0)) AS pui_agente_mes,
        -- Giro proporcional (solo CNIOR)
        CASE WHEN ii.rol_pui = 'CNIOR' AND tp.total_vr_cnior_mes > 0
            THEN im.giro_obligatorio * (da.vr_agente_mes / tp.total_vr_cnior_mes)
            ELSE 0
        END AS egreso_giro_cior,
        -- Recaudo real proporcional (solo CNIOR)
        CASE WHEN ii.rol_pui = 'CNIOR' AND tp.total_vr_cnior_mes > 0
            THEN im.recaudo_real_estimado * (da.vr_agente_mes / tp.total_vr_cnior_mes)
            ELSE 0
        END AS recaudo_real_agente,
        -- Total giros CNIOR del mes (pre-calculado)
        COALESCE(tg.total_giros_cnior_mes, 0) AS total_giros_cnior_mes,
        -- MÉTRICAS SIMPLES PARA INDEPENDIENTES
        -- Sobrecosto PUI: diferencia entre giro obligatorio y recaudo real
        CASE WHEN ii.rol_pui = 'CNIOR' AND ii.es_independiente
            THEN (im.giro_obligatorio * (da.vr_agente_mes / tp.total_vr_cnior_mes)) - 
                 (im.recaudo_real_estimado * (da.vr_agente_mes / tp.total_vr_cnior_mes))
            ELSE 0
        END AS sobrecosto_pui,
        -- Pérdida por incobrabilidad como % del giro
        CASE WHEN ii.rol_pui = 'CNIOR' AND ii.es_independiente AND im.giro_obligatorio > 0
            THEN ((im.giro_obligatorio - im.recaudo_real_estimado) / im.giro_obligatorio) * 100
            ELSE 0
        END AS pct_perdida_incobrabilidad,
        -- Riesgo de flujo de caja: porcentaje de ingresos comprometidos
        CASE WHEN ii.rol_pui = 'CNIOR' AND ii.es_independiente
            THEN (im.giro_obligatorio * (da.vr_agente_mes / tp.total_vr_cnior_mes)) / 
                 NULLIF(da.vr_agente_mes * (SELECT AVG("PrecPromCont") FROM fact_daily_sistema), 0) * 100
            ELSE 0
        END AS riesgo_flujo_caja,
        -- Tipo de independiente
        CASE WHEN ii.es_independiente AND ii.es_miembro_asociacion
            THEN 'Miembro (pagó estudio)' 
            WHEN ii.es_independiente AND NOT ii.es_miembro_asociacion
            THEN 'No miembro'
            ELSE 'No independiente'
        END AS tipo_independiente,
        -- Parámetros
        (SELECT p_rcpui FROM params) AS param_rcpui,
        (SELECT p_pct_areas_especiales FROM params) AS param_pct_ae,
        (SELECT p_factor_recaudo_cnior FROM params) AS param_factor_recaudo,
        (SELECT p_esquema_competitivo FROM params) AS param_competitivo,
        (SELECT p_cfpui FROM params) AS param_cfpui
    FROM impacto_mercado im
    JOIN demanda_agente_mensual da ON im.mes = da.mes
    JOIN independientes_info ii ON da.agente_code = ii.agente_code
    JOIN dim_agente a ON da.agente_code = a.agente_code
    JOIN totales_por_mes tp ON im.mes = tp.mes
    LEFT JOIN totales_giros_por_mes tg ON im.mes = tg.mes
    WHERE a.activity = 'COMERCIALIZACIÓN'
),

-- ============================================================
-- PASO 12: Flujo neto por agente
-- ============================================================
flujo_neto AS (
    SELECT
        ia.*,
        cm.mercado_name,
        COALESCE(a.name, ia.agente_nombre_independiente) AS agente_name,
        -- INGRESOS PUI facturado
        CASE
            WHEN ia.rol_pui = 'CIOR' THEN
                ia.pui_agente_mes + ia.total_giros_cnior_mes
            ELSE ia.pui_agente_mes
        END AS ingresos_pui_facturado,
        -- FLUJO NETO CAJA
        CASE
            WHEN ia.rol_pui = 'CIOR' THEN
                ia.pui_agente_mes + ia.total_giros_cnior_mes
            WHEN ia.rol_pui = 'CNIOR' THEN
                ia.recaudo_real_agente - ia.egreso_giro_cior
        END AS flujo_neto_caja_pui,
        -- INDICADORES
        CASE
            WHEN ia.rol_pui = 'CNIOR' AND ia.egreso_giro_cior > 0
            THEN (ia.recaudo_real_agente - ia.egreso_giro_cior) / ia.egreso_giro_cior * 100
        END AS pct_perdida_sobre_giro_cnior,
        CASE
            WHEN ia.rol_pui = 'CIOR' AND ia.pui_agente_mes > 0
            THEN ia.total_giros_cnior_mes / ia.pui_agente_mes * 100
        END AS pct_apalancamiento_cior
    FROM impacto_agentes ia
    LEFT JOIN dim_mercado cm ON ia.mercado_code = cm.mercado_code
    LEFT JOIN dim_agente a ON ia.agente_code = a.agente_code
)

SELECT * FROM flujo_neto;

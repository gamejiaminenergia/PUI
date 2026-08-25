-- Función parametrizada para simulación PUI
-- Permite ejecutar escenarios sin modificar parámetros en tabla
-- NOTA: Trabaja a nivel de mercado (fact_hourly_mercadocomercializacion)
-- y distribuye impacto proporcionalmente a agentes.

CREATE OR REPLACE FUNCTION fn_simulacion_pui(
    p_fecha_ini DATE DEFAULT '2024-01-01',
    p_fecha_fin DATE DEFAULT '2026-12-31',
    p_val_rcpui NUMERIC DEFAULT 0.03,
    p_val_pct_ae NUMERIC DEFAULT 0.10,
    p_val_factor_recaudo NUMERIC DEFAULT 0.92,
    p_val_esquema_comp BOOLEAN DEFAULT false,
    p_val_cfpui NUMERIC DEFAULT 0.025,
    p_solo_independientes BOOLEAN DEFAULT true
) RETURNS TABLE (
    mercado_code TEXT,
    mercado_name TEXT,
    mes DATE,
    agente_code TEXT,
    agente_name TEXT,
    rol_pui TEXT,
    es_independiente BOOLEAN,
    es_miembro_asociacion BOOLEAN,
    ventas_reg_kwh NUMERIC,
    ingresos_pui_facturado NUMERIC,
    egreso_giro_cior NUMERIC,
    flujo_neto_caja_pui NUMERIC,
    pct_perdida_sobre_giro_cnior NUMERIC,
    pct_apalancamiento_cior NUMERIC,
    sobrecosto_pui NUMERIC,
    pct_perdida_incobrabilidad NUMERIC,
    riesgo_flujo_caja NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH cte_params AS (
        SELECT
            p_val_rcpui AS v_rcpui,
            p_val_pct_ae AS v_pct_ae,
            p_val_factor_recaudo AS v_factor_recaudo,
            p_fecha_ini AS v_fecha_inicio,
            p_fecha_fin AS v_fecha_fin,
            p_val_esquema_comp AS v_esquema_competitivo,
            p_val_cfpui AS v_cfpui
    ),

    -- Demanda mensual por MERCADO
    cte_demanda_mercado AS (
        SELECT
            hm.mercadocomercializacion_code AS mkt_code,
            date_trunc('month', hm.fecha_hora)::date AS m_mes,
            SUM(hm."DemaCome") AS m_vr_mes
        FROM fact_hourly_mercadocomercializacion hm
        CROSS JOIN cte_params p
        WHERE hm.fecha_hora BETWEEN p.v_fecha_inicio AND p.v_fecha_fin
        GROUP BY hm.mercadocomercializacion_code, date_trunc('month', hm.fecha_hora)
    ),

    -- Demanda mensual por AGENTE
    cte_demanda_agente AS (
        SELECT
            ha.agente_code AS a_code,
            date_trunc('month', ha.fecha_hora)::date AS a_mes,
            SUM(ha."DemaComeReg") AS a_vr_mes
        FROM fact_hourly_agente ha
        JOIN dim_agente a ON ha.agente_code = a.agente_code
        CROSS JOIN cte_params p
        WHERE a.activity = 'COMERCIALIZACIÓN'
          AND ha.fecha_hora BETWEEN p.v_fecha_inicio AND p.v_fecha_fin
        GROUP BY ha.agente_code, date_trunc('month', ha.fecha_hora)
    ),

    -- Ranking de agentes por demanda regulada total (solo agentes con datos)
    cte_ranking AS (
        SELECT
            a_code,
            SUM(a_vr_mes) AS r_total,
            ROW_NUMBER() OVER (ORDER BY SUM(a_vr_mes) DESC) AS r_rank
        FROM cte_demanda_agente
        WHERE a_vr_mes > 0
        GROUP BY a_code
    ),

    -- Clasificación CIOR/CNIOR
    cte_clasif AS (
        SELECT
            a_code,
            r_total,
            CASE WHEN r_rank = 1 THEN 'CIOR' ELSE 'CNIOR' END AS c_rol
        FROM cte_ranking
    ),

    -- Información de independientes
    cte_independientes AS (
        SELECT
            cl.a_code,
            cl.r_total,
            cl.c_rol,
            CASE WHEN ia.agente_code IS NOT NULL THEN true ELSE false END AS c_es_independiente,
            COALESCE(ia.es_miembro_asociacion, false) AS c_es_miembro_asociacion
        FROM cte_clasif cl
        LEFT JOIN independientes_asociacion ia ON cl.a_code = ia.agente_code
        WHERE (NOT p_solo_independientes) OR ia.agente_code IS NOT NULL
    ),

    -- Pre-agregación: totales demanda por mes
    cte_totales_mes AS (
        SELECT
            da.a_mes AS t_mes,
            SUM(da.a_vr_mes) AS t_vr_total,
            SUM(CASE WHEN ci.c_rol = 'CNIOR' THEN da.a_vr_mes ELSE 0 END) AS t_vr_cnior
        FROM cte_demanda_agente da
        JOIN cte_independientes ci ON da.a_code = ci.a_code
        GROUP BY da.a_mes
    ),

    -- CU base mensual
    cte_cu_base AS (
        SELECT
            date_trunc('month', fecha)::date AS cb_mes,
            AVG("PrecPromCont") AS cb_cu
        FROM fact_daily_sistema
        CROSS JOIN cte_params p
        WHERE fecha BETWEEN p.v_fecha_inicio AND p.v_fecha_fin
        GROUP BY date_trunc('month', fecha)
    ),

    -- CRPUI por mercado
    cte_crpui_mercado AS (
        SELECT
            dm.mkt_code AS cm_mercado,
            dm.m_mes AS cm_mes,
            dm.m_vr_mes AS cm_vr,
            cb.cb_cu AS cm_cu,
            dm.m_vr_mes * p.v_pct_ae AS cm_vpui,
            LAG(dm.m_vr_mes) OVER (PARTITION BY dm.mkt_code ORDER BY dm.m_mes) AS cm_vr_m1,
            LAG(dm.m_vr_mes * p.v_pct_ae) OVER (PARTITION BY dm.mkt_code ORDER BY dm.m_mes) AS cm_vpui_m1,
            LAG(cb.cb_cu) OVER (PARTITION BY dm.mkt_code ORDER BY dm.m_mes) AS cm_cu_m1
        FROM cte_demanda_mercado dm
        LEFT JOIN cte_cu_base cb ON dm.m_mes = cb.cb_mes
        CROSS JOIN cte_params p
    ),

    -- CRPUI calculado
    cte_crpui_calc AS (
        SELECT
            cr.*,
            CASE
                WHEN p.v_esquema_competitivo THEN 0
                WHEN cm_vr_m1 > 0 AND cm_cu_m1 > 0 AND cm_vpui_m1 > 0
                THEN (p.v_rcpui * cm_vpui_m1) / (cm_vr_m1 * cm_cu_m1)
                ELSE 0
            END AS cc_crpui
        FROM cte_crpui_mercado cr
        CROSS JOIN cte_params p
    ),

    -- CFPUI aplicado
    cte_cfpui AS (
        SELECT
            cc.*,
            CASE
                WHEN p.v_esquema_competitivo THEN p.v_cfpui
                ELSE 0
            END AS cf_cfpui
        FROM cte_crpui_calc cc
        CROSS JOIN cte_params p
    ),

    -- Costo total a trasladar por mercado
    cte_costo_total AS (
        SELECT
            c.cm_mercado AS ct_mercado,
            c.cm_mes AS ct_mes,
            (c.cc_crpui + c.cf_cfpui) * LAG(c.cm_vr, 2) OVER (PARTITION BY c.cm_mercado ORDER BY c.cm_mes) AS ct_pui
        FROM cte_cfpui c
    ),

    -- Totales giros por mes (pre-calculado)
    cte_totales_giros AS (
        SELECT
            ct_mes AS tg_mes,
            SUM(ct_pui) AS tg_total
        FROM cte_costo_total
        WHERE ct_pui > 0
        GROUP BY ct_mes
    ),

    -- Impacto por mercado
    cte_impacto_mercado AS (
        SELECT
            ct.ct_mercado AS im_mercado,
            ct.ct_mes AS im_mes,
            ct.ct_pui AS im_pui,
            ct.ct_pui AS im_giro,
            ct.ct_pui * p.v_factor_recaudo AS im_recaudo,
            ct.ct_pui * (1 - p.v_factor_recaudo) AS im_perdida
        FROM cte_costo_total ct
        CROSS JOIN cte_params p
        WHERE ct.ct_pui > 0
    ),

    -- Distribución proporcional a agentes
    cte_impacto_agentes AS (
        SELECT
            im.im_mercado AS ia_mercado,
            im.im_mes AS ia_mes,
            da.a_code AS ia_agente,
            ci.c_rol AS ia_rol,
            ci.c_es_independiente AS ia_es_independiente,
            ci.c_es_miembro_asociacion AS ia_es_miembro_asociacion,
            da.a_vr_mes AS ia_vr,
            im.im_pui * (da.a_vr_mes / NULLIF(tt.t_vr_total, 0)) AS ia_pui,
            CASE WHEN ci.c_rol = 'CNIOR' AND tt.t_vr_cnior > 0
                THEN im.im_giro * (da.a_vr_mes / tt.t_vr_cnior)
                ELSE 0
            END AS ia_giro,
            CASE WHEN ci.c_rol = 'CNIOR' AND tt.t_vr_cnior > 0
                THEN im.im_recaudo * (da.a_vr_mes / tt.t_vr_cnior)
                ELSE 0
            END AS ia_recaudo,
            COALESCE(tg.tg_total, 0) AS ia_total_giros,
            -- Sobrecosto PUI
            CASE WHEN ci.c_rol = 'CNIOR' AND ci.c_es_independiente
                THEN (im.im_giro * (da.a_vr_mes / tt.t_vr_cnior)) -
                     (im.im_recaudo * (da.a_vr_mes / tt.t_vr_cnior))
                ELSE 0
            END AS ia_sobrecosto,
            -- Pérdida por incobrabilidad
            CASE WHEN ci.c_rol = 'CNIOR' AND ci.c_es_independiente AND im.im_giro > 0
                THEN ((im.im_giro - im.im_recaudo) / im.im_giro) * 100
                ELSE 0
            END AS ia_pct_perdida,
            -- Riesgo flujo caja
            CASE WHEN ci.c_rol = 'CNIOR' AND ci.c_es_independiente
                THEN (im.im_giro * (da.a_vr_mes / tt.t_vr_cnior)) /
                     NULLIF(da.a_vr_mes * (SELECT AVG("PrecPromCont") FROM fact_daily_sistema), 0) * 100
                ELSE 0
            END AS ia_riesgo_flujo,
            p_val_rcpui AS ia_param_rcpui,
            p_val_pct_ae AS ia_param_pct_ae,
            p_val_factor_recaudo AS ia_param_factor_recaudo,
            p_val_esquema_comp AS ia_param_competitivo,
            p_val_cfpui AS ia_param_cfpui
        FROM cte_impacto_mercado im
        JOIN cte_demanda_agente da ON im.im_mes = da.a_mes
        JOIN cte_independientes ci ON da.a_code = ci.a_code
        JOIN cte_totales_mes tt ON im.im_mes = tt.t_mes
        LEFT JOIN cte_totales_giros tg ON im.im_mes = tg.tg_mes
    ),

    -- Flujo neto por agente
    cte_flujo_neto AS (
        SELECT
            ia.*,
            cm.mercado_name AS fn_mercado_name,
            COALESCE(a.name, ia.ia_agente) AS fn_agente_name,
            CASE
                WHEN ia.ia_rol = 'CIOR' THEN
                    ia.ia_pui + ia.ia_total_giros
                ELSE ia.ia_pui
            END AS fn_ingresos,
            CASE
                WHEN ia.ia_rol = 'CIOR' THEN
                    ia.ia_pui + ia.ia_total_giros
                WHEN ia.ia_rol = 'CNIOR' THEN
                    ia.ia_recaudo - ia.ia_giro
            END AS fn_flujo_neto,
            CASE
                WHEN ia.ia_rol = 'CNIOR' AND ia.ia_giro > 0
                THEN (ia.ia_recaudo - ia.ia_giro) / ia.ia_giro * 100
            END AS fn_pct_perdida,
            CASE
                WHEN ia.ia_rol = 'CIOR' AND ia.ia_pui > 0
                THEN ia.ia_total_giros / ia.ia_pui * 100
            END AS fn_pct_apalancamiento
        FROM cte_impacto_agentes ia
        LEFT JOIN dim_mercado cm ON ia.ia_mercado = cm.mercado_code
        LEFT JOIN dim_agente a ON ia.ia_agente = a.agente_code
    )

    SELECT
        fn.ia_mercado::TEXT,
        fn.fn_mercado_name::TEXT,
        fn.ia_mes,
        fn.ia_agente::TEXT,
        fn.fn_agente_name::TEXT,
        fn.ia_rol::TEXT,
        fn.ia_es_independiente::BOOLEAN,
        fn.ia_es_miembro_asociacion::BOOLEAN,
        fn.ia_vr::NUMERIC,
        fn.fn_ingresos::NUMERIC,
        fn.ia_giro::NUMERIC,
        fn.fn_flujo_neto::NUMERIC,
        fn.fn_pct_perdida::NUMERIC,
        fn.fn_pct_apalancamiento::NUMERIC,
        fn.ia_sobrecosto::NUMERIC,
        fn.ia_pct_perdida::NUMERIC,
        fn.ia_riesgo_flujo::NUMERIC
    FROM cte_flujo_neto fn;
END;
$$ LANGUAGE plpgsql;

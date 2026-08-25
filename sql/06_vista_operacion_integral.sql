-- Vista integral de operación de comercializadores independientes
-- Combina: Compra (contratos+bolsa), Venta (contratos+bolsa), Demanda y PUI

DROP VIEW IF EXISTS v_operacion_integral_independientes CASCADE;

CREATE VIEW v_operacion_integral_independientes AS
WITH datos_agente AS (
    SELECT 
        ia.agente_code,
        ia.agente_nombre,
        ia.es_miembro_asociacion,
        -- COMPRA DE ENERGÍA
        SUM(COALESCE(ha."CompContEner", 0)) AS compra_contratos_kwh,
        SUM(COALESCE(ha."CompBolsNaciEner", 0) + COALESCE(ha."CompBolsaIntEner", 0) + COALESCE(ha."CompBolsaTIEEner", 0)) AS compra_bolsa_kwh,
        SUM(COALESCE(ha."CompContEner", 0) + COALESCE(ha."CompBolsNaciEner", 0) + COALESCE(ha."CompBolsaIntEner", 0) + COALESCE(ha."CompBolsaTIEEner", 0)) AS compra_total_kwh,
        -- VENTA DE ENERGÍA
        SUM(COALESCE(ha."VentContEner", 0)) AS venta_contratos_kwh,
        SUM(COALESCE(ha."VentBolsNaciEner", 0) + COALESCE(ha."VentBolsaIntEner", 0) + COALESCE(ha."VentBolsaTIEEner", 0)) AS venta_bolsa_kwh,
        SUM(COALESCE(ha."VentContEner", 0) + COALESCE(ha."VentBolsNaciEner", 0) + COALESCE(ha."VentBolsaIntEner", 0) + COALESCE(ha."VentBolsaTIEEner", 0)) AS venta_total_kwh,
        -- DEMANDA
        SUM(COALESCE(ha."DemaComeReg", 0)) AS demanda_regulada_kwh,
        SUM(COALESCE(ha."DemaComeNoReg", 0)) AS demanda_no_regulada_kwh,
        SUM(COALESCE(ha."DemaCome", 0)) AS demanda_total_kwh,
        -- PERDIDAS
        SUM(COALESCE(ha."PerdidasEner", 0)) AS perdidas_kwh
    FROM independientes_asociacion ia
    LEFT JOIN fact_hourly_agente ha ON ia.agente_code = ha.agente_code
        AND ha.fecha_hora BETWEEN 
            to_timestamp(get_param('p_fecha_inicio'))::date AND 
            to_timestamp(get_param('p_fecha_fin'))::date
    GROUP BY ia.agente_code, ia.agente_nombre, ia.es_miembro_asociacion
)
SELECT 
    agente_code,
    agente_nombre,
    CASE WHEN es_miembro_asociacion THEN 'Sí' ELSE 'No' END AS miembro_asociacion,
    -- COMPRA (GWh)
    (compra_contratos_kwh / 1e6)::numeric(12,2) AS compra_contratos_gwh,
    (compra_bolsa_kwh / 1e6)::numeric(12,2) AS compra_bolsa_gwh,
    (compra_total_kwh / 1e6)::numeric(12,2) AS compra_total_gwh,
    -- % Compra por Contratos
    CASE WHEN compra_total_kwh > 0 
        THEN ((compra_contratos_kwh / compra_total_kwh) * 100)::numeric(5,1)
        ELSE 0 
    END AS pct_compra_contratos,
    -- VENTA (GWh)
    (venta_contratos_kwh / 1e6)::numeric(12,2) AS venta_contratos_gwh,
    (venta_bolsa_kwh / 1e6)::numeric(12,2) AS venta_bolsa_gwh,
    (venta_total_kwh / 1e6)::numeric(12,2) AS venta_total_gwh,
    -- DEMANDA (GWh)
    (demanda_regulada_kwh / 1e6)::numeric(12,2) AS demanda_regulada_gwh,
    (demanda_no_regulada_kwh / 1e6)::numeric(12,2) AS demanda_no_regulada_gwh,
    (demanda_total_kwh / 1e6)::numeric(12,2) AS demanda_total_gwh,
    -- % Demanda Regulada
    CASE WHEN demanda_total_kwh > 0 
        THEN ((demanda_regulada_kwh / demanda_total_kwh) * 100)::numeric(5,1)
        ELSE 0 
    END AS pct_demanda_regulada,
    -- BALANCE COMPRA-VENTA (GWh)
    ((compra_total_kwh - venta_total_kwh) / 1e6)::numeric(12,2) AS balance_compra_venta_gwh,
    -- PERDIDAS (GWh)
    (perdidas_kwh / 1e6)::numeric(12,2) AS perdidas_gwh,
    -- % Perdidas sobre Demanda
    CASE WHEN demanda_total_kwh > 0 
        THEN ((perdidas_kwh / demanda_total_kwh) * 100)::numeric(5,2)
        ELSE 0 
    END AS pct_perdidas
FROM datos_agente
WHERE compra_total_kwh > 0 OR venta_total_kwh > 0 OR demanda_total_kwh > 0
ORDER BY compra_total_kwh DESC;
-- Tabla de parámetros configurables para simulación PUI
DROP TABLE IF EXISTS params_pui CASCADE;

CREATE TABLE params_pui (
    param_name TEXT PRIMARY KEY,
    param_value NUMERIC,
    param_text TEXT,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Detectar rango de fechas disponible en la BD
-- NOTA: La BD puede tener datos desde 2015, pero la regulación PUI es de 2024+.
-- Se usa 2024-01-01 como inicio por defecto (regulación vigente).
-- El usuario puede cambiar p_fecha_inicio/p_fecha_fin después si desea otro rango.
DO $$
DECLARE
    v_min DATE;
    v_max DATE;
BEGIN
    SELECT MIN(fecha_hora)::date, MAX(fecha_hora)::date
    INTO v_min, v_max
    FROM fact_hourly_agente;

    IF v_min IS NULL THEN
        v_min := '2024-01-01'::date;
        v_max := '2024-12-31'::date;
    ELSE
        -- Usar desde 2024 (regulación PUI) hasta la fecha máxima disponible
        v_min := GREATEST(v_min, '2024-01-01'::date);
    END IF;

    INSERT INTO params_pui (param_name, param_value, description) VALUES
    ('p_rcpui', 0.03, 'Prima riesgo cartera CIOR ($/kWh)'),
    ('p_pct_areas_especiales', 0.10, '% usuarios en áreas especiales sobre VR'),
    ('p_factor_recaudo_cnior', 0.92, 'Factor recaudo real CNIOR (0-1)'),
    ('p_fecha_inicio', EXTRACT(EPOCH FROM v_min)::numeric, 'Fecha inicio simulación (epoch) — desde 2024 (regulación PUI)'),
    ('p_fecha_fin', EXTRACT(EPOCH FROM v_max)::numeric, 'Fecha fin simulación (epoch) — detectado automáticamente'),
    ('p_esquema_competitivo', 0, '0=Transitorio CRPUI, 1=Competitivo CFPUI'),
    ('p_cfpui', 0.025, 'Costo variabilizado subasta competitiva ($/kWh)');
END $$;

-- Vista para lectura fácil de parámetros
CREATE OR REPLACE VIEW v_params_pui AS
SELECT
    param_name,
    param_value,
    CASE
        WHEN param_name IN ('p_fecha_inicio','p_fecha_fin') THEN to_timestamp(param_value)::date
        ELSE NULL
    END AS param_date,
    description
FROM params_pui;

-- Función helper para obtener parámetro (numeric)
CREATE OR REPLACE FUNCTION get_param(p_name TEXT) RETURNS NUMERIC AS $$
    SELECT param_value FROM params_pui WHERE param_name = p_name;
$$ LANGUAGE SQL STABLE;

-- Función helper para obtener parámetro boolean
CREATE OR REPLACE FUNCTION get_param_bool(p_name TEXT) RETURNS BOOLEAN AS $$
    SELECT param_value = 1 FROM params_pui WHERE param_name = p_name;
$$ LANGUAGE SQL STABLE;

-- Tabla de clasificación de independientes
-- miembro = true: asociación que pagó el estudio
-- miembro = false: otros independientes (universo de estudio)
DROP TABLE IF EXISTS independientes_asociacion CASCADE;

CREATE TABLE independientes_asociacion (
    agente_code TEXT PRIMARY KEY,
    agente_nombre TEXT NOT NULL,
    es_miembro_asociacion BOOLEAN NOT NULL, -- true = pagó el estudio, false = otro independiente
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vista para identificar rápidamente a los independientes
CREATE OR REPLACE VIEW v_agentes_independientes AS
SELECT
    agente_code,
    agente_nombre,
    es_miembro_asociacion,
    CASE WHEN es_miembro_asociacion THEN 'Miembro (pagó estudio)' ELSE 'No miembro' END AS tipo_independiente
FROM independientes_asociacion;

-- Parámetro para activar análisis solo de independientes
INSERT INTO params_pui (param_name, param_value, description) VALUES
('p_solo_independientes', 1, '1=Análisis solo independientes, 0=Todos los agentes')
ON CONFLICT (param_name) DO UPDATE SET param_value = 1, description = '1=Análisis solo independientes, 0=Todos los agentes';

-- Función para verificar si un agente es independiente
CREATE OR REPLACE FUNCTION es_independiente(p_agente_code TEXT) RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM independientes_asociacion 
        WHERE agente_code = p_agente_code
    );
$$ LANGUAGE SQL STABLE;

-- Función para verificar si un agente es miembro de la asociación
CREATE OR REPLACE FUNCTION es_miembro(p_agente_code TEXT) RETURNS BOOLEAN AS $$
    SELECT COALESCE(
        (SELECT es_miembro_asociacion FROM independientes_asociacion WHERE agente_code = p_agente_code),
        false
    );
$$ LANGUAGE SQL STABLE;

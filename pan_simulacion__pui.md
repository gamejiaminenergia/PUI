# Plan de Simulación SQL-Only: Impacto del PUI en Comercializadores

## Contexto Regulatorio
Basado en `docs/contexto_calculo_pui.md` y `docs/modelo_calculo_pui.md`:
- **Fase Transitoria**: CIOR asume rol PUI, costo basado en riesgo de cartera en áreas especiales (`CRPUI`)
- **Fase Definitiva**: Mecanismo competitivo, costo variabilizado (`CFPUI`)
- **Flujo**: CIOR calcula → publica → CNIOR facturan a usuarios → CNIOR giran a CIOR (riesgo de cobro en CNIOR)

---

## 1. Análisis de Brecha de Datos (BD Actual vs Requerida)

| Variable Regulatoria | Existe en BD | Tabla/Origen | Acción Simulación |
|---------------------|--------------|--------------|-------------------|
| `VR_i,j,m` (ventas totales reguladas) | ✅ Parcial | `fact_hourly_agente`.`DemaComeReg` + `fact_hourly_mercadocomercializacion`.`DemaCome` | Agregar por agente/mercado/mes |
| `VPUI_i,j,m-1` (ventas áreas especiales) | ❌ | No hay identificación de áreas especiales | **Simular**: % aleatorio o fijo (ej. 5-15%) sobre VR |
| `RCPUI_j,t` (prima riesgo cartera CIOR) | ❌ | No existe en BD | **Parametrizar**: input configurable (ej. 0.02-0.05 $/kWh) |
| `G, T, D1, PR1, R` (componentes base CU) | ❌ Parcial | No desglosados en BD | **Simular**: usar `PrecPromCont` + `PPPrecBolsNaci` como proxy |
| CIOR vs CNIOR por mercado | ❌ | `dim_agente` no tiene esta clasificación | **Asignar**: 1 CIOR por mercado (mayor `DemaCome`), resto CNIOR |
| `CFPUI_j,m` (costo subasta competitiva) | ❌ | No existe | **Escenario**: input configurable post-competitivo |
| Recaudo real vs facturado (CNIOR) | ❌ | No hay datos de cartera/cobro | **Simular**: factor de recaudo (ej. 85-98%) |

---

## 2. Arquitectura de la Simulación (CTEs Encadenadas)

```
WITH params AS (                           -- 0. Parámetros configurables
    SELECT ...
),
agentes_mercado AS (                       -- 1. Agentes por mercado + rol CIOR/CNIOR
    SELECT ...
),
ventas_mensuales AS (                      -- 2. VR_i,j,m agregado mensual
    SELECT ...
),
ventas_areas_especiales AS (               -- 3. VPUI simulado (% de VR)
    SELECT ...
),
costo_unitario_pui AS (                    -- 4. CRPUI_i,j,m (Paso 1)
    SELECT ...
),
costo_total_trasladar AS (                 -- 5. PUI_j,m = CRPUI * VR_m-2 (Paso 3)
    SELECT ...
),
facturacion_cniors AS (                    -- 6. CNIOR facturan PUI a usuarios (Paso 4)
    SELECT ...
),
giros_cniors AS (                          -- 7. CNIOR giran a CIOR (Paso 5) - CON RIESGO
    SELECT ...
),
remuneracion_cior AS (                     -- 8. VTPUI = CRPUICIOR + Σ giros (Paso 6)
    SELECT ...
),
impacto_comercializadores AS (             -- 9. ANÁLISIS CENTRAL: +/- por agente
    SELECT ...
)
SELECT * FROM impacto_comercializadores;
```

---

## 3. Detalle de Cada CTE

### 0. `params` — Parámetros de Simulación
```sql
params AS (
    SELECT
        0.03::numeric AS p_rcpui,              -- Prima riesgo cartera ($/kWh)
        0.10::numeric AS p_pct_areas_especiales, -- % usuarios en áreas especiales
        0.92::numeric AS p_factor_recaudo_cnior, -- Factor recaudo real CNIOR
        '2024-01-01'::date AS p_fecha_inicio,
        '2024-12-31'::date AS p_fecha_fin,
        false AS p_esquema_competitivo,        -- true = fase definitiva
        0.025::numeric AS p_cfpui              -- $/kWh si competitivo
)
```

### 1. `agentes_mercado` — Clasificación CIOR/CNIOR
```sql
agentes_mercado AS (
    SELECT
        hm.mercado_code,
        m.mercado_name,
        ha.agente_code,
        a.name AS agente_name,
        CASE
            WHEN ROW_NUMBER() OVER (PARTITION BY hm.mercado_code ORDER BY SUM(ha."DemaComeReg") DESC) = 1
            THEN 'CIOR'
            ELSE 'CNIOR'
        END AS rol_pui,
        SUM(ha."DemaComeReg") AS demanda_reg_anual
    FROM fact_hourly_agente ha
    JOIN fact_hourly_mercadocomercializacion hm ON ha.fecha_hora = hm.fecha_hora
    JOIN dim_agente a ON ha.agente_code = a.agente_code
    JOIN dim_mercado m ON hm.mercado_code = m.mercado_code
    WHERE a.activity = 'COMERCIALIZACIÓN'
      AND ha.fecha_hora BETWEEN (SELECT p_fecha_inicio FROM params) AND (SELECT p_fecha_fin FROM params)
    GROUP BY hm.mercado_code, m.mercado_name, ha.agente_code, a.name
)
```

### 2. `ventas_mensuales` — VR_i,j,m por agente/mercado/mes
```sql
ventas_mensuales AS (
    SELECT
        am.mercado_code,
        am.mercado_name,
        am.agente_code,
        am.agente_name,
        am.rol_pui,
        date_trunc('month', ha.fecha_hora)::date AS mes,
        SUM(ha."DemaComeReg") AS vr_mes  -- Ventas reguladas
    FROM fact_hourly_agente ha
    JOIN agentes_mercado am ON ha.agente_code = am.agente_code
    WHERE ha.fecha_hora BETWEEN (SELECT p_fecha_inicio FROM params) AND (SELECT p_fecha_fin FROM params)
    GROUP BY am.mercado_code, am.mercado_name, am.agente_code, am.agente_name, am.rol_pui, date_trunc('month', ha.fecha_hora)
)
```

### 3. `ventas_areas_especiales` — VPUI simulado
```sql
ventas_areas_especiales AS (
    SELECT
        vm.*,
        vm.vr_mes * (SELECT p_pct_areas_especiales FROM params) AS vpui_mes
    FROM ventas_mensuales vm
)
```

### 4. `costo_unitario_pui` — CRPUI_i,j,m (Fórmula Paso 1)
```sql
costo_unitario_pui AS (
    SELECT
        vae.*,
        -- Componentes base CU (proxy: precio contrato + bolsa ponderado)
        (SELECT AVG("PrecPromCont") FROM fact_daily_sistema
         WHERE fecha = date_trunc('month', vae.mes)::date) AS cu_base,
        -- CRPUI = (RCPUI * VPUI_m-1) / (VR_m-1 * CU_base)
        -- Usamos LAG para m-1
        LAG(vae.vpui_mes) OVER (PARTITION BY vae.agente_code ORDER BY vae.mes) AS vpui_m_1,
        LAG(vae.vr_mes) OVER (PARTITION BY vae.agente_code ORDER BY vae.mes) AS vr_m_1,
        LAG((SELECT AVG("PrecPromCont") FROM fact_daily_sistema
             WHERE fecha = date_trunc('month', vae.mes)::date))
            OVER (PARTITION BY vae.agente_code ORDER BY vae.mes) AS cu_base_m_1
    FROM ventas_areas_especiales vae
),
crpui_calculado AS (
    SELECT
        *,
        CASE
            WHEN vr_m_1 > 0 AND cu_base_m_1 > 0 AND rol_pui = 'CIOR'
            THEN ((SELECT p_rcpui FROM params) * vpui_m_1) / (vr_m_1 * cu_base_m_1)
            ELSE 0
        END AS crpui_unitario
    FROM costo_unitario_pui
)
```

### 5. `costo_total_trasladar` — PUI_j,m (Paso 3)
```sql
costo_total_trasladar AS (
    SELECT
        c.mercado_code,
        c.mes,
        -- PUI_j,m = CRPUI_i,j,m * VR_i,j,m-2 (ventas hace 2 meses)
        c.crpui_unitario * LAG(c.vr_mes, 2) OVER (PARTITION BY c.agente_code ORDER BY c.mes) AS pui_total_mes
    FROM crpui_calculado c
    WHERE c.rol_pui = 'CIOR'  -- Solo CIOR calcula CRPUI
)
```

### 6. `facturacion_cniors` — CNIOR facturan a usuarios (Paso 4)
```sql
facturacion_cniors AS (
    SELECT
        vm.mercado_code,
        vm.mes,
        vm.agente_code,
        vm.agente_name,
        vm.rol_pui,
        vm.vr_mes AS ventas_reg_mes,
        ctt.pui_total_mes AS pui_facturado  -- Cada CNIOR factura su PUI_j,m
    FROM ventas_mensuales vm
    JOIN costo_total_trasladar ctt ON vm.mercado_code = ctt.mercado_code
        AND vm.mes = ctt.mes
    WHERE vm.rol_pui = 'CNIOR'
)
```

### 7. `giros_cniors` — Giro a CIOR con riesgo de cobro (Paso 5) ⭐ **CRÍTICO**
```sql
giros_cniors AS (
    SELECT
        fc.*,
        fc.pui_facturado AS giro_obligatorio,           -- Debe girar 100% facturado
        fc.pui_facturado * (SELECT p_factor_recaudo_cnior FROM params) AS recaudo_real_estimado,
        fc.pui_facturado * (1 - (SELECT p_factor_recaudo_cnior FROM params)) AS perdida_cartera_cnior
    FROM facturacion_cniors fc
)
```

### 8. `remuneracion_cior` — VTPUI consolidado (Paso 6)
```sql
remuneracion_cior AS (
    SELECT
        am.mercado_code,
        am.mes,
        am.agente_code AS cior_code,
        am.agente_name AS cior_name,
        -- CRPUICIOR: CIOR recauda directo de sus usuarios
        am.vr_mes * ccr.crpui_unitario AS crpui_cior,
        -- CRPUICNIOR: Suma giros recibidos de CNIORs
        COALESCE(SUM(g.giro_obligatorio) FILTER (WHERE g.mercado_code = am.mercado_code AND g.mes = am.mes), 0) AS crpui_cnior,
        -- VTPUI total
        (am.vr_mes * ccr.crpui_unitario) + COALESCE(SUM(g.giro_obligatorio) FILTER (WHERE g.mercado_code = am.mercado_code AND g.mes = am.mes), 0) AS vtpui_total
    FROM ventas_mensuales am
    JOIN crpui_calculado ccr ON am.agente_code = ccr.agente_code AND am.mes = ccr.mes
    LEFT JOIN giros_cniors g ON g.mercado_code = am.mercado_code AND g.mes = am.mes
    WHERE am.rol_pui = 'CIOR'
    GROUP BY am.mercado_code, am.mes, am.agente_code, am.agente_name, am.vr_mes, ccr.crpui_unitario
)
```

### 9. `impacto_comercializadores` — **ANÁLISIS CENTRAL: +/- por agente**
```sql
impacto_comercializadores AS (
    SELECT
        vm.mercado_code,
        vm.mes,
        vm.agente_code,
        vm.agente_name,
        vm.rol_pui,
        vm.vr_mes AS ventas_reg_kwh,
        -- INGRESOS por PUI (facturado a usuarios)
        CASE
            WHEN vm.rol_pui = 'CIOR' THEN vm.vr_mes * ccr.crpui_unitario
            ELSE fc.pui_facturado
        END AS ingresos_pui_facturado,
        -- EGRESOS por PUI (giro a CIOR para CNIOR)
        CASE
            WHEN vm.rol_pui = 'CNIOR' THEN g.giro_obligatorio
            ELSE 0
        END AS egreso_giro_cior,
        -- FLUJO NETO CAJA (considerando recaudo real)
        CASE
            WHEN vm.rol_pui = 'CIOR' THEN
                (vm.vr_mes * ccr.crpui_unitario) + COALESCE(SUM(g.giro_obligatorio) FILTER (WHERE g.mercado_code = vm.mercado_code AND g.mes = vm.mes), 0)
            WHEN vm.rol_pui = 'CNIOR' THEN
                g.recaudo_real_estimado - g.giro_obligatorio  -- NEGATIVO si recaudo < giro
        END AS flujo_neto_caja_pui,
        -- INDICADORES DE IMPACTO
        CASE
            WHEN vm.rol_pui = 'CNIOR' THEN
                (g.recaudo_real_estimado - g.giro_obligatorio) / NULLIF(g.giro_obligatorio, 0) * 100
        END AS pct_perdida_sobre_giro_cnior,
        CASE
            WHEN vm.rol_pui = 'CIOR' THEN
                (COALESCE(SUM(g.giro_obligatorio) FILTER (WHERE g.mercado_code = vm.mercado_code AND g.mes = vm.mes), 0)) / NULLIF(vm.vr_mes * ccr.crpui_unitario, 0) * 100
        END AS pct_apalancamiento_cior
    FROM ventas_mensuales vm
    LEFT JOIN crpui_calculado ccr ON vm.agente_code = ccr.agente_code AND vm.mes = ccr.mes
    LEFT JOIN facturacion_cniors fc ON vm.agente_code = fc.agente_code AND vm.mes = fc.mes
    LEFT JOIN giros_cniors g ON vm.agente_code = g.agente_code AND vm.mes = g.mes
    GROUP BY vm.mercado_code, vm.mes, vm.agente_code, vm.agente_name, vm.rol_pui, vm.vr_mes,
             ccr.crpui_unitario, fc.pui_facturado, g.giro_obligatorio, g.recaudo_real_estimado
)
```

---

## 4. Consultas de Análisis Derivadas (Vistas Finales)

### 4.1 Resumen por Rol (CIOR vs CNIOR)
```sql
SELECT
    rol_pui,
    COUNT(DISTINCT agente_code) AS n_agentes,
    SUM(ventas_reg_kwh)/1e6 AS gwh_totales,
    SUM(ingresos_pui_facturado)/1e9 AS ingresos_pui_cop_miles_millones,
    SUM(egreso_giro_cior)/1e9 AS egresos_giro_cop_miles_millones,
    SUM(flujo_neto_caja_pui)/1e9 AS flujo_neto_caja_cop_miles_millones,
    AVG(pct_perdida_sobre_giro_cnior) AS pct_prom_perdida_cnior,
    AVG(pct_apalancamiento_cior) AS pct_prom_apalancamiento_cior
FROM impacto_comercializadores
GROUP BY rol_pui;
```

### 4.2 Top 5 CNIOR más afectados (pérdida neta)
```sql
SELECT agente_name, mercado_name, mes,
       flujo_neto_caja_pui/1e6 AS perdida_millones_cop,
       pct_perdida_sobre_giro_cnior
FROM impacto_comercializadores
WHERE rol_pui = 'CNIOR' AND flujo_neto_caja_pui < 0
ORDER BY flujo_neto_caja_pui ASC
LIMIT 5;
```

### 4.3 CIOR: Apalancamiento por giros CNIOR
```sql
SELECT agente_name AS cior, mercado_name, mes,
       vtpui_total/1e9 AS vtpui_miles_millones_cop,
       crpui_cnior/1e9 AS giros_recibidos_miles_millones_cop,
       pct_apalancamiento_cior
FROM remuneracion_cior
ORDER BY pct_apalancamiento_cior DESC;
```

### 4.4 Sensibilidad: Escenario Competitivo vs Transitorio
```sql
-- Ejecutar simulación 2 veces: p_esquema_competitivo = false / true
-- Comparar flujo_neto_caja_pui entre ambos
```

### 4.5 Sensibilidad: Factor Recaudo CNIOR (85% vs 98%)
```sql
-- Variar p_factor_recaudo_cnior en params
-- Graficar flujo_neto_caja_pui CNIOR vs factor_recaudo
```

---

## 5. Variables de Sensibilidad Clave (Para Dashboard/Análisis)

| Parámetro | Rango Realista | Impacto CNIOR | Impacto CIOR |
|-----------|----------------|---------------|--------------|
| `p_rcpui` | 0.015 - 0.050 $/kWh | Lineal ↑ costo → ↑ pérdida | Lineal ↑ ingresos |
| `p_pct_areas_especiales` | 3% - 20% | Lineal ↑ VPUI → ↑ CRPUI | Lineal ↑ base remuneración |
| `p_factor_recaudo_cnior` | 0.80 - 0.98 | **CRÍTICO**: no lineal, umbral quiebre | Neutro (recibe giro obligatorio) |
| `p_cfpui` (competitivo) | 0.015 - 0.040 $/kWh | Reemplaza CRPUI, puede ↓ o ↑ | Define ingreso fijo por kWh |

---

## 6. Limitaciones y Supuestos Explícitos

1. **CIOR = agente con mayor demanda regulada por mercado** (proxy regulatorio)
2. **Áreas especiales = % fijo de ventas reguladas** (sin georreferenciación real)
3. **Componentes CU (G,T,D1,PR1,R) = Precio Promedio Contratos** (proxy de `fact_daily_sistema`)
4. **Requerimiento de giro = 100% facturado** (regla estricta regulación)
5. **Recaudo CNIOR = factor fijo** (no modela curva de morosidad temporal)
6. **No hay diferimiento temporal** (facturación m, giro m+1 simplificado a mismo mes)
7. **Fase competitiva: CFPUI uniforme por mercado** (sin discriminación por agente)

---

## 7. Próximos Pasos de Implementación

1. **Crear función SQL**: `fn_simulacion_pui(fecha_ini, fecha_fin, rcpui, pct_ae, factor_recaudo, esquema_comp, cfpui)` RETURNS TABLE
2. **Validar con datos 2024**: Ejecutar para 2024-01 a 2024-12
3. **Calibrar parámetros**: Ajustar `p_rcpui` y `p_pct_areas_especiales` contra resoluciones CREG reales
4. **Extender a fase definitiva**: Agregar lógica `CFPUI` cuando exista data de subastas
5. **Integrar con `fn_estudio_c04_exposicion_bolsa`**: Cruce PUI vs exposición bolsa/comercializador

---

## 8. Archivos SQL Generados

| Archivo | Descripción |
|---------|-------------|
| `sql/01_params_pui.sql` | Tabla/función de parámetros configurables |
| `sql/02_simulacion_pui_core.sql` | CTE principal (9 pasos) |
| `sql/03_vistas_analisis_pui.sql` | Vistas 4.1 a 4.5 |
| `sql/04_fn_simulacion_pui.sql` | Función invocable parametrizada |
| `sql/05_calibracion_parametros.sql` | Queries para estimar params desde datos reales |

---

**Nota**: Esta simulación es **100% SQL**, ejecutable en la BD `elecdb` sin dependencias externas. El foco analítico está en el **flujo de caja neto por comercializador** (CNIOR asume riesgo de cobro, CIOR recibe apalancamiento), revelando ganadores/perdedores del esquema PUI.

---

## 9. Entregables Finales y Estructura de Ejecución

### 9.1 Estructura de Directorios
```
PUI/
├── docs/
│   ├── contexto_calculo_pui.md
│   └── modelo_calculo_pui.md
├── sql/
│   ├── 01_params_pui.sql           -- Tabla params_pui + vista v_params_pui
│   ├── 02_simulacion_pui_core.sql  -- CTE principal (9 pasos) → vista v_simulacion_pui
│   ├── 03_vistas_analisis_pui.sql  -- 5 vistas analíticas (v_resumen_rol, v_top_cnior, v_apalancamiento_cior, v_sensibilidad_competitivo, v_sensibilidad_recaudo)
│   ├── 04_fn_simulacion_pui.sql    -- Función fn_simulacion_pui(...) RETURNS TABLE
│   └── 05_calibracion_parametros.sql -- Queries calibración desde datos reales
├── scripts/
│   ├── 01_setup.sh                 -- Crea tablas/vistas/función en BD
│   ├── 02_run_simulation.sh        -- Ejecuta simulación base + escenarios
│   ├── 03_export_csv.sh            -- Exporta vistas a CSV en data/
│   └── 04_generate_summary.sh      -- Genera resumen_ejecutivo.md desde CSV
├── data/
│   ├── simulacion_pui_base.csv           -- Resultado v_simulacion_pui (escenario base)
│   ├── simulacion_pui_competitivo.csv    -- Resultado escenario competitivo
│   ├── simulacion_pui_sensibilidad_recaudo.csv -- Resultado barrido factor_recaudo
│   ├── resumen_por_rol.csv
│   ├── top_cnior_afectados.csv
│   ├── apalancamiento_cior.csv
│   └── resumen_ejecutivo.md              -- **Entregable principal para dirección**
└── pan_simulacion__pui.md                -- Este plan
```

### 9.2 Resumen Ejecutivo (`data/resumen_ejecutivo.md`)

**Contenido obligatorio:**
- **Hallazgo principal**: CNIOR pierden X% del giro PUI por riesgo de cobro (factor recaudo Y%)
- **CIOR ganan**: Apalancamiento Z% sobre su recaudo propio vía giros CNIOR
- **Mercados más afectados**: Top 3 por volumen de pérdidas CNIOR
- **Sensibilidad clave**: Gráfico/ tabla flujo neto CNIOR vs factor_recaudo (80-98%)
- **Escenario competitivo**: Δ flujo neto vs transitorio (CFPUI vs CRPUI)
- **Recomendación**: Umbral mínimo recaudo CNIOR para viabilidad / ajuste RCPUI

**Formato**: Markdown con tablas, KPIs destacados, listo para PDF/presentación.

### 9.3 Scripts Bash (Orquestaación)

#### `scripts/01_setup.sh`
```bash
#!/usr/bin/env bash
# Crea objetos en BD: tabla params_pui, vistas, función
psql -h localhost -U postgres -d postgres -f sql/01_params_pui.sql
psql -h localhost -U postgres -d postgres -f sql/02_simulacion_pui_core.sql
psql -h localhost -U postgres -d postgres -f sql/03_vistas_analisis_pui.sql
psql -h localhost -U postgres -d postgres -f sql/04_fn_simulacion_pui.sql
psql -h localhost -U postgres -d postgres -f sql/05_calibracion_parametros.sql
```

#### `scripts/02_run_simulation.sh`
```bash
#!/usr/bin/env bash
# Escenario base (transitorio, params default)
psql -h localhost -U postgres -d postgres -c "
  SELECT * FROM fn_simulacion_pui('2024-01-01','2024-12-31',0.03,0.10,0.92,false,0.025);
" > data/simulacion_pui_base.csv

# Escenario competitivo
psql -h localhost -U postgres -d postgres -c "
  SELECT * FROM fn_simulacion_pui('2024-01-01','2024-12-31',0.03,0.10,0.92,true,0.025);
" > data/simulacion_pui_competitivo.csv

# Barrido sensibilidad recaudo (80%, 85%, 90%, 92%, 95%, 98%)
for r in 0.80 0.85 0.90 0.92 0.95 0.98; do
  psql -h localhost -U postgres -d postgres -c "
    SELECT * FROM fn_simulacion_pui('2024-01-01','2024-12-31',0.03,0.10,$r,false,0.025);
  " >> data/simulacion_pui_sensibilidad_recaudo.csv
done

# Vistas analíticas
psql -h localhost -U postgres -d postgres -c "SELECT * FROM v_resumen_por_rol;" > data/resumen_por_rol.csv
psql -h localhost -U postgres -d postgres -c "SELECT * FROM v_top_cnior_afectados;" > data/top_cnior_afectados.csv
psql -h localhost -U postgres -d postgres -c "SELECT * FROM v_apalancamiento_cior;" > data/apalancamiento_cior.csv
```

#### `scripts/03_export_csv.sh`
```bash
#!/usr/bin/env bash
# Wrapper: ejecuta 02_run_simulation.sh y valida CSVs generados
./02_run_simulation.sh
# Validación rápida: filas > 0, columnas esperadas
for f in data/*.csv; do
  echo "=== $f ===" && head -1 "$f" && wc -l "$f"
done
```

#### `scripts/04_generate_summary.sh`
```bash
#!/usr/bin/env bash
# Genera resumen_ejecutivo.md desde CSVs usando awk/sed o python
python3 << 'PYEOF'
import pandas as pd
from pathlib import Path

base = pd.read_csv('data/simulacion_pui_base.csv')
comp = pd.read_csv('data/simulacion_pui_competitivo.csv')
sens = pd.read_csv('data/simulacion_pui_sensibilidad_recaudo.csv')
rol = pd.read_csv('data/resumen_por_rol.csv')
top = pd.read_csv('data/top_cnior_afectados.csv')
apal = pd.read_csv('data/apalancamiento_cior.csv')

with open('data/resumen_ejecutivo.md', 'w') as f:
    f.write('# Resumen Ejecutivo: Impacto PUI en Comercializadores\n\n')
    f.write(f'**Periodo**: 2024-01 a 2024-12  \n')
    f.write(f'**Escenario base**: Transitorio (CRPUI)  \n\n')
    
    # KPIs globales
    cnior = base[base['rol_pui']=='CNIOR']
    cior = base[base['rol_pui']=='CIOR']
    f.write(f'## Hallazgos Clave\n\n')
    f.write(f'- **CNIOR pierden**: ${cnior["flujo_neto_caja_pui"].sum()/1e9:,.1f} miles millones COP (recaudo {cnior["pct_perdida_sobre_giro_cnior"].mean():.1f}% bajo giro)\n')
    f.write(f'- **CIOR ganan apalancamiento**: {cior["pct_apalancamiento_cior"].mean():.1f}% sobre recaudo propio\n')
    f.write(f'- **Mercados críticos**: {top.head(3)["mercado_name"].tolist()}\n\n')
    
    # Sensibilidad
    f.write(f'## Sensibilidad Factor Recaudo CNIOR\n\n')
    for r in [0.80, 0.85, 0.90, 0.92, 0.95, 0.98]:
        subset = sens[sens['p_factor_recaudo_cnior']==r]
        if len(subset) > 0:
            perdida = subset[subset['rol_pui']=='CNIOR']['flujo_neto_caja_pui'].sum()/1e9
            f.write(f'- Recaudo {r*100:.0f}%: Pérdida CNIOR = ${perdida:,.1f} MM COP\n')
    
    f.write(f'\n## Escenario Competitivo vs Transitorio\n\n')
    diff_cnior = comp[comp['rol_pui']=='CNIOR']['flujo_neto_caja_pui'].sum() - cnior['flujo_neto_caja_pui'].sum()
    f.write(f'- Δ Flujo neto CNIOR: ${diff_cnior/1e9:,.1f} MM COP\n')
    
    f.write(f'\n## Recomendación\n\n')
    f.write(f'- Establecer floor recaudo CNIOR ≥ 90% para evitar pérdidas sistémicas\n')
    f.write(f'- Calibrar RCPUI con datos reales SSPD/CREG\n')
    f.write(f'- Evaluar mecanismo competitivo (CFPUI) para reducir asimetría\n')

print("resumen_ejecutivo.md generado")
PYEOF
```

### 9.4 Flujo de Ejecución Completo
```bash
cd /home/alde/Escritorio/PUI
chmod +x scripts/*.sh
./scripts/01_setup.sh      # 1. Instala objetos en BD
./scripts/03_export_csv.sh # 2. Ejecuta simulación + exporta CSVs
./scripts/04_generate_summary.sh # 3. Genera resumen ejecutivo
```

### 9.5 Verificación de Entregables
| Archivo | Verificación |
|---------|--------------|
| `data/simulacion_pui_base.csv` | > 0 filas, columnas: mercado, mes, agente, rol, flujo_neto_caja_pui, pct_perdida... |
| `data/resumen_ejecutivo.md` | Existe, contiene KPIs, tablas, recomendaciones |
| `sql/*.sql` | 5 archivos, sintaxis válida PostgreSQL |
| `scripts/*.sh` | Ejecutables, sin errores en dry-run |
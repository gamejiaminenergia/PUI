# PUI — Simulación del Prestador de Última Instancia

Simulación 100% SQL del impacto económico del **Prestador de Última Instancia (PUI)** en los comercializadores del Mercado de Energía Mayorista (MEM) de Colombia.

Basado en la regulación CREG — Fase Transitoria (CRPUI) y Definitiva (CFPUI).

---

## Contexto Regulatorio

| Fase | Mecanismo | Costo |
|------|-----------|-------|
| **Transitoria** | CIOR calcula CRPUI basado en riesgo de cartera en áreas especiales | `CRPUI = (RCPUI × VPUI) / (VR × CU)` |
| **Definitiva** | Mecanismo competitivo (subasta) | `CFPUI` = costo variabilizado |

**Flujo:** CIOR calcula → publica → CNIOR facturan a usuarios → CNIOR giran a CIOR (riesgo de cobro en CNIOR).

---

## Estructura del Proyecto

```
PUI/
├── docs/
│   ├── contexto_calculo_pui.md      # Flujo de cálculo paso a paso (CREG)
│   └── modelo_calculo_pui.md        # Modelo matemático y tarifario
├── sql/
│   ├── 01_params_pui.sql            # Tabla params_pui + vista v_params_pui
│   ├── 02_simulacion_pui_core.sql   # Vista v_simulacion_pui (CTE principal)
│   ├── 03_vistas_analisis_pui.sql   # 5 vistas analíticas derivadas
│   ├── 04_fn_simulacion_pui.sql     # Función fn_simulacion_pui() parametrizada
│   └── 05_calibracion_parametros.sql # Queries para calibrar params desde datos reales
├── scripts/
│   └── 01_setup.sh                  # Instala todos los objetos SQL en BD
├── data/
│   ├── simulacion_pui_base.csv      # Resultado completo (~40K filas)
│   ├── resumen_por_rol.csv          # Resumen CIOR vs CNIOR
│   ├── top_cnior_afectados.csv      # Top 20 CNIOR con mayor pérdida
│   ├── apalancamiento_cior.csv      # Detalle apalancamiento CIOR
│   └── resumen_ejecutivo.md         # Documento ejecutivo para dirección
├── pan_simulacion__pui.md           # Plan detallado de implementación
└── README.md                        # Este archivo
```

---

## Requisitos

- **PostgreSQL** ≥ 14
- **Base de datos XM/SIN** cargada (tablas `fact_hourly_agente`, `fact_hourly_mercadocomercializacion`, `fact_daily_sistema`, `dim_agente`, `dim_mercado`)
- **psql** (cliente PostgreSQL)

---

## Instalación

```bash
# 1. Clonar el repositorio
cd ~/Escritorio
git clone <repo-url> PUI
cd PUI

# 2. Ejecutar setup (crea tablas, vistas, función)
chmod +x scripts/01_setup.sh
./scripts/01_setup.sh
```

El setup crea:
- Tabla `params_pui` (parámetros configurables)
- Vista `v_simulacion_pui` (simulación principal)
- 5 vistas analíticas (`v_resumen_por_rol`, `v_top_cnior_afectados`, etc.)
- Función `fn_simulacion_pui()` parametrizada

---

## Uso

### Consulta rápida — Resultado base

```sql
-- Resumen por rol (CIOR vs CNIOR)
SELECT * FROM v_resumen_por_rol;

-- Top CNIOR más afectados
SELECT * FROM v_top_cnior_afectados;

-- Apalancamiento CIOR
SELECT * FROM v_apalancamiento_cior LIMIT 10;
```

### Escenario personalizado — Función parametrizada

```sql
-- Escenario base: transitorio, params default
SELECT * FROM fn_simulacion_pui('2024-01-01', '2026-12-31');

-- Escenario competitivo
SELECT * FROM fn_simulacion_pui('2024-01-01', '2026-12-31',
    0.03,    -- RCPUI ($/kWh)
    0.10,    -- % áreas especiales
    0.92,    -- factor recaudo CNIOR
    true,    -- esquema competitivo
    0.025    -- CFPUI ($/kWh)
);

-- Barrido sensibilidad factor recaudo
SELECT * FROM fn_simulacion_pui('2024-01-01', '2026-12-31',
    0.03, 0.10, 0.85, false, 0.025  -- recaudo 85%
);
```

### Cambiar parámetros permanentemente

```sql
-- Modificar RCPUI
UPDATE params_pui SET param_value = 0.05 WHERE param_name = 'p_rcpui';

-- Cambiar rango de fechas
UPDATE params_pui SET param_value = EXTRACT(EPOCH FROM '2025-01-01'::date)
WHERE param_name = 'p_fecha_inicio';

-- Verificar cambios
SELECT * FROM v_params_pui;
```

---

## Parámetros de Simulación

| Parámetro | Default | Descripción | Rango Realista |
|-----------|---------|-------------|----------------|
| `p_rcpui` | 0.03 $/kWh | Prima riesgo cartera CIOR | 0.015 – 0.050 |
| `p_pct_areas_especiales` | 10% | % usuarios en áreas especiales | 3% – 20% |
| `p_factor_recaudo_cnior` | 92% | Factor recaudo real CNIOR | 80% – 98% |
| `p_fecha_inicio` | 2024-01-01 | Fecha inicio simulación | Auto-detectado |
| `p_fecha_fin` | Auto-detectado | Fecha fin simulación | Auto-detectado |
| `p_esquema_competitivo` | false | false=CRPUI, true=CFPUI | — |
| `p_cfpui` | 0.025 $/kWh | Costo subasta competitiva | 0.015 – 0.040 |

---

## Vistas Analíticas

| Vista | Descripción |
|-------|-------------|
| `v_simulacion_pui` | Simulación completa: agente/mes/mercado con flujo neto |
| `v_resumen_por_rol` | Resumen agregado CIOR vs CNIOR |
| `v_top_cnior_afectados` | Top 20 CNIOR con mayor pérdida neta |
| `v_apalancamiento_cior` | Apalancamiento CIOR por mercado |
| `v_sensibilidad_competitivo` | Comparación CRPUI vs CFPUI |
| `v_sensibilidad_recaudo` | Barrido factor de recaudo |
| `v_resumen_independientes` | Resumen de todos los comerc. independientes |
| `v_comparacion_grupos` | Comparación asociados vs no asociados |
| `v_top_afectados` | Top 30 independientes con mayor pérdida |
| `v_riesgo_flujo_caja` | Independientes con mayor riesgo financiero |

---

## Limitaciones Conocidas

1. **Sin mapeo agente→mercado:** `fact_hourly_agente` no tiene dimensión de mercado. Se distribuye el PUI proporcionalmente.
2. **Un solo CIOR global:** Se asigna ENEL COLOMBIA (mayor demanda regulada). En la realidad, cada mercado tiene su CIOR.
3. **Factor de recaudo uniforme:** Se aplica 92% a todos los CNIOR. Varía por agente en la práctica.
4. **DemaComeReg con ~20% cobertura:** Solo ~20% de filas tienen datos de demanda regulada.

---

## Datos

La simulación depende de la **base de datos XM/SIN** con esquema star:

| Tabla | Uso en PUI |
|-------|------------|
| `fact_hourly_agente` | Demanda regulada por agente (`DemaComeReg`) |
| `fact_hourly_mercadocomercializacion` | Demanda total por mercado (`DemaCome`) |
| `fact_daily_sistema` | Precio promedio contratos (`PrecPromCont`) |
| `dim_agente` | Clasificación de agentes (COMERCIALIZACIÓN) |
| `dim_mercado` | Catálogo de mercados de comercialización |

---

## Archivos de Resultados (`data/`)

| Archivo | Formato | Contenido |
|---------|---------|-----------|
| `simulacion_pui_base.csv` | CSV | Simulación completa (~40K filas) |
| `resumen_por_rol.csv` | CSV | Resumen CIOR vs CNIOR |
| `top_cnior_afectados.csv` | CSV | Top 20 CNIOR con mayor pérdida |
| `apalancamiento_cior.csv` | CSV | Detalle apalancamiento CIOR |
| `resumen_ejecutivo.md` | Markdown | Documento ejecutivo para dirección |

---

## Análisis para Comercializadores Independientes

Este proyecto incluye un análisis específico para los **comercializadores independientes** (CNIOR), que son los más afectados por el esquema transitorio del PUI.

### Clasificación de Independientes

- **Asociados** (19 agentes): Comercializadores independientes asociados a la empresa contratante
- **No Asociados** (53 agentes): Otros independientes sin respaldo financiero

### Métricas Clave para Independientes

| Métrica | Descripción |
|---------|-------------|
| `sobrecosto_pui` | Diferencia entre lo que pagan y lo que recaudan |
| `pct_perdida_incobrabilidad` | Porcentaje de pérdida por no cobrar a usuarios |
| `riesgo_flujo_caja` | Porcentaje de ingresos comprometidos con giros |
| `tipo_riesgo` | Clasificación de riesgo (asociado/no asociado) |

### Consultas para Independientes

```sql
-- Resumen de todos los independientes
SELECT * FROM v_resumen_independientes;

-- Comparación entre asociados y no asociados
SELECT * FROM v_comparacion_grupos;

-- Top independientes más afectados
SELECT * FROM v_top_afectados LIMIT 10;

-- Independientes con mayor riesgo financiero
SELECT * FROM v_riesgo_flujo_caja;
```

### Generar Reporte Ejecutivo

```bash
# Ejecutar reporte completo
psql "postgresql://postgres:postgres@localhost:5432/postgres" -f scripts/reporte_independientes.sql
```

### Apoyo al Análisis Regulatorio

El análisis de independientes apoya los comentarios del `docs/comentario.md` sobre:

1. **Asimetría de riesgos**: Los independientes asumen el 100% del riesgo de impago
2. **Falta de músculo financiero**: No tienen subsidio cruzado de otras líneas de negocio
3. **Concentración del mercado**: El esquema transitorio desincentiva la participación de independientes

---

## Licencia

Proyecto interno — Base de datos XM/SIN Colombia.

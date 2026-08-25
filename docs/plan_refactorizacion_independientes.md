# Plan Simplificado: Análisis PUI para Comercializadores Independientes

## Objetivo
Mostrar de manera **simple y clara** los sobrecostos, riesgos y asimetrías del PUI para **todos los comercializadores independientes**, apoyando los comentarios del `comentario.md`.

## Contexto Clave
- **Todos** los agentes en `agente.json` son **comercializadores independientes** (CNIOR)
- Los `miembro: true` (19 agentes) están **asociados a la empresa contratante** (respaldo financiero)
- Los `miembro: false` (53 agentes) son **otros independientes** sin asociación (mayor riesgo)
- El esquema transitorio del PUI genera **asimetrías** que desfavorecen a los independientes

## Plan Simplificado (4 Pasos)

### Paso 1: Incorporar Clasificación de Independientes
**Qué hacer:** Agregar la información de `agente.json` al modelo SQL

1. **Modificar `01_params_pui.sql`:**
   - Agregar tabla `independientes_asociacion` con los códigos de agente y su estatus de membresía
   - Crear vista `v_agentes_independientes` para identificar rápidamente a los independientes
   - Parámetro opcional `p_solo_independientes` (default: true) para activar el análisis focalizado

2. **Script de carga:**
   - SQL para insertar los 72 agentes desde `agente.json`
   - Mapeo: código → nombre → es_asociado (true/false)

### Paso 2: Métricas Simples de Impacto
**Qué hacer:** Crear indicadores claros que muestren el problema

3. **Agregar en `02_simulacion_pui_core.sql`:**
   - `sobrecosto_pui`: Diferencia entre lo que pagan y lo que recaudan real
   - `perdida_por_incobrabilidad`: Pérdida estimada por no cobrar a usuarios
   - `riesgo_flujo_caja`: Porcentaje de ingresos comprometidos con giros obligatorios
   - `comparacion_asociado_no_asociado`: Diferencia entre independientes con y sin respaldo

4. **Crear vista `v_resumen_independientes`:**
   - Totales agregados para todos los independientes
   - Promedio de pérdida por agente
   - Ranking de los más afectados

### Paso 3: Análisis Comparativo Simple
**Qué hacer:** Mostrar la diferencia entre asociados y no asociados

5. **Crear vista `v_comparacion_grupos`:**
   - Independientes asociados (respaldados por empresa contratante)
   - Independientes no asociados (sin respaldo)
   - Métricas lado a lado: pérdida, riesgo, viabilidad

6. **Crear vista `v_top_afectados`:**
   - Top 10 independientes con mayor pérdida absoluta
   - Top 10 con mayor pérdida relativa (% de sus ingresos)
   - Top 10 con mayor riesgo de flujo de caja

### Paso 4: Reporte Ejecutivo Simple
**Qué hacer:** Generar un resumen claro para el cliente

7. **Crear script `reporte_independientes.sql`:**
   - Resumen ejecutivo: impacto total del PUI en independientes
   - Tabla comparativa: asociados vs. no asociados
   - Gráficos conceptuales (se pueden crear con herramientas externas)
   - Conclusiones que apoyen los comentarios del `comentario.md`

8. **Actualizar documentación:**
   - Modificar `README.md` con sección "Análisis para Independientes"
   - Crear `docs/resumen_ejecutivo_independientes.md` con hallazgos clave

## Ejemplo de Salida Esperada

```markdown
## Impacto del PUI en Comercializadores Independientes

### Resumen Ejecutivo
- **Total de independientes analizados:** 72 agentes
- **Pérdida estimada total:** $X,XXX millones de COP
- **Sobrecosto promedio:** $XX,XXX por kWh
- **Agentes en riesgo crítico:** XX (XX%)

### Comparación Asociados vs. No Asociados
| Métrica | Asociados (19) | No Asociados (53) |
|---------|----------------|-------------------|
| Pérdida promedio | $XXX millones | $X,XXX millones |
| Riesgo de flujo | Bajo | Alto |
| Capacidad de absorción | Alta | Baja |

### Conclusión
El esquema transitorio del PUI genera una carga desproporcionada para los independientes no asociados, quienes no tienen respaldo financiero para cubrir las pérdidas por incobrabilidad.
```

## Orden de Ejecución
1. **Paso 1** (datos) -基础 - 1 día
2. **Paso 2** (métricas) - core - 2 días  
3. **Paso 3** (comparación) - análisis - 1 día
4. **Paso 4** (reporte) - presentación - 1 día

## Validación
- Verificar que los números son coherentes con los comentarios del `comentario.md`
- Revisar que las métricas son simples y fáciles de entender
- Confirmar que el análisis apoya los argumentos del cliente

## Preguntas para el Usuario
1. ¿Qué métricas específicas son más importantes para tu cliente?
2. ¿Necesitas comparación con datos históricos o solo proyecciones?
3. ¿Qué formato de reporte prefiere tu cliente (tablas, gráficos, texto)?
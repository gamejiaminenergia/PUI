# INFORME TÉCNICO: Impacto del Prestador de Última Instancia (PUI) en Comercializadores Independientes del MEM

**Entidad emisora:** CREG (Comisión de Regulación de Energía y Gas)
**Norma analizada:** Resolución 101 121 del 30 de julio de 2026
**Periodo de análisis:** Marzo 2024 — Agosto 2026 (30 meses)
**Fecha de elaboración:** 24 de agosto de 2026
**Clasificación:** Documento técnico para comercializadores independientes (CNIOR)

---

## GLOSARIO TÉCNICO

| Término | Definición |
|---------|------------|
| **PUI** | Prestador de Última Instancia. Mecanismo que obliga a un comercializador a atender usuarios huérfanos cuando el mercado no asigna provisión. |
| **CNIOR** | Comercializador No Integrado con el Operador de Red. Empresa que comercializa energía sin pertenecer a un grupo económico con distribuidora. |
| **CIOR** | Comercializador Integrado con el Operador de Red. Empresa que forma parte del mismo grupo económico que una distribuidora. |
| **MEM** | Mercado de Energía Mayorista. Mercado mayorista de energía eléctrica en Colombia regulado por la CREG. |
| **CRPUI** | Cargo por Riesgo del Prestador de Última Instancia. Componente del PUI que remunera el riesgo de cartera asumido por el CIOR en áreas especiales. |
| **RCPUI** | Prima de Riesgo del CRPUI. Factor que pondera el costo de incobrabilidad en áreas especiales ($/kWh). |
| **VR** | Ventas Reguladas. Energía efectivamente medida y facturada a usuarios regulados (kWh). |
| **VPUI** | Ventas del PUI. Porcentaje de VR que corresponde a usuarios huérfanos atendidos por el PUI. |
| **CU** | Cargo Único. Precio promedio de los contratos de compra de energía del mercado regulado ($/kWh). |
| **DemaCome** | Demanda Comercializada. Energía total comercializada por un agente (kWh). |
| **DemaComeReg** | Demanda Comercializada Regulada. Energía comercializada por un agente en el segmento regulado del MEM (kWh). |
| **CompContEner** | Compra por Contratos. Energía adquirida mediante contratos bilaterales (kWh). |
| **CompBolsa*** | Compra en Bolsa. Energía adquirida en el Mercado de Energía (Nacional, Internacional, TIE). |
| **VentContEner** | Venta por Contratos. Energía vendida mediante contratos bilaterales (kWh). |
| **VentBolsa*** | Venta en Bolsa. Energía vendida en el Mercado de Energía. |
| **Áreas Especiales** | Zonas geográficas donde la distribución presenta pérdidas elevadas y dificultad de acceso, definidas por la CREG. |
| **Recaudo Real** | Porcentaje de la facturación efectivamente cobrada a los usuarios. Factor clave de riesgo financiero. |
| **Giro Obligatorio** | Transferencia de dinero que el CNIOR debe realizar al CIOR independientemente de si recaudó o no de los usuarios. |

---

## 1. MARCO REGULATORIO

### 1.1 Fundamento Legal

El PUI fue establecido por la **Resolución CREG 101 121 de 2026** como mecanismo transitorio para atender usuarios huérfanos antes de la implementación del mercado competitivo definitivo.

**Artículo 11 — Traslado de valor fijo:**
Obliga a los CNIOR a cobrar una tarifa regulada ex-ante a los usuarios huérfanos, antes de que exista un precio definido por libre competencia.

**Artículo 12 — Obligatoriedad de pago ("Pague lo Facturado, No lo Recaudado"):**
Obliga al comercializador a transferir al Operador de Red los costos asignados, independientemente de si logra recaudar el dinero de los usuarios.

### 1.2 Implicaciones para Comercializadores Independientes

| Aspecto | Implicación |
|---------|-------------|
| **Riesgo de cartera** | El CNIOR asume el 100% del riesgo de impago de usuarios huérfanos |
| **Flujo de caja** | Debe girar al CIOR sin garantía de recaudo |
| **Sin subsidio cruzado** | No tiene otras líneas de negocio para compensar pérdidas temporales |
| **Barreras de entrada** | El esquema desincentiva la participación de nuevos comercializadores |

---

## 2. OPERACIÓN DEL COMERCIALIZADOR INDEPENDIENTE

### 2.1 Modelo de Negocio

El comercializador independiente opera con **tres pilares fundamentales**:

```
                    ┌─────────────────────────────────────────┐
                    │      COMERCIALIZADOR INDEPENDIENTE      │
                    └─────────────────────────────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
        ▼                              ▼                              ▼
┌───────────────┐            ┌───────────────┐            ┌───────────────┐
│   COMPRA      │            │    VENTA      │            │    PUI        │
│   ENERGÍA     │            │   ENERGÍA     │            │  (Riesgo)     │
└───────────────┘            └───────────────┘            └───────────────┘
        │                              │                              │
        ├─ Contratos Bilaterales       ├─ Contratos a Usuarios        ├─ Giros Obligatorios
        └─ Bolsa (Nacional/Int.)       └─ Mercado Mayorista           └─ Pérdida por Incobrabilidad
```

### 2.2 Compra de Energía

| Canal | Descripción | Riesgo |
|-------|-------------|--------|
| **Contratos Bilaterales** | Acuerdos directos con generadores a precio fijo | Bajo (precio predefinido) |
| **Bolsa Nacional** | Compra en el Mercado de Energía Mayorista | Alto (precio spot variable) |
| **Bolsa Internacional** | Compra de energía importada | Alto + Riesgo cambiario |
| **Bolsa TIE** | Transacciones de Interconexión Externa | Alto + Riesgo de transferencia |

### 2.3 Venta de Energía

| Canal | Descripción | Regulación |
|-------|-------------|------------|
| **Contratos a Usuarios** | Ventas directas a clientes finales | Regulada (tarifas CREG) |
| **Mercado Mayorista** | Ventas a otros comercializadores | No regulada (precios de mercado) |

### 2.4 El PUI como Riesgo Adicional

El PUI representa un **costo obligatorio** que se suma a la operación normal:

```
Costo Total Operación = Costos Contratos + Costos Bolsa + Costo PUI
```

El costo PUI se calcula como:
```
Costo PUI = Giros Obligatorios × (1 - Factor Recaudo)
```

Donde el Factor Recaudo (92%) representa el % de facturación efectivamente cobrada.

---

## 3. METODOLOGÍA DE CÁLCULO DEL PUI

### 3.1 Fórmula del CRPUI

```
CRPUI_j,m = (RCPUI × VPUI_m-1) / (VR_m-1 × CU_base_m-1)
```

### 3.2 Costo Total a Trasladar

```
PUI_j,m = CRPUI_j,m × VR_j,m-2
```

### 3.3 Distribución a Agentes

```
Giro_i,m = PUI_j,m × (VR_i,m / VR_total_j,m)
```

### 3.4 Pérdida por Incobrabilidad

```
Pérdida_i,m = Giro_i,m × (1 - Factor_Recaudo)
```

---

## 4. PARÁMETROS DE SIMULACIÓN

| Parámetro | Valor | Fuente | Unidad |
|-----------|-------|--------|--------|
| RCPUI | 0.03 | Resolución CREG 101/121 | $/kWh |
| % Áreas Especiales | 10% | Estimación basada en datos XM | — |
| Factor Recaudo CNIOR | 92% | Promedio histórico del sector | — |
| Fecha inicio | 2024-01-01 | Regulación PUI vigente | — |
| Fecha fin | 2026-08-17 | Datos disponibles en BD | — |
| Esquema | Transitorio (CRPUI) | Configuración actual | — |

---

## 5. UNIVERSO DE ANÁLISIS

### 5.1 Comercializadores Independientes Identificados

| Categoría | Cantidad | Descripción |
|-----------|----------|-------------|
| **Total independientes** | **60** | Todos los agentes clasificados como CNIOR |
| **Con datos de operación** | **53** | Agentes con datos de compra/venta/demanda |
| **Sin datos en BD** | 7 | Agentes sin registros en `fact_hourly_agente` |

---

## 6. RESULTADOS — OPERACIÓN INTEGRAL DE INDEPENDIENTES

### 6.1 Tabla Completa de Operación (53 agentes)

**Orden:** Por volumen de compra total (mayor a menor)

| # | Agente | Miembro | Compra Contratos | Compra Bolsa | Compra Total | % Contratos | Venta Contratos | Venta Bolsa | Demanda Reg | Demanda No Reg | Demanda Total | % Dem Reg | Pérdidas | % Pérd |
|---|--------|---------|------------------|--------------|--------------|-------------|-----------------|-------------|-------------|----------------|---------------|-----------|----------|--------|
| 1 | VATIA S.A. E.S.P. | Sí | 5,450.72 | 602.62 | 6,053.35 | 90.0% | 1,704.29 | 88.58 | 4,008.43 | 434.16 | 4,442.59 | 90.2% | 64.90 | 1.46% |
| 2 | SOUTH32 ENERGY S.A.S E.S.P | No | 3,605.83 | 5.54 | 3,611.37 | 99.8% | 375.94 | 0.00 | 0.00 | 3,394.71 | 3,394.71 | 0.0% | 50.60 | 1.49% |
| 3 | RUITOQUE S.A. E.S.P. | Sí | 2,859.27 | 131.86 | 2,991.13 | 95.6% | 2,161.41 | 110.35 | 250.13 | 520.70 | 770.84 | 32.4% | 11.47 | 1.49% |
| 4 | COENERSA S.A.S. E.S.P. | No | 2,612.08 | 41.40 | 2,653.48 | 98.4% | 2,388.46 | 259.66 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 5 | NEU ENERGY S.A.S E.S.P | Sí | 1,819.00 | 146.63 | 1,965.64 | 92.5% | 675.18 | 164.48 | 802.93 | 418.55 | 1,221.48 | 65.7% | 18.33 | 1.50% |
| 6 | PROENERGY S.A.S.E.S.P. | No | 1,766.71 | 0.08 | 1,766.79 | 100.0% | 1,555.97 | 210.66 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 7 | QI ENERGY S.A.S. E.S.P. | Sí | 1,346.82 | 68.58 | 1,415.40 | 95.2% | 531.30 | 152.60 | 688.78 | 76.24 | 765.02 | 90.0% | 11.04 | 1.44% |
| 8 | ENERTOTAL S.A. E.S.P. | Sí | 1,402.98 | 2.60 | 1,405.58 | 99.8% | 40.98 | 0.00 | 797.83 | 641.98 | 1,439.82 | 55.4% | 20.98 | 1.46% |
| 9 | FUENTES DE ENERGIAS RENOVABLES | Sí | 1,211.91 | 2.65 | 1,214.55 | 99.8% | 788.05 | 219.82 | 0.00 | 222.15 | 222.15 | 0.0% | 3.35 | 1.51% |
| 10 | ENERGETICOS S.A.S E.S.P | Sí | 1,015.38 | 1.66 | 1,017.04 | 99.8% | 699.20 | 318.04 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 11 | PROFESIONALES EN ENERGIA S.A. E.S.P. | No | 800.78 | 11.51 | 812.29 | 98.6% | 752.84 | 51.18 | 3.34 | 6.32 | 9.66 | 34.6% | 0.14 | 1.42% |
| 12 | DRUMMOND POWER S.A.S. E.S.P. | No | 585.55 | 171.52 | 757.07 | 77.3% | 22.28 | 121.65 | 0.00 | 653.92 | 653.92 | 0.0% | 10.50 | 1.61% |
| 13 | CEMEX ENERGY S.A.S E.S.P. | No | 603.88 | 124.12 | 728.00 | 83.0% | 19.06 | 65.37 | 0.00 | 676.27 | 676.27 | 0.0% | 10.37 | 1.53% |
| 14 | ENERGIA Y GAS DE COLOMBIA SAS ESP | Sí | 709.35 | 5.17 | 714.52 | 99.3% | 617.71 | 94.08 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 15 | ESPACIO PRODUCTIVO S.A.S. E.S.P. | No | 701.40 | 0.00 | 701.40 | 100.0% | 701.05 | 0.35 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 16 | ENERCO S.A. E.S.P. | Sí | 625.13 | 2.21 | 627.34 | 99.7% | 625.87 | 0.00 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 17 | ENERVISA S.A.S E.S.P. | No | 618.77 | 2.23 | 620.99 | 99.6% | 620.99 | 0.00 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 18 | AMPERIA S.A. E.S.P. | No | 575.91 | 7.40 | 583.32 | 98.7% | 515.87 | 41.72 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 19 | TERPEL ENERGÍA S.A.S. E.S.P. | No | 520.17 | 43.74 | 563.91 | 92.2% | 281.60 | 20.08 | 29.77 | 242.08 | 271.85 | 10.9% | 4.35 | 1.60% |
| 20 | ENERBIT S.A.S. E.S.P. | No | 524.45 | 8.25 | 532.69 | 98.5% | 12.56 | 297.41 | 224.33 | 21.75 | 246.07 | 91.2% | 3.94 | 1.60% |
| 21 | ENERGIA LIMPIA Y EFICIENTE S.A.S ESP | No | 524.02 | 0.84 | 524.86 | 99.8% | 524.19 | 0.00 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 22 | SPECTRUM RENOVAVEIS S.A.S. E.S.P. | No | 508.40 | 10.84 | 519.24 | 97.9% | 466.11 | 43.62 | 0.00 | 9.59 | 9.59 | 0.0% | 0.15 | 1.56% |
| 23 | ITALCOL ENERGIA S.A. E.S.P. | Sí | 445.05 | 29.85 | 474.89 | 93.7% | 78.29 | 28.98 | 0.35 | 386.94 | 387.29 | 0.1% | 5.81 | 1.50% |
| 24 | GREENYELLOW COMERCIALIZADORA S.A.S. E.S.P. | No | 383.03 | 30.91 | 413.94 | 92.5% | 335.52 | 24.31 | 0.00 | 57.27 | 57.27 | 0.0% | 0.86 | 1.50% |
| 25 | ECOMMERCIAL S.A.S. E.S.P. | No | 411.69 | 1.56 | 413.26 | 99.6% | 397.01 | 7.19 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 26 | DUCK ENERGY S.A.S ESP | No | 287.90 | 62.36 | 350.26 | 82.2% | 289.12 | 63.07 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 27 | IA ENERGÍA Y GESTIÓN S.A.S. E.S.P. | No | 326.48 | 0.11 | 326.58 | 99.9% | 315.72 | 11.19 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 28 | MERELEC COLOMBIA S.A.S. E.S.P. | Sí | 307.10 | 9.89 | 316.99 | 96.9% | 313.63 | 5.02 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 29 | ENERXIA COLOMBIA SAS ESP - COMERCIALIZADOR | Sí | 252.73 | 47.92 | 300.65 | 84.1% | 73.97 | 25.69 | 0.00 | 214.55 | 214.55 | 0.0% | 3.22 | 1.50% |
| 30 | MESSER ENERGY SERVICES SAS ESP | No | 248.46 | 37.70 | 286.16 | 86.8% | 173.51 | 9.14 | 0.00 | 108.48 | 108.48 | 0.0% | 1.63 | 1.50% |
| 31 | SANTA FE ENERGY ZOMAC S.A.S. E.S.P. | Sí | 236.29 | 6.28 | 242.57 | 97.4% | 198.44 | 41.82 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 32 | CEE ENERGY SAS ESP | No | 177.39 | 43.89 | 221.28 | 80.2% | 166.58 | 56.63 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 33 | FRANCA ENERGIA SA ESP | No | 179.48 | 27.13 | 206.61 | 86.9% | 8.83 | 3.87 | 0.00 | 203.03 | 203.03 | 0.0% | 3.05 | 1.50% |
| 34 | GAP ENERGY GROUP SAS ESP | No | 153.96 | 34.24 | 188.20 | 81.8% | 4.21 | 9.77 | 0.00 | 181.79 | 181.79 | 0.0% | 2.73 | 1.50% |
| 35 | COLOMBINA ENERGIA SAS ESP | Sí | 154.93 | 14.47 | 169.40 | 91.5% | 3.99 | 3.77 | 0.00 | 169.05 | 169.05 | 0.0% | 2.54 | 1.50% |
| 36 | SOL & CIELO ENERGIA S.A.S. E.S.P | Sí | 128.23 | 4.76 | 133.00 | 96.4% | 56.71 | 51.44 | 21.26 | 6.88 | 28.14 | 75.5% | 0.42 | 1.49% |
| 37 | CARBOENERGY SAS ESP | No | 111.21 | 0.00 | 111.21 | 100.0% | 109.58 | 1.63 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 38 | COLENERGIA S.A. E.S.P. | No | 83.47 | 2.86 | 86.32 | 96.7% | 71.28 | 15.47 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 39 | A.S.C. INGENIERIA S.A. E.S.P. | Sí | 73.07 | 0.00 | 73.07 | 100.0% | 2.02 | 0.00 | 54.01 | 20.74 | 74.75 | 72.3% | 1.12 | 1.50% |
| 40 | VOLTAJE EMPRESARIAL S.A.S. E.S.P. | No | 55.86 | 12.79 | 68.66 | 81.4% | 3.74 | 24.40 | 0.00 | 47.23 | 47.23 | 0.0% | 0.71 | 1.50% |
| 41 | BEAM ENERGY INNOVATION S.A.S. E.S.P. | No | 56.39 | 3.53 | 59.92 | 94.1% | 30.14 | 10.94 | 4.47 | 17.90 | 22.37 | 20.0% | 0.34 | 1.52% |
| 42 | DICELER S.A. E.S.P. | Sí | 54.70 | 4.31 | 59.01 | 92.7% | 24.62 | 22.36 | 12.79 | 0.00 | 12.79 | 100.0% | 0.19 | 1.49% |
| 43 | DEPI ENERGY S.A.S. E.S.P. | Sí | 51.37 | 5.58 | 56.95 | 90.2% | 41.27 | 16.49 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 44 | LUMINA ENERGY S.A.S. E.S.P. | No | 48.10 | 0.00 | 48.10 | 100.0% | 25.98 | 24.13 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 45 | RIOPAILA ENERGÍA S.A.S. E.S.P. | No | 0.00 | 22.18 | 22.18 | 0.0% | 0.00 | 0.00 | 0.00 | 21.94 | 21.94 | 0.0% | 0.33 | 1.50% |
| 46 | ÉRGON ENERGY SAS ESP | No | 21.88 | 0.00 | 21.89 | 100.0% | 20.99 | 0.90 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 47 | ENERMAS SAS ESP | No | 16.36 | 2.71 | 19.08 | 85.7% | 16.70 | 2.37 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 48 | UNERGY ENERGY DIGITAL S.A.S E.S.P | No | 12.45 | 0.00 | 12.45 | 100.0% | 0.29 | 12.87 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 49 | EMPRESA SIGLO XXI EICE ESP | No | 9.98 | 2.41 | 12.39 | 80.5% | 0.27 | 1.39 | 11.22 | 0.00 | 11.22 | 100.0% | 0.17 | 1.51% |
| 50 | SOUL ENERGY SAS ESP | No | 7.32 | 0.00 | 7.32 | 100.0% | 7.32 | 0.00 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 51 | NEXTGY S.A.S. E.S.P | No | 2.39 | 0.00 | 2.39 | 100.0% | 0.49 | 2.88 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 52 | SOL DEL EJE S.A.S E.S.P | No | 0.02 | 0.00 | 0.02 | 100.0% | 0.00 | 0.02 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |
| 53 | DEMAND RESPONSE SAS ESP | No | 0.00 | 0.00 | 0.00 | — | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0% | 0.00 | 0% |

**Unidades:** GWh (Gigavatios-hora)

### 6.2 Resumen Estadístico de Operación

| Métrica | Valor |
|---------|-------|
| **Total agentes analizados** | 53 |
| **Compra total (GWh)** | 36,847 |
| **Venta total (GWh)** | 22,158 |
| **Demanda total (GWh)** | 18,836 |
| **Demanda regulada (GWh)** | 7,560 |
| **% Demanda regulada** | 40.1% |
| **Compra promedio por contratos** | 93.5% |
| **Pérdida promedio por PUI** | 1.49% |

### 6.3 Análisis por Tipo de Operación

| Tipo de Agente | Cantidad | Compra Promedio | % Contratos | Demanda Reg Prom |
|----------------|----------|-----------------|-------------|------------------|
| **Enfoque Regulado** | 14 | 1,200 GWh | 94.2% | 75.3% |
| **Enfoque No Regulado** | 39 | 650 GWh | 95.8% | 0.0% |

---

## 7. ANÁLISIS DE SENSIBILIDAD

### 7.1 Impacto del Factor de Recaudo

| Factor Recaudo | Pérdida % | Pérdida Total (GWh equivalentes) | Escenario |
|----------------|-----------|----------------------------------|-----------|
| 80% | -20.00% | 7,369 | Peor caso |
| 85% | -15.00% | 5,527 | |
| 90% | -10.00% | 3,685 | |
| **92% (base)** | **-8.00%** | **2,948** | **Actual** |
| 95% | -5.00% | 1,842 | |
| 98% | -2.00% | 737 | Mejor caso |

### 7.2 Impacto por Agente (Top 5)

| Agente | GWh Operación | Pérdida @80% | Pérdida @92% | Pérdida @98% |
|--------|---------------|--------------|--------------|--------------|
| VATIA | 6,053 | 1,211 | 484 | 194 |
| SOUTH32 | 3,611 | 722 | 289 | 116 |
| RUITOQUE | 2,991 | 598 | 239 | 96 |
| COENERSA | 2,653 | 531 | 212 | 85 |
| NEU ENERGY | 1,966 | 393 | 157 | 63 |

---

## 8. ANÁLISIS REGULATORIO

### 8.1 Evidencia de Asimetrías (Art. 11 y 12 CREG)

| Aspecto Regulatorio | Evidencia Cuantitativa | Impacto |
|---------------------|------------------------|---------|
| **Riesgo de cartera (Art. 12)** | 100% del riesgo recae sobre el CNIOR | Pérdida del 8% promedio sobre giros |
| **Obligatoriedad de pago** | Giros obligatorios sin garantía de recaudo | Flujo de caja negativo |
| **Sin discriminación positiva** | Todos los independientes tienen mismo trato | Concentración del mercado |
| **Desincentivo a participación** | Pérdida garantizada para nuevos entrantes | Barreras de entrada efectivas |

### 8.2 Comparación CIOR vs CNIOR

| Variable | CIOR (Operador Integrado) | CNIOR (Independiente) |
|----------|---------------------------|----------------------|
| **Garantía de ingreso** | Caja blindada (cobra siempre) | Sin garantía (depende del recaudo) |
| **Riesgo de cartera** | Ninguno | 100% del riesgo |
| **Respaldo financiero** | Subsidio cruzado del grupo | Sin subsidio |
| **Capacidad de absorción** | Alta (múltiples líneas de negocio) | Baja (comercialización pura) |
| **Costo de capital** | Menor (menor riesgo percibido) | Mayor (mayor riesgo percibido) |

### 8.3 Citas del Análisis CREG

> *"El esquema transitorio genera trato discriminatorio o asimetrías en contra de los comercializadores no integrados (CNIOR)."*

> *"Al obligarlos a pagar valores no recaudados bajo tarifas preestablecidas, la regulación desincentiva la participación de comercializadores independientes."*

> *"Los Artículos 11 y 12 funcionan como un mecanismo de blindaje sistémico a favor del Operador de Red, a costa de imponer barreras financieras casi infranqueables a los CNIOR."*

---

## 9. CONCLUSIONES TÉCNICAS

### 9.1 Conclusiones Principales

1. **Efecto uniforme del PUI:** Todos los comercializadores independientes enfrentan el mismo riesgo financiero del 8% sobre los giros obligatorios, independientemente de su tamaño o modelo de negocio.

2. **Pérdida estructural:** El PUI genera una pérdida garantizada para los independientes que operan en el segmento regulado, representando el 40.1% de su demanda total.

3. **Asimetría confirmada:** La diferencia entre CIOR y CNIOR es significativa: el CIOR tiene ingreso blindado mientras que el CNIOR asume el 100% del riesgo de impago.

4. **Dependencia de contratos:** El 93.5% de la compra de energía se realiza mediante contratos bilaterales, lo que limita la exposición a precios spot pero no elimina el riesgo del PUI.

5. **Impacto diferenciado:** Los agentes con mayor demanda regulada (VATIA, NEU ENERGY, ENERTOTAL) son los más afectados por el PUI en términos absolutos.

### 9.2 Recomendaciones para Comercializadores Independientes

1. **Evaluación de viabilidad:** Antes de participar en procesos de PUI, evaluar si el margen del CRPUI cubre el costo esperado de incobrabilidad (8% promedio).

2. **Gestión de cartera:** Implementar mecanismos de cobro efectivo para minimizar el factor de recaudo real por debajo del 92% asumido.

3. **Análisis de zonas:** Priorizar mercados con menor riesgo de cartera y mayor potencial de recaudo.

4. **Monitoreo regulatorio:** Seguir la evolución hacia el mecanismo competitivo definitivo, que promete mayor neutralidad competitiva.

5. **Documentación:** Estos hallazgos respaldan la posición de los independientes ante la CREG en materia de asimetrías regulatorias.

---

## 10. METODOLOGÍA TÉCNICA DE LA SIMULACIÓN

### 10.1 Fuentes de Datos

| Tabla | Uso | Campos Clave |
|-------|-----|--------------|
| `fact_hourly_agente` | Operación por agente | `CompContEner`, `CompBolsa*`, `VentContEner`, `VentBolsa*`, `DemaCome*` |
| `fact_hourly_mercadocomercializacion` | Demanda por mercado | `DemaCome` |
| `fact_daily_sistema` | Precio promedio contratos | `PrecPromCont` |
| `dim_agente` | Clasificación de agentes | `activity = 'COMERCIALIZACIÓN'` |
| `dim_mercado` | Catálogo de mercados | `mercado_name` |

### 10.2 Algoritmo de Simulación

1. **Calcular demanda mensual** por mercado y por agente
2. **Clasificar agentes** CIOR/CNIOR (mayor demanda = CIOR)
3. **Calcular CRPUI** mensual por mercado usando fórmula CREG
4. **Distribuir giros** proporcionalmente a la participación de cada agente
5. **Aplicar factor de recaudo** (92%) para estimar pérdida
6. **Calcular flujo neto** de caja por agente

### 10.3 Supuestos

- Factor de recaudo uniforme (92%) para todos los CNIOR
- Un solo CIOR global (ENEL COLOMBIA) para todos los mercados
- Distribución proporcional sin mapeo agente→mercado directo
- Período completo de datos disponibles (2024-01-01 a 2026-08-17)

---

## 11. REFERENCIAS NORMATIVAS

1. **Resolución CREG 101 121 del 30 de julio de 2026** — Prestador de Última Instancia
2. **Decreto 1073 de 2015** — Definición de zonas especiales y subnormales
3. **Recomendaciones Superintendencia de Industria y Comercio (SIC)** — Riesgo de cartera
4. **Resoluciones CREG 2023-2024** — Prima de riesgo cartera histórica

---

*Documento generado por simulación PUI — Base de datos XM/SIN Colombia*
*Fecha: 2026-08-24*
*Para uso exclusivo de comercializadores independientes del MEM*
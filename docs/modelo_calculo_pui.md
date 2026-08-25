# Modelo Matemático y Tarifario: Prestador de Última Instancia (PUI)
**Enfoque: Agentes Comercializadores**

Este documento detalla el modelo de cálculo extraído de la regulación para la selección, operación y remuneración del Prestador de Última Instancia (PUI)[cite: 1]. El modelo busca asegurar la viabilidad económica del esquema y mitigar los riesgos financieros y de cartera asumidos por el comercializador[cite: 1].

## 1. Integración del Costo PUI en la Fórmula Tarifaria
La remuneración del comercializador se enmarca en la fórmula tarifaria general, donde el costo asociado al PUI impacta directamente el componente variable de comercialización[cite: 1].

**Fórmula del Componente Variable de Comercialización ($Cv_{m,i,j}$):**
$$ Cvm,i,j = C_{i,j,m}^* + \frac{CER_{i,m} + CCD_{i,m-1} + CG_{i,m-1}}{V_{i,m-1}} + \frac{(1-\beta) \times Cf_{m,j} \times UR_{i,j,m-2} + CGCU_{i,j,m-1} + PUI_{j,m}}{VR_{i,j,m-2} + cot_{n,j,m}} $$

*   **$PUI_{j,m}$**: Costo que remunera la actividad de Prestador de Última Instancia a usuarios regulados en el mercado de comercialización $j$, en el mes $m$[cite: 1].

---

## 2. Remuneración del PUI: Esquema Transitorio (Antes del mecanismo competitivo)
Antes de implementar el mecanismo competitivo, la remuneración del PUI se fundamenta en la causal de áreas especiales y corresponde al costo asociado al riesgo de cartera reconocido por la atención de dichos usuarios[cite: 1].

**Costo Total que Remunera la Actividad del PUI ($VTPUI$):**
$$ VTPUI = CRPUICIOR + CRPUICNIOR $$
*   **$CRPUICIOR$**: Costo de riesgo de cartera recaudado por el comercializador integrado con el operador de red (CIOR)[cite: 1].
*   **$CRPUICNIOR$**: Costo del riesgo de cartera recaudado por los comercializadores no integrados con el operador de red (CNIOR)[cite: 1].

**Cálculo del Costo por Riesgo de Cartera para CNIOR:**
$$ CRPUICNIOR = \sum_{i=1}^{I} CRPUI_{i,j,m} \times VRCNIOR_{j,m} $$

**Costo Unitario por Prestación del Servicio PUI en Áreas Especiales ($CRPUI_{i,j,m}$):**
$$ CRPUI_{i,j,m} = \frac{(RCPUI_{j,t} \times VPUI_{i,j,m-1})}{VR_{i,j,m-1} \times (G_{i,j,m-1} + T_{m-1} + D1_{j,m-1} + PR1_{j,m-1} + R_{i,m-1})} $$
*Esta fórmula indica qué fracción del costo unitario debe ser reconocida al PUI, ponderando la prima de riesgo de cartera del CIOR por la participación de usuarios en áreas especiales[cite: 1].*

**Traslado del Costo Transitorio a Usuarios Regulados:**
$$ PUI_{j,m} = CRPUI_{i,j,m} \times VR_{i,j,m-2} $$

---

## 3. Remuneración del PUI: Esquema Definitivo (Posterior al mecanismo competitivo)
Una vez implementado el mecanismo competitivo, la variable $PUI_{j,m}$ incorpora el resultado variabilizado del proceso, englobando todos los costos y riesgos operativos[cite: 1].

**Fórmula de Traslado Post-Competitivo:**
$$ PUI_{j,m} = CFPUI_{j,m} \times \sum_{i=1}^{I} VR_{i,j,m-2} $$
*   **$CFPUI_{j,m}$**: Costo variabilizado (en $/kWh) resultante del mecanismo competitivo para el mercado $j$ en el mes $m$[cite: 1].

*(Nota: La regulación también prevé una expresión metodológica que combina el costo competitivo con el riesgo de cartera: $PUI_{j,m} = (CRPUI_{i,j,m} + CFPUI_{j,m}) \times VR_{i,j,m-2}$[cite: 1])*

---

## 4. Estructura del Costo Variable de Comercialización y Riesgo de Cartera
El comercializador debe considerar los componentes que alimentan la variable $C_{i,j,m}^*$[cite: 1].

**Costo Variable de Comercialización Base ($C_{i,j,m}^*$):**
$$ C_{i,j,m}^* = (G_{i,j,m-1} + T_{m-1} + D1_{j,m-1} + PR1_{j,m-1} + R_{i,m-1}) \times (mo + RC_{i,j,m} + CFE_{i,j,m}) $$

**Cálculo del Riesgo de Cartera ($RC_{i,j,m}$):**
Reconoce los riesgos para usuarios tradicionales, áreas especiales, barrios subnormales y nuevos usuarios[cite: 1].
$$ RC_{i,j,m} = \frac{(RCT_j \times VUTr_{i,j,m-1}) + (RCAE_{j,t} \times VAE_{i,j,m-1}) + (RCSNE_{i,j,t} \times VSNE_{i,j,m-1}) + (RCNU \times VNU_{i,j,m-1})}{VRC_{i,j,m-1}} $$

**Prima Específica por Áreas Especiales:**
$$ Prima_{areas especiales} = \frac{(RCAE_{j,t} \times VAE_{i,j,m-1})}{VRC_{i,j,m-1} \times (G_{i,j,m-1} + T_{m-1} + D1_{j,m-1} + PR1_{j,m-1} + R_{i,m-1})} $$

---

## 5. Traslado de Compras Mediante Contratos Transitorios
Para las compras de energía destinadas al PUI mediante contratos transitorios (tipo pague lo contratado o PCDE), se aplica la siguiente regla para determinar el precio a trasladar[cite: 1].

**Energía Cubierta ($C$):**
$$ C = \sum_{s=1}^{n} qs $$
*   $qs$: Cantidades liquidadas en el mes $m$ con destino al mercado regulado[cite: 1].

**Precio Promedio Ponderado de Traslado ($p$):**
$$ p = \min \left( precio\_techo ; \frac{\sum_{s=1}^{n} ps \times qs}{C} \right) $$

---

## 6. Impacto en el Costo Unitario (Análisis de Sensibilidad)
Fórmula empleada para evaluar el impacto porcentual de la demanda atendida por el PUI sobre el Costo Unitario de Prestación del Servicio (CU) del mercado regulado[cite: 1].

$$ \Delta CU (\%) = \frac{V_{NR}}{V_R} \times \frac{PB - ((\alpha \times Mc) + ((1-\alpha) \times PB))}{CU} $$

### Glosario de Variables Adicionales:
*   **$V_{NR}$**: Energía del usuario no regulado atendido por PUI (kWh/mes)[cite: 1].
*   **$V_R$**: Ventas totales reguladas del mercado de comercialización (kWh/mes)[cite: 1].
*   **$PB$**: Precio de bolsa ponderado ($/kWh)[cite: 1].
*   **$Mc$**: Precio ponderado de los contratos ($/kWh)[cite: 1].
*   **$\alpha$**: Factor de cobertura contractual para el mercado regulado[cite: 1].
*   **$mo$**: Margen de rentabilidad al comercializador[cite: 1].
*   **$CFE$**: Costo del flujo de efectivo necesario para desarrollar la actividad[cite: 1].

***
*Documento enfocado en la modelación matemática estricta sin incluir lenguajes de programación en su estructura de análisis funcional, dirigido a agentes comercializadores del Sistema Interconectado Nacional.*
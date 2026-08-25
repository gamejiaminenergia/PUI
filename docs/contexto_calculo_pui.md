---
tipo_documento: Flujo de Cálculo / Operación Tarifaria
entidad: CREG
tema: Prestador de Última Instancia (PUI)
etiquetas: #RegulacionEnergia #MercadoElectrico #FlujoCalculo #Comercializacion
---

# Flujo de Cálculo y Operación: Esquema del Prestador de Última Instancia (PUI)

Este documento detalla el paso a paso del flujo de cálculo, facturación y giro de recursos definido en la regulación para la remuneración del Prestador de Última Instancia (PUI) en su fase transitoria (antes del mecanismo competitivo)[cite: 1]. 

El flujo está enfocado en la interacción entre el Comercializador Integrado con el Operador de Red (CIOR), los Comercializadores No Integrados (CNIOR) y los usuarios regulados.

## Diagrama de Flujo Lógico (Paso a Paso)

### PASO 1: Cálculo del Costo Unitario por el CIOR
El proceso inicia con el Comercializador Integrado con el Operador de Red (CIOR), quien asume inicialmente la responsabilidad y ejerce la función de PUI[cite: 1].
*   **Acción:** El CIOR calcula el costo por la prestación del servicio del PUI en áreas especiales ($CRPUI_{i,j,m}$)[cite: 1].
*   **Lógica Matemática:** Se pondera la prima de riesgo de cartera reconocida al CIOR por áreas especiales ($RCPUI_{j,t}$) según la participación que tienen los usuarios de estas áreas ($VPUI_{i,j,m-1}$) sobre las ventas totales ($VR_{i,j,m-1}$)[cite: 1]. Este factor se aplica sobre la suma de los componentes base del Costo Unitario de Prestación del Servicio ($G, T, D1, PR1, R$)[cite: 1].

### PASO 2: Publicación y Reporte Regulatorio
Una vez el costo unitario ha sido calculado:
*   **Acción:** El CIOR tiene el deber de publicar el valor de $CRPUI_{i,j,m}$ en su página web oficial[cite: 1].
*   **Plazo Máximo:** A más tardar el último día del mes respectivo[cite: 1].
*   **Obligación Adicional:** Este valor debe remitirse obligatoriamente a la Superintendencia de Servicios Públicos Domiciliarios (SSPD) para fines de inspección y control[cite: 1].

### PASO 3: Determinación del Costo Total a Trasladar ($PUI_{j,m}$)
Con el indicador publicado por el CIOR, cada comercializador en el mercado calcula la variable definitiva a integrar en su fórmula tarifaria.
*   **Acción:** Se halla el costo total que debe ser trasladado a los usuarios regulados en el mercado de comercialización ($PUI_{j,m}$)[cite: 1].
*   **Lógica Matemática:** Se multiplica el costo unitario calculado en el paso anterior ($CRPUI_{i,j,m}$) por el volumen de ventas totales a usuarios regulados del comercializador en el mes m-2 ($VR_{i,j,m-2}$)[cite: 1].

### PASO 4: Facturación al Usuario Regulado
El costo se transfiere directamente a la demanda que soporta el esquema.
*   **Acción:** El valor monetario de la variable $PUI_{j,m}$ es facturado por **todos** los comercializadores (tanto el CIOR como los CNIOR) a su demanda regulada en ese mercado[cite: 1].

### PASO 5: Giro de Recursos al PUI (Liquidación Financiera)
Es necesario que los dineros recaudados por comercializadores entrantes lleguen al comercializador integrado que está respaldando la operación.
*   **Acción:** Los Comercializadores No Integrados (CNIOR) deben girar financieramente el monto facturado ($PUI_{j,m}$) al CIOR (quien opera como PUI)[cite: 1].
*   **Condición Estricta de Riesgo:** El giro del dinero debe hacerse de manera obligatoria **independientemente de si el CNIOR logró recaudar efectivamente ese dinero** de sus usuarios[cite: 1].
*   **Plazo Máximo:** A más tardar el último día calendario del mes siguiente a la facturación[cite: 1].

### PASO 6: Consolidación de la Remuneración Total del PUI
El flujo culmina con el ingreso consolidado que garantiza la operatividad del prestador.
*   **Acción:** El CIOR consolida el Costo Total que remunera su actividad ($VTPUI$)[cite: 1].
*   **Lógica Matemática:** Corresponde a la sumatoria del costo de riesgo de cartera recaudado directamente por él mismo a sus usuarios ($CRPUICIOR$) más la suma de todos los giros recibidos por parte de los demás comercializadores ($CRPUICNIOR$)[cite: 1].

---
*Nota sobre la Fase Definitiva:* Una vez implementado el proceso de selección competitivo, este flujo operativo variará. El costo unitario dependerá exclusivamente del costo variabilizado resultante de la subasta ($CFPUI_{j,m}$) reemplazando el cálculo asociado a las áreas especiales, aplicándose directamente sobre las ventas a usuarios regulados ($VR_{i,j,m-2}$)[cite: 1].
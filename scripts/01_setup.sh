#!/usr/bin/env bash
# 01_setup.sh - Instala objetos SQL en la BD elecdb
# Uso: ./scripts/01_setup.sh

set -eo pipefail

DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$SCRIPT_DIR/../sql"

PSQL="psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1"

echo "=== Instalando objetos PUI ==="

echo "[1/6] Parámetros y estructura base..."
eval "$PSQL -f $SQL_DIR/01_params_pui.sql"

echo "[2/6] Cargando datos de independientes..."
eval "$PSQL -f $SCRIPT_DIR/cargar_independientes.sql"

echo "[3/6] Simulación core (vista v_simulacion_pui)..."
eval "$PSQL -f $SQL_DIR/02_simulacion_pui_core.sql"

echo "[4/6] Vistas analíticas..."
eval "$PSQL -f $SQL_DIR/03_vistas_analisis_pui.sql"

echo "[5/8] Función fn_simulacion_pui..."
eval "$PSQL -f $SQL_DIR/04_fn_simulacion_pui.sql"

echo "[6/8] Calibración parámetros..."
eval "$PSQL -f $SQL_DIR/05_calibracion_parametros.sql"

echo "[7/8] Vista operación integral..."
eval "$PSQL -f $SQL_DIR/06_vista_operacion_integral.sql"

echo "[8/8] Verificación final..."
eval "$PSQL -f $SQL_DIR/05_calibracion_parametros.sql"

echo "=== Verificación ==="
eval "$PSQL -c \"SELECT param_name, param_date, description FROM v_params_pui;\""
eval "$PSQL -c \"SELECT COUNT(*) as total_independientes FROM independientes_asociacion;\""
eval "$PSQL -c \"SELECT * FROM v_agentes_independientes LIMIT 5;\""
eval "$PSQL -c \"SELECT COUNT(*) as total_filas FROM v_simulacion_pui;\""
eval "$PSQL -c \"SELECT * FROM v_resumen_por_rol LIMIT 5;\""
eval "$PSQL -c \"SELECT * FROM v_top_cnior_afectados LIMIT 3;\""
eval "$PSQL -c \"SELECT COUNT(*) FROM v_apalancamiento_cior;\""
eval "$PSQL -c \"SELECT * FROM v_resumen_independientes LIMIT 5;\""
eval "$PSQL -c \"SELECT * FROM v_comparacion_grupos;\""

echo "✅ Setup completado exitosamente"
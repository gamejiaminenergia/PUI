#!/usr/bin/env bash
# 01_setup.sh - Instala objetos SQL en la BD elecdb
# Uso: ./scripts/01_setup.sh

set -eo pipefail

DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$SCRIPT_DIR/../sql"

PSQL="psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1"

echo "=== Instalando objetos PUI ==="

echo "[1/5] Parámetros..."
eval "$PSQL -f $SQL_DIR/01_params_pui.sql"

echo "[2/5] Simulación core (vista v_simulacion_pui)..."
eval "$PSQL -f $SQL_DIR/02_simulacion_pui_core.sql"

echo "[3/5] Vistas analíticas..."
eval "$PSQL -f $SQL_DIR/03_vistas_analisis_pui.sql"

echo "[4/5] Función fn_simulacion_pui..."
eval "$PSQL -f $SQL_DIR/04_fn_simulacion_pui.sql"

echo "[5/5] Calibración parámetros..."
eval "$PSQL -f $SQL_DIR/05_calibracion_parametros.sql"

echo "=== Verificación ==="
eval "$PSQL -c \"SELECT param_name, param_date, description FROM v_params_pui;\""
eval "$PSQL -c \"SELECT COUNT(*) as total_filas FROM v_simulacion_pui;\""
eval "$PSQL -c \"SELECT * FROM v_resumen_por_rol LIMIT 5;\""
eval "$PSQL -c \"SELECT * FROM v_top_cnior_afectados LIMIT 3;\""
eval "$PSQL -c \"SELECT COUNT(*) FROM v_apalancamiento_cior;\""

echo "✅ Setup completado exitosamente"
#!/usr/bin/env bash
# Regenera la tabla de operación del resumen ejecutivo desde la vista SQL.
# Uso: ./scripts/04_generate_summary.sh

set -euo pipefail

DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SUMMARY="$PROJECT_DIR/data/resumen_ejecutivo.md"

cd "$PROJECT_DIR"

python3 - "$DATABASE_URL" "$SUMMARY" <<'PY'
import csv
import re
import subprocess
import sys
from pathlib import Path

database_url, summary_path = sys.argv[1:]
query = """
SELECT agente_nombre, miembro_asociacion,
       compra_contratos_gwh, compra_bolsa_gwh, compra_total_gwh,
       pct_compra_contratos, pct_compra_bolsa,
       venta_contratos_gwh, venta_bolsa_gwh,
       demanda_regulada_gwh, demanda_no_regulada_gwh, demanda_total_gwh,
       pct_demanda_regulada
FROM v_operacion_integral_independientes
ORDER BY compra_total_gwh DESC, agente_nombre
"""

try:
    result = subprocess.run(
        ["psql", database_url, "-v", "ON_ERROR_STOP=1", "-A", "-F", "\t", "-P", "footer=off", "-c", query],
        check=True, capture_output=True, text=True,
    )
except FileNotFoundError:
    raise SystemExit("Error: psql no está instalado o no está disponible en PATH.")
except subprocess.CalledProcessError as error:
    detail = (error.stderr or error.stdout or "sin detalles").strip()
    raise SystemExit(
        "Error al consultar PostgreSQL. Verifique que la BD esté activa y que "
        "haya ejecutado ./scripts/01_setup.sh.\nDetalle: " + detail
    )
rows = list(csv.DictReader(result.stdout.splitlines(), delimiter="\t"))
if not rows:
    raise SystemExit("La vista no devolvió agentes; no se modificó el resumen.")

def number(value):
    return "0.00" if value in (None, "") else f"{float(value):,.2f}"

def percent(value):
    return "—" if value in (None, "") else f"{float(value):.1f}%"

path = Path(summary_path)
text = path.read_text(encoding="utf-8")
existing_pui = {}
for line in text.splitlines():
    if re.match(r"^\|\s*\d+\s*\|", line):
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) >= 16:
            existing_pui[cells[1]] = (cells[14], cells[15])

table = [
    "| # | Agente | Miembro | Compra Contratos | Compra Bolsa | Compra Total | % Contratos | % Bolsa | Venta Contratos | Venta Bolsa | Demanda Reg | Demanda No Reg | Demanda Total | % Dem Reg | Pérdida PUI | % Pérd PUI |",
    "|---|--------|---------|------------------|--------------|--------------|-------------|---------|-----------------|-------------|-------------|----------------|---------------|-----------|------------|------------|",
]
for index, row in enumerate(rows, 1):
    perdida_pui, pct_perdida_pui = existing_pui.get(row["agente_nombre"], ("0.00", "0%"))
    table.append(
        f"| {index} | {row['agente_nombre']} | {row['miembro_asociacion']} | "
        f"{number(row['compra_contratos_gwh'])} | {number(row['compra_bolsa_gwh'])} | "
        f"{number(row['compra_total_gwh'])} | {percent(row['pct_compra_contratos'])} | "
        f"{percent(row['pct_compra_bolsa'])} | {number(row['venta_contratos_gwh'])} | "
        f"{number(row['venta_bolsa_gwh'])} | {number(row['demanda_regulada_gwh'])} | "
        f"{number(row['demanda_no_regulada_gwh'])} | {number(row['demanda_total_gwh'])} | "
        f"{percent(row['pct_demanda_regulada'])} | {perdida_pui} | {pct_perdida_pui} |"
    )

pattern = r"(?ms)^\| # \| Agente \| Miembro.*?^\|---.*?\n(?=\n\*\*Fuente de datos:)"
replacement = "\n".join(table) + "\n"
updated, count = re.subn(pattern, replacement, text, count=1)
if count != 1:
    raise SystemExit("No se encontró la tabla 6.1 esperada; no se modificó el resumen.")
path.write_text(updated, encoding="utf-8")
print(f"Resumen generado: {len(rows)} agentes; columna % Bolsa incluida.")
PY
